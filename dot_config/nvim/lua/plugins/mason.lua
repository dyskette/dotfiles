-- Mason owns editor-only servers/adapters. Append its bin dir to PATH so binaries
-- pinned by a repo's mise.toml (e.g. ruff, golangci-lint) always win inside Neovim.
---@type LazySpec
return {
  "mason-org/mason.nvim",
  opts = { PATH = "append" },
}
