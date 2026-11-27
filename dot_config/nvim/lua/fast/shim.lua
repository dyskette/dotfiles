--- Resolve Windows `.cmd` shims (Mason's bin/, npm's .bin/) to what they would run.
---
--- Spawning a `.cmd` starts cmd.exe, which then starts the tool: an extra process and
--- 30-80 ms per LSP server, formatter or linter run. The known formats run one line:
---   mason: ... & "%dp0%\..\packages\gopls\gopls.exe" %*
---   npm:   ... & "%_prog%"  "%dp0%\..\@vtsls\language-server\bin\vtsls.js" %*
---   mise npm backend: node "%~dp0\..\.mise\<pkg>@<ver>\node_modules\<pkg>\x.js" %*
--- Unknown formats return nil and the caller keeps the shim.
local M = {}

---@type table<string, string[]|false>
local cache = {}

---@param path string
---@return string?
local function read(path)
  local f = io.open(path, "rb")
  if not f then
    return nil
  end
  local s = f:read("*a")
  f:close()
  return s
end

---@param path string absolute path of a .cmd file
---@param depth? integer
---@return string[]|false argv prefix, or false when the shim can't be resolved
local function resolve(path, depth)
  depth = depth or 0
  if depth > 3 then
    return false
  end
  local src = read(path)
  if not src then
    return false
  end
  local dir = path:match("^(.*)[/\\]")
  local last = src:match('[^\n]*%%dp0%%[^\n]*"%s+%%%*%s*$') or ""
  -- The mise form also sets NODE_PATH to its package store. Node only falls back to it for
  -- modules it can't find next to the script; basedpyright (bundled) never needs it.
  local npm_js = last:match('"%%_prog%%"%s+"%%dp0%%([^"]+%.[cm]?js)"')
    or src:match('\n%s*node%s+"%%~dp0([^"]+%.[cm]?js)"%s+%%%*')
  if npm_js then
    local node = vim.fn.exepath("node")
    local js = dir .. npm_js
    if node ~= "" and vim.uv.fs_stat(js) then
      return { node, js }
    end
    return false
  end
  local target = last:match('"%%dp0%%([^"]+)"%s+%%%*')
  if not target then
    return false
  end
  target = dir .. target
  local ext = target:sub(-4):lower()
  if ext == ".exe" and vim.uv.fs_stat(target) then
    return { target }
  elseif ext == ".cmd" then
    return resolve(target, depth + 1)
  end
  return false
end

--- argv prefix that replaces `cmd` (a name or a path), or nil to keep it.
---@param cmd string
---@return string[]?
function M.argv(cmd)
  local path = cmd
  if path:sub(-4):lower() ~= ".cmd" then
    -- exepath() is memoized and already unwraps .exe shims; only npm shims are left here.
    path = vim.fn.exepath(cmd)
    if path:sub(-4):lower() ~= ".cmd" then
      return nil
    end
  end
  local hit = cache[path]
  if hit == nil then
    hit = resolve(path)
    cache[path] = hit
  end
  return hit or nil
end

--- The `.exe` a shim runs, when it runs one directly (not a node script).
---@param path string absolute .cmd path
---@return string?
function M.exe(path)
  local hit = cache[path]
  if hit == nil then
    hit = resolve(path)
    cache[path] = hit
  end
  return hit and #hit == 1 and hit[1] or nil
end

return M
