--- Windows process-level speedups, loaded from init.lua before lazy.nvim (ADR 0008).
---
--- On Windows every `executable()`/`exepath()` walks each PATH dir times each PATHEXT entry
--- (11-35 ms per call with a 100-entry PATH), and plugins call these on every format, lint and
--- LSP start; Mason's `.cmd` shims add a cmd.exe per spawn. This module shrinks the search
--- space, answers lookups from an index and starts Mason tools without cmd.exe.
local M = {}

--- Start building the lookup index in the background (Windows only).
M.prebuild = function() end

local is_win = jit.os == "Windows"
local uv = vim.uv

--- Cleared when the lookup index exists; a no-op elsewhere.
M.clear = function() end

--- Remove duplicate and missing PATH dirs, so each lookup stats fewer places.
--- Child processes inherit the shorter PATH; nothing that resolved before stops resolving.
local function dedupe_path()
  local sep = is_win and ";" or ":"
  local seen, keep = {}, {}
  for dir in vim.gsplit(vim.env.PATH or "", sep, { plain = true }) do
    local key = dir:gsub("[/\\]+$", "")
    key = is_win and key:lower() or key
    if dir ~= "" and not seen[key] then
      seen[key] = true
      if uv.fs_stat(dir) then
        keep[#keep + 1] = dir
      end
    end
  end
  vim.env.PATH = table.concat(keep, sep)
end

--- Windows: answer executable()/exepath() from an index of every PATH dir (built once, ~10 ms),
--- instead of stat-ing dirs x PATHEXT per call (11-35 ms per miss with a long PATH).
--- Lua callers only (conform, nvim-lint, vim.lsp, snacks...); Vimscript still uses the builtin.
--- Rebuilt when PATH changes, and on a miss once the index is older than `ttl` ms, so tools
--- installed mid-session (Mason) are found.
local function index_lookups()
  local ttl = 10e3
  local raw_executable, raw_exepath = vim.fn.executable, vim.fn.exepath
  --- "\n<name>\t<dir>" per file, lowercase, PATH order: a plain find() returns the first dir
  --- that has it. Kept as one string, so building it needs no parsing on the main thread.
  local index ---@type string?
  local built_path, built_at = nil, 0
  local exts = {}

  ---@param path string
  ---@return string
  local function scan(path)
    local u = vim.uv
    local out = { "" }
    for dir in path:gmatch("[^;]+") do
      local fs = u.fs_scandir(dir)
      if fs then
        local d = dir:gsub("[/\\]+$", ""):lower()
        while true do
          local name, kind = u.fs_scandir_next(fs)
          if not name then
            break
          end
          if kind ~= "directory" then
            out[#out + 1] = name:lower() .. "\t" .. d
          end
        end
      end
    end
    out[#out + 1] = ""
    return table.concat(out, "\n")
  end

  local results = {} ---@type table<string, string|false> per-name answers for this index

  local function set(str, path)
    index, built_path, built_at, results = str, path, uv.now(), {}
    exts = {}
    for ext in ((uv.os_getenv("PATHEXT") or ".EXE"):lower()):gmatch("[^;]+") do
      exts[#exts + 1] = ext
    end
  end

  local function build()
    local path = uv.os_getenv("PATH") or ""
    set(scan(path), path)
  end

  --- Build in a worker thread (called at the end of startup, after every PATH change made by
  --- the config): ready before the first LSP/formatter lookup, no main-thread cost.
  M.prebuild = function()
    local path = uv.os_getenv("PATH") or ""
    local work = uv.new_work(scan, function(str)
      if not index and uv.os_getenv("PATH") == path then
        set(str, path)
      end
    end)
    work:queue(path)
  end

  ---@return string? full path
  local function lookup(key)
    local s = index:find("\n" .. key .. "\t", 1, true)
    if s then
      local e = index:find("\n", s + 1, true)
      local dir = index:sub(s + #key + 2, e - 1)
      return dir .. "\\" .. key
    end
  end

  ---@return string? full path
  ---@return boolean? use_raw
  local function find(name, retry)
    if name:find("[/\\]") then
      return nil, true -- a path: let the builtin handle it
    end
    if not index or uv.os_getenv("PATH") ~= built_path then
      build()
    end
    local key = name:lower()
    local cached = results[key]
    if cached or (cached == false and (retry or uv.now() - built_at <= ttl)) then
      return cached or nil
    end
    local hit
    local ext = key:match("%.[^.]+$")
    if ext and vim.tbl_contains(exts, ext) then
      hit = lookup(key)
    end
    if not hit then
      for _, e in ipairs(exts) do
        hit = lookup(key .. e)
        if hit then
          break
        end
      end
    end
    if not hit and not retry and uv.now() - built_at > ttl then
      build()
      return find(name, true)
    end
    results[key] = hit or false
    return hit
  end

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.fn.executable = function(name)
    local hit, use_raw = find(name)
    if use_raw then
      return raw_executable(name)
    end
    return hit and 1 or 0
  end

  local resolve = nil ---@type fun(path: string): string?
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.fn.exepath = function(name)
    local hit, use_raw = find(name)
    local p = use_raw and raw_exepath(name) or hit or ""
    -- Mason's `.cmd` shims cost a cmd.exe per spawn; hand back the real binary when there is one.
    if p ~= "" and p:sub(-4):lower() == ".cmd" then
      resolve = resolve or require("fast.shim").exe
      return resolve(p) or p
    end
    return p
  end

  M.clear = function()
    index = nil
  end
end

--- Rewrite `{ "tool.cmd", ... }` to the binary (or `node script.js`) the shim would run.
--- vim.system backs vim.lsp, conform and most plugin spawns.
local function unshim_system()
  local system = vim.system
  local shim = require("fast.shim")
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.system = function(cmd, opts, on_exit)
    if type(cmd) == "table" and cmd[1] then
      local argv = shim.argv(cmd[1])
      if argv then
        cmd = vim.list_extend(vim.list_slice(argv), cmd, 2)
      end
    end
    return system(cmd, opts, on_exit)
  end
end

--- Windows only: Linux and macOS lookups are cheap. Runs before lazy.nvim (init.lua).
function M.setup()
  if not is_win then
    return
  end
  if vim.g.fast_path_tweaks ~= false then
    dedupe_path()
    -- .VBS/.JS/.WSF/.MSC/... are never CLI tools; 4 extensions instead of 12 triples lookup speed.
    vim.env.PATHEXT = vim.g.fast_pathext or ".COM;.EXE;.BAT;.CMD"
  end
  index_lookups()
  unshim_system()
end

return M
