# Load ~/.config/powershell/profile.ps1 from $PROFILE, wherever Documents is (OneDrive too).
$p = $PROFILE.CurrentUserAllHosts
$line = '. "$HOME\.config\powershell\profile.ps1"'
New-Item -ItemType Directory -Force (Split-Path $p) | Out-Null
# Select-String throws on a missing file even with -ErrorAction Ignore, so check for the file first.
if (-not ((Test-Path $p) -and (Select-String -Quiet -SimpleMatch $line $p))) { Add-Content $p $line }
