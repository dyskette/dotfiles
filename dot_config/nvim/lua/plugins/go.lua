-- golangci-lint comes from mise (dot_config/mise/config.toml), not Mason: one owner per binary
-- (ADR 0001). mise's shim comes first on PATH anyway, and without a global version it failed
-- outside repos that pin one ("No version is set for shim"), which nvim-lint reported as
-- "Linter command `cmd.exe` exited with code".
---@type LazySpec
return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      -- The go extra adds it to ensure_installed; this runs after the extras.
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return tool ~= "golangci-lint"
      end, opts.ensure_installed or {})
    end,
  },
}
