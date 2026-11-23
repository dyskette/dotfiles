vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_python_ruff = "ruff"

-- "vtsls" or "tsc" (TS 7 native server).
vim.g.lazyvim_ts_lsp = "vtsls"

vim.g.lazyvim_picker = "snacks"
vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }

-- Appended, so the activated shell PATH (per-project runtimes) wins.
vim.env.PATH = vim.env.PATH .. ":" .. vim.env.HOME .. "/.local/share/mise/shims"

vim.opt.clipboard = "unnamedplus"
if vim.env.SSH_TTY then
  vim.g.clipboard = "osc52"
end
