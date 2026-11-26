@echo off
setlocal
rem nv-edit FILE [LINE]: see nv-edit.ps1. The Neovim-terminal case (lazygit's `e` from <leader>gg) is
rem handled here, without PowerShell's ~350 ms start; VS Code and the psmux `nv` cases go to nv-edit.ps1.
if "%TERM_PROGRAM%"=="vscode" goto ps1
if not defined NVIM goto ps1
rem One --remote-send closes the lazygit float and edits FILE, so it all happens even if closing the float
rem ends lazygit (and us). --headless: a client with a UI takes ~1.1 s to start; headless, ~60 ms.
rem Windows file names can't hold < > " |; a ' is doubled for the Vim string, fnameescape does the rest.
set "nv_file=%~f1"
set "nv_file=%nv_file:'=''%"
set "nv_line="
if not "%~2"=="" set "nv_line=+%~2 "
nvim --headless --server "%NVIM%" --remote-send "<C-\><C-n><cmd>close<bar>execute 'edit %nv_line%' .. fnameescape('%nv_file%')<cr>"
exit /b
:ps1
pwsh -NoProfile -File "%~dp0nv-edit.ps1" %*
