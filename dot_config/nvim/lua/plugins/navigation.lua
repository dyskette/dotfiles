-- Neovim splits and tmux panes as one layout (ADR 0004). Keep the keys in sync with tmux.conf.
-- Normal-mode Alt-j/k replace LazyVim's "move line" (still in insert and visual mode).

---@param fn string smart-splits function name
local function ss(fn)
  return function()
    require("smart-splits")[fn]()
  end
end

---@type LazySpec
return {
  "smart-splits-nvim/smart-splits.nvim",
  version = "^3.0.0",
  -- Never lazy: until the backend sets @pane-is-vim, tmux keeps Alt-h/j/k/l.
  lazy = false,
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
