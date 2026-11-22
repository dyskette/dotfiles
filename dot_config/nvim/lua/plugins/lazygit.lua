-- <leader>gg: open edited files in the current window instead of a new tab
-- (snacks' default "nvim-remote" preset uses --remote-tab).
---@type LazySpec
return {
  "folke/snacks.nvim",
  opts = {
    lazygit = {
      config = {
        os = {
          editPreset = "",
          edit = 'nvim --server "$NVIM" --remote-send "<C-\\><C-n><cmd>close<cr>" && nvim --server "$NVIM" --remote "{{filename}}"',
          editAtLine = 'nvim --server "$NVIM" --remote-send "<C-\\><C-n><cmd>close<cr>" && nvim --server "$NVIM" --remote "{{filename}}" && nvim --server "$NVIM" --remote-send ":{{line}}<CR>"',
        },
      },
    },
  },
}
