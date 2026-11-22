-- Options are automatically loaded before lazy.nvim startup
-- Default options: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Python: basedpyright + ruff (LazyVim's python extra defaults to pyright)
vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_python_ruff = "ruff"

-- TypeScript: "vtsls" (default, most code actions) or "tsc" (TS 7 native server, faster).
-- LazyVim 16.0.1 renamed "tsgo" -> "tsc".
vim.g.lazyvim_ts_lsp = "vtsls"

vim.g.lazyvim_picker = "snacks"
-- Root detection: LSP root first, then .git, then cwd (LazyVim default)
vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }

-- mise safety net: append shims so the activated shell PATH (per-project runtimes) wins.
vim.env.PATH = vim.env.PATH .. ":" .. vim.env.HOME .. "/.local/share/mise/shims"

-- OSC52 clipboard through tmux and SSH
vim.opt.clipboard = "unnamedplus"
if vim.env.SSH_TTY then
  vim.g.clipboard = "osc52"
end
