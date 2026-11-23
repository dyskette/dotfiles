# Load ~/.config/powershell/profile.ps1 from $PROFILE, wherever Documents is (OneDrive too).
$p = $PROFILE.CurrentUserAllHosts
$line = '. "$HOME\.config\powershell\profile.ps1"'
New-Item -ItemType Directory -Force (Split-Path $p) | Out-Null
if (-not (Select-String -Quiet -SimpleMatch $line $p -ErrorAction Ignore)) { Add-Content $p $line }
