# User variables for programs started outside PowerShell (the Start menu, VS Code's Neovim, IDEs).
# Runs on every apply: JAVA_HOME names an exact version, so `mise up` + `chezmoi apply` refreshes it.
# No DOTNET_ROOT: .NET is the machine-wide install in Program Files, where .NET looks by default.
$env:PATH = "$env:LOCALAPPDATA\mise\shims;$env:PATH"
$vars = @{
  JAVA_HOME       = (mise env --json | ConvertFrom-Json).JAVA_HOME
  # Neovim and the other XDG tools read ~/.config, as in the profile; without it, Neovim started from a
  # program that didn't come through PowerShell looks in %LOCALAPPDATA%\nvim and finds no config.
  XDG_CONFIG_HOME = "$HOME\.config"
}
foreach ($v in $vars.GetEnumerator()) {
  if ($v.Value -and [Environment]::GetEnvironmentVariable($v.Key, 'User') -ne $v.Value) {
    [Environment]::SetEnvironmentVariable($v.Key, $v.Value, 'User')
  }
}
# Earlier applies pointed DOTNET_ROOT at mise's .NET, which global tools would keep using.
if ([Environment]::GetEnvironmentVariable('DOTNET_ROOT', 'User') -like '*\mise\*') {
  [Environment]::SetEnvironmentVariable('DOTNET_ROOT', $null, 'User')
}
