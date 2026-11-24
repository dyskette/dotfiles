# sesh-dir [START]: pick a folder with lf (Enter, from ~/.config/lf/sesh-dir-pwsh) and open its sesh session.
# Windows counterpart of ./executable_sesh-dir.
param([string]$Start = $PWD.Path)
# TMUX in a psmux popup is missing or names another session's server; see ./tm.ps1.
$s = $env:PSMUX_TARGET_SESSION
if ($s -and $s -ne '__warm__' -and (Test-Path ($port = "$HOME\.psmux\$s.port"))) { $env:TMUX = "/tmp/psmux-0/default,$(Get-Content $port),0" }
$env:SESH_DIR_OUT = New-TemporaryFile
try {
  lf -command "source '$HOME/.config/lf/sesh-dir-pwsh'" $Start
  $dir = Get-Content $env:SESH_DIR_OUT -Raw
} finally { Remove-Item $env:SESH_DIR_OUT }
if ($dir) { sesh connect $dir }
