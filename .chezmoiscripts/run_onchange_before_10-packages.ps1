# winget packages mise can't provide.
# less: bat and delta page through it when run outside git (git brings its own, but only to its children).
$a = '--exact', '--silent', '--accept-package-agreements', '--accept-source-agreements'
foreach ($p in 'AmanThanvi.noctty', 'marlocarlo.psmux', 'jstarks.npiperelay', 'jftuga.less', 'Microsoft.VisualStudioCode') { winget install --id $p @a }
# MSVC: the linker rust needs and the C compiler tree-sitter builds parsers with.
winget install --id Microsoft.VisualStudio.BuildTools @a --override '--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended'
