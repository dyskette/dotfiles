vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_python_ruff = "ruff"

-- "vtsls" or "tsc" (TS 7 native server).
vim.g.lazyvim_ts_lsp = "vtsls"

vim.g.lazyvim_picker = "snacks"
vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }

local is_win = jit.os == "Windows"

-- Appended, so the activated shell PATH (per-project runtimes) wins. On Windows the shims are
-- already on the user PATH (a ":" there would corrupt PATH's last entry).
if not is_win then
  vim.env.PATH = vim.env.PATH .. ":" .. vim.env.HOME .. "/.local/share/mise/shims"
end

vim.opt.clipboard = "unnamedplus"
if vim.env.SSH_TTY then
  vim.g.clipboard = "osc52"
elseif is_win then
  -- Win32 clipboard API instead of a win32yank.exe process per yank/put (ADR 0008).
  require("fast.clipboard").setup()
end

-- Started from Git Bash, Neovim takes $SHELL (bash) but keeps cmd.exe's '/s /c' flags, which
-- breaks :! and system(). cmd.exe is also the fastest shell to start on Windows.
if is_win and vim.o.shellcmdflag == "/s /c" and not vim.o.shell:lower():find("cmd") then
  vim.o.shell = "cmd.exe"
end
