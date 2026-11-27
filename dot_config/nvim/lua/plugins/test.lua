-- neotest adapters the enabled LazyVim extras don't register.
---@type LazySpec
return {
  {
    "nvim-neotest/neotest",
    -- Windows: buffers opened as C:/x/test.py were "No tests found" (fast/neotest_paths.lua).
    init = jit.os == "Windows" and function()
      require("fast.neotest_paths").setup()
    end or nil,
    dependencies = { "marilari88/neotest-vitest", "nvim-neotest/neotest-jest", "AkisArou/neotest-nodejs" },
    opts = {
      adapters = {
        -- Node's built-in runner (`node --test`). Its own matcher claims any *.test/*.spec file that
        -- doesn't import vitest, which includes Jest's (they import nothing): also require node:test.
        ["neotest-nodejs"] = {
          isTestFile = function(file_path)
            if not require("neotest-nodejs.util").defaultTestFileMatcher(file_path) then
              return false
            end
            local ok, content = pcall(require("neotest.lib").files.read, file_path)
            return ok and content:find("node:test", 1, true) ~= nil
          end,
          -- Our reporter (reporters/neotest-nodejs.cjs keeps failure messages), as a file:// URL:
          -- on Windows node rejects C:/x/reporter.cjs (ERR_UNSUPPORTED_ESM_URL_SCHEME), ran
          -- nothing, and every test showed as failed.
          nodeArguments = function(args, context)
            local adapters = "--test-reporter=" .. context.reporterPath
            local ours = vim.fs.joinpath(vim.fn.stdpath("config"), "reporters", "neotest-nodejs.cjs")
            return vim.tbl_map(function(arg)
              return arg == adapters and "--test-reporter=" .. vim.uri_from_fname(ours) or arg
            end, args)
          end,
        },
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
