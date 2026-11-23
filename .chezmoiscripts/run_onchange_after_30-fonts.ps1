# JetBrainsMono Nerd Font for this user (no admin). Bump the version to update.
$v = 'v3.4.0'
$dir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
if ((Get-Content "$dir\JetBrainsMonoNerd.version" -ErrorAction Ignore) -eq $v) { exit }
$tmp = New-Item -ItemType Directory (Join-Path ([IO.Path]::GetTempPath()) (New-Guid))
Invoke-WebRequest "https://github.com/ryanoasis/nerd-fonts/releases/download/$v/JetBrainsMono.zip" -OutFile "$tmp\font.zip"
Expand-Archive "$tmp\font.zip" $tmp
New-Item -ItemType Directory -Force $dir | Out-Null
foreach ($f in Get-ChildItem $tmp -Filter *.ttf) {
  Copy-Item $f.FullName $dir -Force
  New-ItemProperty 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' "$($f.BaseName) (TrueType)" -Value "$dir\$($f.Name)" -Force | Out-Null
}
Set-Content "$dir\JetBrainsMonoNerd.version" $v
Remove-Item -Recurse $tmp
