-- <leader>gg: open edited files in the current window instead of a new tab
-- (snacks' default "nvim-remote" preset uses --remote-tab).
-- lazygit runs these through sh, or cmd on Windows, which expands %NVIM% rather than $NVIM.
local server = vim.fn.has("win32") == 1 and '"%NVIM%"' or '"$NVIM"'
local remote = "nvim --server " .. server

---@type LazySpec
return {
  "folke/snacks.nvim",
  opts = {
    lazygit = {
      config = {
        os = {
          editPreset = "",
          edit = remote .. ' --remote-send "<C-\\><C-n><cmd>close<cr>" && ' .. remote .. ' --remote "{{filename}}"',
          editAtLine = remote .. ' --remote-send "<C-\\><C-n><cmd>close<cr>" && ' .. remote .. ' --remote "{{filename}}" && '
            .. remote .. ' --remote-send ":{{line}}<CR>"',
        },
      },
    },
  },
}
