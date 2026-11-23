# winget packages mise can't provide.
$a = '--exact', '--silent', '--accept-package-agreements', '--accept-source-agreements'
foreach ($p in 'AmanThanvi.noctty', 'marlocarlo.psmux', 'jstarks.npiperelay') { winget install --id $p @a }
# MSVC: the linker rust needs and the C compiler tree-sitter builds parsers with.
winget install --id Microsoft.VisualStudio.BuildTools @a --override '--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended'
