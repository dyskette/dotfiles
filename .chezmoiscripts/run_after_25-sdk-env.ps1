# JAVA_HOME for programs that don't look in PATH (IDEs finding a JDK).
# Runs on every apply: the value names an exact version, so `mise up` + `chezmoi apply` refreshes it.
# No DOTNET_ROOT: .NET is the machine-wide install in Program Files, where .NET looks by default.
$env:PATH = "$env:LOCALAPPDATA\mise\shims;$env:PATH"
$java = (mise env --json | ConvertFrom-Json).JAVA_HOME
if ($java -and [Environment]::GetEnvironmentVariable('JAVA_HOME', 'User') -ne $java) {
  [Environment]::SetEnvironmentVariable('JAVA_HOME', $java, 'User')
}
# Earlier applies pointed DOTNET_ROOT at mise's .NET, which global tools would keep using.
if ([Environment]::GetEnvironmentVariable('DOTNET_ROOT', 'User') -like '*\mise\*') {
  [Environment]::SetEnvironmentVariable('DOTNET_ROOT', $null, 'User')
}
