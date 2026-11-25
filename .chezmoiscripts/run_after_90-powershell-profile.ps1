# Load ~/.config/powershell/profile.ps1 from $PROFILE, wherever Documents is (OneDrive too).
# Runs on every apply, so a $PROFILE another tool rewrote (or commented the line out of) is repaired.
$p = $PROFILE.CurrentUserAllHosts
$line = '. "$HOME\.config\powershell\profile.ps1"'
New-Item -ItemType Directory -Force (Split-Path $p) | Out-Null
# Only an active line counts: a commented-out copy doesn't load anything.
$active = [IO.File]::Exists($p) -and ([IO.File]::ReadAllLines($p) | Where-Object { $_.Trim() -eq $line })
if (-not $active) { Add-Content $p $line; Write-Host "Added the profile loader to $p" }
