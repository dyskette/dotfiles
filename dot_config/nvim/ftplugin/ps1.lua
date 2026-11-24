-- Replaces the runtime ftplugin/ps1.vim (sourced after this one, it stops at b:did_ftplugin).
-- That one calls Vimscript executable() up to 4 times per PowerShell buffer to find pwsh for
-- `K`: 20-80 ms on Windows. Same settings; the shell lookup happens when K is pressed.
if vim.b.did_ftplugin then
  return
end
vim.b.did_ftplugin = 1

vim.opt_local.textwidth = 0
vim.opt_local.commentstring = "# %s"
vim.opt_local.formatoptions = "tcqro"
vim.opt_local.iskeyword:append("-")

vim.api.nvim_buf_create_user_command(0, "GetHelp", function(ev)
  local pwsh = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell.exe"
  local cmd = pwsh .. ' -NoLogo -NoProfile -NonInteractive -Command Get-Help -Full "' .. ev.args .. '"'
  vim.cmd("silent hor term " .. cmd .. (vim.fn.executable("less") == 1 and " | less" or ""))
end, { nargs = 1 })
vim.opt_local.keywordprg = ":GetHelp"

vim.b.undo_ftplugin = "setlocal tw< cms< fo< iskeyword< kp< | sil! delc -buffer GetHelp"
