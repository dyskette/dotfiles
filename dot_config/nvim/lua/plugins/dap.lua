-- Debug adapters by real executable on Windows. nvim-dap starts adapters with uv.spawn, which only
-- finds .exe/.com, and the extras name them by bare name ("dlv", "js-debug-adapter"), for which
-- Mason has only .cmd launchers: the session fails with ENOENT. Calling the executables directly
-- also skips the cmd.exe each .cmd would start. Python's adapter is in plugins/python.lua.
if jit.os ~= "Windows" then
  return {}
end

local mason = (vim.env.MASON or vim.fn.stdpath("data") .. "/mason") .. "/packages"
--- A new table each time: neotest-golang writes `cwd` into the one it gets.
local function delve()
  return { path = mason .. "/delve/dlv.exe" }
end

---@type LazySpec
return {
  { "leoluz/nvim-dap-go", opts = { delve = delve() } },
  -- neotest-golang calls dap-go's setup() again with its own dap_go_opts before each debug run,
  -- which would reset the path to "dlv".
  {
    "nvim-neotest/neotest",
    optional = true,
    opts = { adapters = { ["neotest-golang"] = { dap_go_opts = { delve = delve() } } } },
  },

  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      -- The typescript extra (loaded before this file) registers the pwa-* adapters; point them at
      -- `node dapDebugServer.js`, which is all js-debug-adapter.cmd runs.
      local dap = require("dap")
      local server = mason .. "/js-debug-adapter/js-debug/src/dapDebugServer.js"
      for _, kind in ipairs({ "pwa-node", "pwa-chrome", "pwa-msedge" }) do
        local adapter = dap.adapters[kind]
        if type(adapter) == "table" and adapter.executable then
          adapter.executable.command = "node"
          adapter.executable.args = { server, "${port}" }
        end
      end
    end,
  },
}
