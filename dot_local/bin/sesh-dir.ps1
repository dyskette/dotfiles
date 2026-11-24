# sesh-dir [START]: pick a folder with lf (Enter, from ~/.config/lf/sesh-dir-pwsh) and open its sesh session.
# Windows counterpart of ./executable_sesh-dir.
param([string]$Start = $PWD.Path)
# psmux popups have no TMUX, so sesh would attach inside the popup; see ./tm.ps1.
$port = "$HOME\.psmux\$env:PSMUX_TARGET_SESSION.port"
if (-not $env:TMUX -and $env:PSMUX_TARGET_SESSION -and (Test-Path $port)) { $env:TMUX = "/tmp/psmux-0/default,$(Get-Content $port),0" }
$env:SESH_DIR_OUT = New-TemporaryFile
try {
  lf -command "source '$HOME/.config/lf/sesh-dir-pwsh'" $Start
  $dir = Get-Content $env:SESH_DIR_OUT -Raw
} finally { Remove-Item $env:SESH_DIR_OUT }
if ($dir) { sesh connect $dir }
