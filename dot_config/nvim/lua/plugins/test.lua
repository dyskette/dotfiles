-- neotest adapters not provided by the enabled LazyVim extras, plus Go tweaks.
-- python (neotest-python) and rust (rustaceanvim.neotest) are registered by their extras.
-- Set an adapter to `false` to drop one that an extra added.
---@type LazySpec
return {
  {
    "nvim-neotest/neotest",
    dependencies = { "marilari88/neotest-vitest", "nvim-neotest/neotest-jest" },
    opts = {
      adapters = {
        ["neotest-vitest"] = {},
        ["neotest-jest"] = {
          jestCommand = "pnpm jest",
          cwd = function()
            return vim.fn.getcwd()
          end,
        },
        -- gotestsum writes JSON to a file instead of stdout (more reliable output parsing).
        ["neotest-golang"] = { runner = "gotestsum", dap_go_enabled = true },
      },
    },
  },
}
