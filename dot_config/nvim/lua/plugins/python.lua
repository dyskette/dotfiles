-- Python editor tools without Mason's pip venvs (ADR 0011). Those venvs point at the absolute path
-- of the Python that was on PATH at install time, and stop starting (exit 103 on Windows) once that
-- version is upgraded or removed.
---@type LazySpec
return {
  -- basedpyright comes from npm through mise (dot_config/mise/config.toml) and runs on mise's node.
  { "neovim/nvim-lspconfig", opts = { servers = { basedpyright = { mason = false } } } },

  {
    "mfussenegger/nvim-dap-python",
    config = function()
      local dap_python = require("dap-python")
      -- setup() registers the configurations and the enrich_config that picks the debuggee's
      -- interpreter (the project's .venv); only the adapter command is replaced below.
      dap_python.setup("debugpy-adapter")
      local dap = require("dap")
      local adapter = dap.adapters.python
      ---@param cb fun(adapter: dap.Adapter)
      ---@param config dap.Configuration
      dap.adapters.python = function(cb, config)
        adapter(function(resolved)
          if resolved.type == "executable" then
            -- uv keeps debugpy in its cache on its own managed Python and rebuilds the environment
            -- if that interpreter changes, so nothing here points at a specific install.
            resolved.command = "uvx"
            resolved.args = { "--from", "debugpy", "debugpy-adapter" }
            resolved.options = vim.tbl_extend("force", resolved.options or {}, {
              -- ~1 s warm, but uvx, debugpy and python can be scanned cold by Defender on Windows:
              -- nvim-dap's 4 s default then warns "Debug adapter didn't respond".
              initialize_timeout_sec = 20,
              -- Windows: a detached process has no console, so the uv.exe that uvx starts got a
              -- new, visible one (a terminal tab titled uv.exe). Attached, nvim-dap's `hide` gives
              -- uvx a hidden console that uv and python share. nvim-dap-go does the same for delve.
              detached = jit.os ~= "Windows",
            })
          end
          cb(resolved)
        end, config)
      end
      dap.adapters.debugpy = dap.adapters.python
    end,
  },

  -- mason-nvim-dap would otherwise reinstall Mason's debugpy for the python adapter.
  { "jay-babu/mason-nvim-dap.nvim", optional = true, opts = { automatic_installation = { exclude = { "python" } } } },
}
