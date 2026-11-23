-- neotest adapters the enabled LazyVim extras don't register.
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
        ["neotest-golang"] = { runner = "gotestsum", dap_go_enabled = true },
      },
    },
  },
}
