# Bootstrap Windows with these dotfiles (counterpart of install.sh). Works in Windows PowerShell 5.1.
#   powershell -ExecutionPolicy Bypass -File install.ps1               (from a clone)
#   & ([scriptblock]::Create((irm <raw-url>/install.ps1))) <git-url>   (no clone yet)
param([string]$Repo)
$ErrorActionPreference = 'Stop'

foreach ($p in 'Git.Git', 'Microsoft.PowerShell', 'jdx.mise') {
  winget install --id $p --exact --silent --accept-package-agreements --accept-source-agreements
}
$env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH', 'User')
$env:XDG_CONFIG_HOME = "$HOME\.config"

# The Windows OpenSSH agent, which git and WSL use; needs admin once.
Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile', '-Command', 'Set-Service ssh-agent -StartupType Automatic; Start-Service ssh-agent'

if ($PSScriptRoot -and (Test-Path "$PSScriptRoot\.chezmoi.toml.tmpl")) { $src = '--source', $PSScriptRoot }
elseif ($Repo) { $src = $Repo }
else { throw 'Run from a clone of the repo, or pass the git URL.' }
mise exec chezmoi@latest -- chezmoi init --apply @src
Write-Host 'Done. Open Noctty and run psmux.'
