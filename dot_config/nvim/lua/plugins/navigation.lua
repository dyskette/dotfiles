-- Neovim splits and tmux panes as one layout (smart-splits.nvim + its tmux backend):
--   Alt-h/j/k/l        move: Neovim's windows first, then on into tmux's panes
--   Alt-Shift-H/J/K/L  resize: push the border in that direction, Neovim split or tmux pane
-- tmux side: the `@pane-is-vim` bindings in ~/.config/tmux/tmux.conf (keep the keys in sync).
-- Why smart-splits and not tmux.nvim/vim-tmux-navigator: docs/adr/0004-smart-splits-for-panes.md.
--
-- Normal-mode Alt-j/k replace LazyVim's "move line" there (it still works in insert and visual
-- mode). LazyVim's own Ctrl-h/j/k/l keep moving between Neovim splits only.

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
  -- Never lazy: the backend tells tmux this pane runs Neovim (`@pane-is-vim`) when it loads.
  -- Until then tmux keeps Alt-h/j/k/l for itself and Neovim never sees them.
  lazy = false,
  dependencies = {
    {
      "smart-splits-nvim/backend-tmux",
      main = "smart-splits-backend-tmux",
      -- No releases yet (first commit 2026-09-30); pinned until it tags one.
      commit = "9e9e6aa9b3eb7a8d3896a993611622ac97abff52",
    },
  },
  opts = {
    mux = { backend = "smart-splits-backend-tmux" },
    -- 'wrap' (default) matches tmux's own select-pane in tmux.conf.
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
