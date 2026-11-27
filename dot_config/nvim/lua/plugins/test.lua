-- neotest adapters the enabled LazyVim extras don't register.
---@type LazySpec
return {
  {
    "nvim-neotest/neotest",
    -- Windows: buffers opened as C:/x/test.py were "No tests found" (fast/neotest_paths.lua).
    init = jit.os == "Windows" and function()
      require("fast.neotest_paths").setup()
    end or nil,
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
