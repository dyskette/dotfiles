# winget packages mise can't provide.
# less: bat and delta page through it when run outside git (git brings its own, but only to its children).
$a = '--exact', '--silent', '--accept-package-agreements', '--accept-source-agreements'
foreach ($p in 'AmanThanvi.noctty', 'marlocarlo.psmux', 'jstarks.npiperelay', 'jftuga.less', 'Microsoft.VisualStudioCode') { winget install --id $p @a }
# .NET: Visual Studio installs SDKs machine-wide anyway, and that dotnet comes first on PATH outside mise's shells;
# winget's SDK 10 owns the CLI and the global tools before Visual Studio is installed (ADR 0001).
winget install --id Microsoft.DotNet.SDK.10 @a
# MSVC comes from Visual Studio (47-visualstudio, ADR 0009), not a separate Build Tools install.
