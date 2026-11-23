# sesh-dir [START]: pick a folder with lf (Enter, from ~/.config/lf/sesh-dir-pwsh) and open its sesh session.
# Windows counterpart of ./executable_sesh-dir.
param([string]$Start = $PWD.Path)
$env:SESH_DIR_OUT = New-TemporaryFile
try {
  lf -command "source '$HOME/.config/lf/sesh-dir-pwsh'" $Start
  $dir = Get-Content $env:SESH_DIR_OUT -Raw
} finally { Remove-Item $env:SESH_DIR_OUT }
if ($dir) { sesh connect $dir }
