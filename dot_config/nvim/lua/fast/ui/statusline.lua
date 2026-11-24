--- Global statusline with LazyVim's lualine layout, without lualine's per-redraw component work
--- (ADR 0008). Replaces lualine; set up from lua/config/options.lua.
---
--- 'statusline' is re-evaluated on every cursor move. Everything expensive (path, diagnostics,
--- git, icons) is cached per buffer and invalidated by the event that changes it; render()
--- only concatenates strings.
---   mode | branch | root  diagnostics  icon path     @q  dap  diff | 42% 10:4 | 14:05
local M = {}

local api = vim.api

local modes = {
  n = { "NORMAL", "Normal" },
  no = { "O-PENDING", "Normal" },
  nov = { "O-PENDING", "Normal" },
  noV = { "O-PENDING", "Normal" },
  ["no\22"] = { "O-PENDING", "Normal" },
  niI = { "NORMAL", "Normal" },
  niR = { "NORMAL", "Normal" },
  niV = { "NORMAL", "Normal" },
  nt = { "NORMAL", "Normal" },
  ntT = { "NORMAL", "Normal" },
  v = { "VISUAL", "Visual" },
  vs = { "VISUAL", "Visual" },
  V = { "V-LINE", "Visual" },
  Vs = { "V-LINE", "Visual" },
  ["\22"] = { "V-BLOCK", "Visual" },
  ["\22s"] = { "V-BLOCK", "Visual" },
  s = { "SELECT", "Visual" },
  S = { "S-LINE", "Visual" },
  ["\19"] = { "S-BLOCK", "Visual" },
  i = { "INSERT", "Insert" },
  ic = { "INSERT", "Insert" },
  ix = { "INSERT", "Insert" },
  R = { "REPLACE", "Replace" },
  Rc = { "REPLACE", "Replace" },
  Rx = { "REPLACE", "Replace" },
  Rv = { "V-REPLACE", "Replace" },
  Rvc = { "V-REPLACE", "Replace" },
  Rvx = { "V-REPLACE", "Replace" },
  c = { "COMMAND", "Command" },
  cv = { "EX", "Command" },
  ce = { "EX", "Command" },
  r = { "REPLACE", "Replace" },
  rm = { "MORE", "Command" },
  ["r?"] = { "CONFIRM", "Command" },
  ["!"] = { "SHELL", "Command" },
  t = { "TERMINAL", "Terminal" },
}

-- per-buffer caches
local path_cache = {} ---@type table<integer, string>
local diag_cache = {} ---@type table<integer, string>
local git_cache = {} ---@type table<integer, { head: string, diff: string }>
local icon_cache = {} ---@type table<string, string>
local root_cache = {} ---@type table<integer, string>

local function esc(s)
  return (s:gsub("%%", "%%%%"))
end

local function hl_get(name)
  return api.nvim_get_hl(0, { name = name, link = false })
end

--- Mode colors from the colorscheme, like lualine's "auto" theme.
function M.colors()
  local stl = hl_get("StatusLine")
  local normal = hl_get("Normal")
  local cursorline = hl_get("CursorLine")
  local bg_c = stl.bg or normal.bg
  local bg_b = cursorline.bg or bg_c
  local fg_on = normal.bg or 0
  local src = {
    Normal = { "Function", "Identifier" },
    Insert = { "String" },
    Visual = { "Statement", "Keyword" },
    Replace = { "Constant", "DiagnosticError" },
    Command = { "Type", "WarningMsg" },
    Terminal = { "String" },
  }
  for mode, groups in pairs(src) do
    local fg
    for _, g in ipairs(groups) do
      fg = fg or hl_get(g).fg
    end
    api.nvim_set_hl(0, "FastStl" .. mode .. "A", { fg = fg_on, bg = fg, bold = true })
    api.nvim_set_hl(0, "FastStl" .. mode .. "B", { fg = fg, bg = bg_b })
  end
  api.nvim_set_hl(0, "FastStlB", { fg = stl.fg or normal.fg, bg = bg_b })
  api.nvim_set_hl(0, "FastStlC", { fg = stl.fg or normal.fg, bg = bg_c })
  local function fg_on_c(name, from)
    api.nvim_set_hl(0, name, { fg = hl_get(from).fg, bg = bg_c })
  end
  fg_on_c("FastStlError", "DiagnosticError")
  fg_on_c("FastStlWarn", "DiagnosticWarn")
  fg_on_c("FastStlInfo", "DiagnosticInfo")
  fg_on_c("FastStlHint", "DiagnosticHint")
  fg_on_c("FastStlAdded", "Added")
  fg_on_c("FastStlChanged", "Changed")
  fg_on_c("FastStlRemoved", "Removed")
  fg_on_c("FastStlSpecial", "Special")
  fg_on_c("FastStlDebug", "Debug")
  fg_on_c("FastStlDir", "Directory")
  fg_on_c("FastStlComment", "Comment")
  api.nvim_set_hl(0, "FastStlFile", { fg = stl.fg or normal.fg, bg = bg_c, bold = true })
  icon_cache = {}
end

--- LazyVim's pretty_path: relative to root, middle dirs shortened, file name bold.
local function path(buf)
  local name = api.nvim_buf_get_name(buf)
  if name == "" then
    return ""
  end
  local root = LazyVim.root.get({ buf = buf, normalize = true })
  local cwd = LazyVim.root.cwd()
  local p = LazyVim.norm(name)
  local base = p:lower():find(cwd:lower(), 1, true) == 1 and cwd or root
  if p:lower():find(base:lower(), 1, true) == 1 and #p > #base then
    p = p:sub(#base + 2)
  end
  local parts = vim.split(p, "/", { plain = true })
  if #parts > 3 then
    parts = { parts[1], "…", parts[#parts - 1], parts[#parts] }
  end
  local file = table.remove(parts)
  local dir = #parts > 0
      and (table.concat(parts, LazyVim.is_win() and "\\" or "/") .. (LazyVim.is_win() and "\\" or "/"))
    or ""
  return "%#FastStlC#" .. esc(dir) .. "%#FastStlFile#" .. esc(file)
end

local function diagnostics(buf)
  local counts = vim.diagnostic.count(buf)
  local out = {}
  local sev = vim.diagnostic.severity
  for _, d in ipairs({ { sev.ERROR, "Error" }, { sev.WARN, "Warn" }, { sev.INFO, "Info" }, { sev.HINT, "Hint" } }) do
    local n = counts[d[1]]
    if n and n > 0 then
      out[#out + 1] = "%#FastStl" .. d[2] .. "#" .. LazyVim.config.icons.diagnostics[d[2]] .. n
    end
  end
  return #out > 0 and (table.concat(out, " ") .. " ") or ""
end

local function git(buf)
  local dict = vim.b[buf].gitsigns_status_dict
  if not dict then
    return { head = "", diff = "" }
  end
  local out = {}
  for _, d in ipairs({
    { "added", "Added", "added" },
    { "changed", "Changed", "modified" },
    { "removed", "Removed", "removed" },
  }) do
    local n = dict[d[1]]
    if n and n > 0 then
      out[#out + 1] = "%#FastStl" .. d[2] .. "#" .. LazyVim.config.icons.git[d[3]] .. n
    end
  end
  return { head = dict.head or "", diff = table.concat(out, " ") }
end

local function ft_icon(ft)
  if ft == "" then
    return ""
  end
  local hit = icon_cache[ft]
  if not hit then
    local ok, mi = pcall(require, "mini.icons")
    if ok then
      local icon, hl = mi.get("filetype", ft)
      local fg = hl_get(hl).fg
      local group = "FastStlIcon" .. hl
      api.nvim_set_hl(0, group, { fg = fg, bg = hl_get("FastStlC").bg })
      hit = "%#" .. group .. "#" .. icon .. " "
    else
      hit = ""
    end
    icon_cache[ft] = hit
  end
  return hit
end

--- LazyVim's root_dir component: shown when the root isn't the cwd.
local function root_dir(buf)
  local hit = root_cache[buf]
  if not hit then
    local root = LazyVim.root.get({ buf = buf, normalize = true })
    local cwd = LazyVim.root.cwd()
    hit = (root ~= cwd and api.nvim_buf_get_name(buf) ~= "")
        and ("%#FastStlDir#\u{f126d} " .. esc(vim.fs.basename(root)) .. " ")
      or ""
    root_cache[buf] = hit
  end
  return hit
end

local excluded = { snacks_dashboard = true, dashboard = true, alpha = true, ministarter = true }

function M.render()
  local buf = api.nvim_get_current_buf()
  if excluded[vim.bo[buf].filetype] then
    return "%#FastStlC#"
  end
  local m = modes[api.nvim_get_mode().mode] or { "NORMAL", "Normal" }
  local kind = m[2]

  local p = path_cache[buf]
  if not p then
    p = path(buf)
    path_cache[buf] = p
  end
  local d = diag_cache[buf]
  if not d then
    d = diagnostics(buf)
    diag_cache[buf] = d
  end
  local g = git_cache[buf]
  if not g then
    g = git(buf)
    git_cache[buf] = g
  end

  local flags = ""
  if vim.bo[buf].modified then
    flags = " %#FastStlSpecial#●"
  elseif vim.bo[buf].readonly or not vim.bo[buf].modifiable then
    flags = " %#FastStlComment#\u{f033e}"
  end

  local dap = ""
  if package.loaded.dap then
    local status = require("dap").status()
    if status ~= "" then
      dap = "%#FastStlDebug#\u{f46f}  " .. esc(status) .. " "
    end
  end

  -- macro recording (noice shows it through lualine in stock LazyVim)
  local reg = vim.fn.reg_recording()
  local recording = reg ~= "" and ("%#FastStlWarn#recording @" .. reg .. " ") or ""

  local hl_a, hl_b = "%#FastStl" .. kind .. "A#", "%#FastStl" .. kind .. "B#"
  return table.concat({
    hl_a,
    " ",
    m[1],
    " ",
    g.head ~= "" and (hl_b .. " \u{e0a0} " .. esc(g.head) .. " ") or "",
    "%#FastStlC# ",
    root_dir(buf),
    d,
    ft_icon(vim.bo[buf].filetype),
    p,
    flags,
    "%#FastStlC#%=",
    recording,
    dap,
    g.diff ~= "" and (g.diff .. " ") or "",
    hl_b,
    " %P %l:%c ",
    hl_a,
    " \u{f43a} ",
    os.date("%R"),
    " ",
  })
end

function M.setup()
  M.colors()
  _G.FastStatusline = M.render
  vim.o.statusline = "%!v:lua.FastStatusline()"

  local group = api.nvim_create_augroup("fast_statusline", { clear = true })
  api.nvim_create_autocmd("ColorScheme", { group = group, callback = M.colors })
  api.nvim_create_autocmd({ "BufFilePost", "BufEnter", "DirChanged", "LspAttach", "BufWritePost" }, {
    group = group,
    callback = function(ev)
      if ev.event == "DirChanged" then
        path_cache, root_cache = {}, {}
      else
        path_cache[ev.buf], root_cache[ev.buf] = nil, nil
      end
    end,
  })
  api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
    group = group,
    callback = function()
      -- reg_recording() is still set during RecordingLeave: redraw once it has cleared
      vim.schedule(function()
        vim.cmd.redrawstatus()
      end)
    end,
  })
  api.nvim_create_autocmd("DiagnosticChanged", {
    group = group,
    callback = function(ev)
      diag_cache[ev.buf] = nil
    end,
  })
  api.nvim_create_autocmd("User", {
    group = group,
    pattern = "GitSignsUpdate",
    callback = function(ev)
      local buf = ev.data and ev.data.buffer
      if buf then
        git_cache[buf] = nil
      else
        git_cache = {}
      end
      vim.cmd.redrawstatus()
    end,
  })
  api.nvim_create_autocmd({ "BufWipeout" }, {
    group = group,
    callback = function(ev)
      path_cache[ev.buf], diag_cache[ev.buf], git_cache[ev.buf], root_cache[ev.buf] = nil, nil, nil, nil
    end,
  })
  -- keep the clock current
  local timer = assert(vim.uv.new_timer())
  local now = os.date("*t")
  timer:start(
    (60 - now.sec) * 1000,
    60000,
    vim.schedule_wrap(function()
      vim.cmd.redrawstatus()
    end)
  )
end

return M
