-- Mason's bin dir goes last, so binaries a repo pins in mise.toml win.
---@type LazySpec
return {
  "mason-org/mason.nvim",
  opts = { PATH = "append" },
}
