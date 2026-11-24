--- Buffer tabline replacing bufferline (ADR 0008), with the bufferline behaviour LazyVim uses:
--- ordered buffers, pinning, move, close left/right, pick, diagnostics, explorer offset, hidden
--- with a single buffer.
---
--- The rendered string is cached and rebuilt only on events that change it, so redraws
--- (every keystroke) cost one string return.
local M = {}

local api = vim.api

M.order = {} ---@type integer[] listed buffers in display order
M.pinned = {} ---@type table<integer, boolean>
local cache ---@type string?
local picking ---@type table<integer, string>?
local hl_made = {} ---@type table<string, boolean>

local function listed(b)
  return api.nvim_buf_is_valid(b) and vim.bo[b].buflisted
end

--- Sync M.order with the listed buffers, keeping order and putting pinned ones first.
local function sync()
  local seen, order = {}, {}
  for _, b in ipairs(M.order) do
    if listed(b) and not seen[b] then
      seen[b] = true
      order[#order + 1] = b
    end
  end
  for _, b in ipairs(api.nvim_list_bufs()) do
    if listed(b) and not seen[b] then
      order[#order + 1] = b
    end
  end
  for b in pairs(M.pinned) do
    if not listed(b) then
      M.pinned[b] = nil
    end
  end
  local pos = {}
  for i, b in ipairs(order) do
    pos[b] = i
  end
  table.sort(order, function(a, b)
    local pa, pb = M.pinned[a] and 1 or 0, M.pinned[b] and 1 or 0
    if pa ~= pb then
      return pa > pb
    end
    return pos[a] < pos[b]
  end)
  M.order = order
end

local function invalidate()
  cache = nil
end

--- Highlight with the fg of `fg_group` on the bg of `bg_group`, created on demand.
local function mixed(fg_group, bg_group)
  local name = "FastTab" .. fg_group .. bg_group
  if not hl_made[name] then
    local fg = api.nvim_get_hl(0, { name = fg_group, link = false }).fg
    local bgh = api.nvim_get_hl(0, { name = bg_group, link = false })
    api.nvim_set_hl(0, name, { fg = fg, bg = bgh.bg, bold = bgh.bold })
    hl_made[name] = true
  end
  return "%#" .. name .. "#"
end

local function names()
  -- bufferline shows the file name, and the parent dir when two buffers share it
  local base, count = {}, {}
  for _, b in ipairs(M.order) do
    local name = api.nvim_buf_get_name(b)
    local tail = name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":t")
    base[b] = tail
    count[tail] = (count[tail] or 0) + 1
  end
  for _, b in ipairs(M.order) do
    if count[base[b]] > 1 then
      local parent = vim.fn.fnamemodify(api.nvim_buf_get_name(b), ":h:t")
      base[b] = parent .. "/" .. base[b]
    end
  end
  return base
end

--- Width of a snacks explorer / sidebar at the left edge, so buffers start after it.
local function offset()
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    local ft = vim.bo[api.nvim_win_get_buf(win)].filetype
    if (ft == "snacks_layout_box" or ft == "neo-tree") and api.nvim_win_get_position(win)[2] == 0 then
      local cfg = api.nvim_win_get_config(win)
      if cfg.relative == "" then
        return api.nvim_win_get_width(win) + 1
      end
    end
  end
  return 0
end

local function item(b, label, current)
  local bg = current and "TabLineSel" or "TabLine"
  local parts = { "%", b, "@v:lua.FastTablineClick@", "%#" .. bg .. "# " }
  if picking then
    parts[#parts + 1] = mixed("DiagnosticError", bg) .. (picking[b] or " ") .. "%#" .. bg .. "# "
  end
  local ok, mi = pcall(require, "mini.icons")
  if ok then
    local name = api.nvim_buf_get_name(b)
    local icon, hl = mi.get("file", name ~= "" and name or "x.txt")
    parts[#parts + 1] = mixed(hl, bg) .. icon .. " %#" .. bg .. "#"
  end
  parts[#parts + 1] = label:gsub("%%", "%%%%")
  local counts = vim.diagnostic.count(b)
  local e, w = counts[vim.diagnostic.severity.ERROR], counts[vim.diagnostic.severity.WARN]
  if e or w then
    parts[#parts + 1] = " "
    if e then
      parts[#parts + 1] = mixed("DiagnosticError", bg) .. vim.trim(LazyVim.config.icons.diagnostics.Error) .. e
    end
    if w then
      parts[#parts + 1] = mixed("DiagnosticWarn", bg) .. vim.trim(LazyVim.config.icons.diagnostics.Warn) .. w
    end
    parts[#parts + 1] = "%#" .. bg .. "#"
  end
  if M.pinned[b] then
    parts[#parts + 1] = " \u{f0403}"
  end
  parts[#parts + 1] = vim.bo[b].modified and " ● " or "   "
  local text = table.concat(parts) .. "%T"
  -- display width: strip highlight/click groups
  local plain = text:gsub("%%#[^#]*#", ""):gsub("%%%d*@[^@]*@", ""):gsub("%%T", ""):gsub("%%%%", "%%")
  return text, api.nvim_strwidth(plain)
end

function M.render()
  if cache then
    return cache
  end
  sync()
  local cur = api.nvim_get_current_buf()
  local labels = names()
  local items, widths, cur_idx = {}, {}, nil
  for i, b in ipairs(M.order) do
    items[i], widths[i] = item(b, labels[b], b == cur)
    if b == cur then
      cur_idx = i
    end
  end
  local off = offset()
  local tabs = ""
  local ntabs = #api.nvim_list_tabpages()
  if ntabs > 1 then
    local cur_tab = api.nvim_tabpage_get_number(0)
    local t = {}
    for i = 1, ntabs do
      t[#t + 1] = (i == cur_tab and "%#TabLineSel#" or "%#TabLine#") .. "%" .. i .. "T " .. i .. " %T"
    end
    tabs = table.concat(t)
  end
  -- keep the current buffer visible when they don't all fit
  local avail = vim.o.columns - off - ntabs * 3 - 2
  local first, last = 1, #items
  local total = 0
  for i = first, last do
    total = total + widths[i]
  end
  cur_idx = cur_idx or 1
  while total > avail and first < last do
    if cur_idx - first > last - cur_idx then
      total, first = total - widths[first], first + 1
    else
      total, last = total - widths[last], last - 1
    end
  end
  local out = { string.rep(" ", off) }
  if first > 1 then
    out[#out + 1] = "%#TabLineFill#<"
  end
  for i = first, last do
    out[#out + 1] = items[i]
  end
  if last < #items then
    out[#out + 1] = "%#TabLineFill#>"
  end
  out[#out + 1] = "%#TabLineFill#%=" .. tabs
  cache = table.concat(out)
  return cache
end

--- Show the tabline only with 2+ buffers or tabs (bufferline's always_show_bufferline = false).
local function update_visibility()
  sync()
  local want = (#M.order > 1 or #api.nvim_list_tabpages() > 1) and 2 or 0
  if vim.o.showtabline ~= want and vim.g.fast_tabline_auto ~= false then
    vim.o.showtabline = want
  end
end

---@param delta integer
function M.cycle(delta)
  sync()
  local n = #M.order
  if n == 0 then
    return
  end
  local idx = vim.fn.index(M.order, api.nvim_get_current_buf()) + 1
  idx = idx == 0 and 1 or ((idx - 1 + delta) % n) + 1
  api.nvim_set_current_buf(M.order[idx])
end

---@param delta integer
function M.move(delta)
  sync()
  local cur = api.nvim_get_current_buf()
  local idx = vim.fn.index(M.order, cur) + 1
  local to = idx + delta
  if idx == 0 or to < 1 or to > #M.order then
    return
  end
  M.order[idx], M.order[to] = M.order[to], M.order[idx]
  invalidate()
  vim.cmd.redrawtabline()
end

function M.toggle_pin()
  local b = api.nvim_get_current_buf()
  M.pinned[b] = not M.pinned[b] or nil
  invalidate()
  vim.cmd.redrawtabline()
end

function M.close_unpinned()
  sync()
  for _, b in ipairs(vim.list_slice(M.order)) do
    if not M.pinned[b] then
      Snacks.bufdelete(b)
    end
  end
end

---@param side -1|1 left or right of the current buffer
function M.close_side(side)
  sync()
  local idx = vim.fn.index(M.order, api.nvim_get_current_buf()) + 1
  for i, b in ipairs(vim.list_slice(M.order)) do
    if (side > 0 and i > idx) or (side < 0 and i < idx) then
      Snacks.bufdelete(b)
    end
  end
end

function M.pick()
  sync()
  local letters = "asdfjkletgwiorumcvxzbnhypq"
  picking = {}
  local by_letter = {}
  for i, b in ipairs(M.order) do
    local l = letters:sub(i, i)
    if l == "" then
      break
    end
    picking[b], by_letter[l] = l, b
  end
  invalidate()
  vim.cmd.redrawtabline()
  local ok, ch = pcall(vim.fn.getcharstr)
  picking = nil
  invalidate()
  vim.cmd.redrawtabline()
  if ok and by_letter[ch] then
    api.nvim_set_current_buf(by_letter[ch])
  end
end

function M.setup()
  _G.FastTabline = M.render
  _G.FastTablineClick = function(minwid, _, button)
    if button == "m" then
      Snacks.bufdelete(minwid)
    elseif api.nvim_buf_is_valid(minwid) then
      api.nvim_set_current_buf(minwid)
    end
  end
  vim.o.tabline = "%!v:lua.FastTabline()"
  local group = api.nvim_create_augroup("fast_tabline", { clear = true })
  api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufWipeout", "TabNew", "TabClosed" }, {
    group = group,
    callback = function()
      invalidate()
      vim.schedule(update_visibility)
    end,
  })
  api.nvim_create_autocmd({
    "BufEnter",
    "BufModifiedSet",
    "BufFilePost",
    "DiagnosticChanged",
    "VimResized",
    "WinResized",
    "TabEnter",
    "WinEnter",
  }, { group = group, callback = invalidate })
  api.nvim_create_autocmd("OptionSet", {
    group = group,
    pattern = "buflisted",
    callback = function()
      invalidate()
      vim.schedule(update_visibility)
    end,
  })
  api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      hl_made = {}
      invalidate()
    end,
  })
  update_visibility()
end

return M
