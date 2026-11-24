-- Neovim splits and tmux panes as one layout (ADR 0004). Keep the keys in sync with tmux.conf.
-- Normal-mode Alt-j/k replace LazyVim's "move line" (still in insert and visual mode).
--
-- tmux sends Alt-h/j/k/l to Neovim only while the pane has @pane-is-vim. smart-splits sets it
-- when it activates, with two blocking tmux calls (~100 ms under psmux on Windows). Here a
-- non-blocking spawn sets it right after startup and smart-splits loads on the first key
-- (ADR 0008).

---@param fn string smart-splits function name
local function ss(fn)
  return function()
    require("smart-splits")[fn]()
  end
end

--- `tmux -S <socket> set-option -p -t <pane> @pane-is-vim <value>`, without waiting.
---@param value 0|1
local function set_pane_is_vim(value)
  local socket = (vim.env.TMUX or ""):match("^([^,]+)")
  local pane = vim.env.TMUX_PANE
  if socket and pane then
    local cmd = { "tmux", "-S", socket, "set-option", "-p", "-t", pane, "@pane-is-vim", tostring(value) }
    pcall(vim.fn.jobstart, cmd, { detach = value == 0 })
  end
end

---@type LazySpec
return {
  "smart-splits-nvim/smart-splits.nvim",
  version = "^3.0.0",
  init = function()
    if not vim.env.TMUX then
      return
    end
    local group = vim.api.nvim_create_augroup("pane_is_vim", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = "VeryLazy",
      once = true,
      callback = function()
        set_pane_is_vim(1)
      end,
    })
    vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, {
      group = group,
      callback = function()
        set_pane_is_vim(0)
      end,
    })
    vim.api.nvim_create_autocmd("VimResume", {
      group = group,
      callback = function()
        set_pane_is_vim(1)
      end,
    })
  end,
  dependencies = {
    {
      "smart-splits-nvim/backend-tmux",
      main = "smart-splits-backend-tmux",
      -- No releases yet.
      commit = "9e9e6aa9b3eb7a8d3896a993611622ac97abff52",
    },
  },
  opts = {
    mux = { backend = "smart-splits-backend-tmux" },
    move = { at_edge = "wrap" },
  },
  keys = {
    { "<M-h>", ss("move_cursor_left"), desc = "Go to Left Window or Pane" },
    { "<M-j>", ss("move_cursor_down"), desc = "Go to Lower Window or Pane" },
    { "<M-k>", ss("move_cursor_up"), desc = "Go to Upper Window or Pane" },
    { "<M-l>", ss("move_cursor_right"), desc = "Go to Right Window or Pane" },
    { "<M-H>", ss("resize_left"), desc = "Resize Window or Pane Left" },
    { "<M-J>", ss("resize_down"), desc = "Resize Window or Pane Down" },
    { "<M-K>", ss("resize_up"), desc = "Resize Window or Pane Up" },
    { "<M-L>", ss("resize_right"), desc = "Resize Window or Pane Right" },
  },
}
