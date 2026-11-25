-- <leader>gg: open edited files in the current window instead of a new tab
-- (snacks' default "nvim-remote" preset uses --remote-tab).
-- On Windows lazygit escapes % & < > with ^ before handing the command to cmd, so neither %NVIM%
-- nor && work there: nv-edit.ps1 does the same through $env:NVIM instead.
local os_config = vim.fn.has("win32") == 1
    and { edit = "nv-edit {{filename}}", editAtLine = "nv-edit {{filename}} {{line}}" }
  or {
    edit = 'nvim --server "$NVIM" --remote-send "<C-\\><C-n><cmd>close<cr>" && nvim --server "$NVIM" --remote "{{filename}}"',
    editAtLine = 'nvim --server "$NVIM" --remote-send "<C-\\><C-n><cmd>close<cr>" && nvim --server "$NVIM" --remote "{{filename}}"'
      .. ' && nvim --server "$NVIM" --remote-send ":{{line}}<CR>"',
  }
os_config.editPreset = ""

---@type LazySpec
return {
  "folke/snacks.nvim",
  opts = {
    lazygit = {
      config = { os = os_config },
    },
  },
}
