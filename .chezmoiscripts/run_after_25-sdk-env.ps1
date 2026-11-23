# SDK roots for programs that don't look in PATH (.NET global tools, IDEs finding a JDK).
# Runs on every apply: the values name exact versions, so `mise up` + `chezmoi apply` refreshes them.
$env:PATH = "$env:LOCALAPPDATA\mise\shims;$env:PATH"
$sdk = mise env --json | ConvertFrom-Json
foreach ($name in 'DOTNET_ROOT', 'JAVA_HOME') {
  if ($sdk.$name -and [Environment]::GetEnvironmentVariable($name, 'User') -ne $sdk.$name) {
    [Environment]::SetEnvironmentVariable($name, $sdk.$name, 'User')
  }
}
