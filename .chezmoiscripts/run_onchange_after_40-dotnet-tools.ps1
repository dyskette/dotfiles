# .NET editor tools, as easy-dotnet.nvim expects them, on the machine-wide .NET (10-packages).
# Program Files\dotnet goes first: winget may have installed it earlier in this same apply.
$env:PATH = "$env:ProgramFiles\dotnet;$HOME\.dotnet\tools;$env:PATH"; $env:XDG_CONFIG_HOME = "$HOME\.config"
dotnet tool update -g EasyDotnet
dotnet tool update -g roslyn-language-server --prerelease
