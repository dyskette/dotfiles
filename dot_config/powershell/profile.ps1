# Windows counterpart of ~/.bash_profile + ~/.bashrc, loaded from $PROFILE.
# UTF-8 with native programs, before any of their output is captured below: the console
# defaults to the OEM code page, which garbles ñ and á in paths from fd, rg, tv or git.
[Console]::InputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$env:XDG_CONFIG_HOME = "$HOME\.config"
$env:LF_CONFIG_HOME = $env:XDG_CONFIG_HOME
$env:BAT_CONFIG_DIR = "$env:XDG_CONFIG_HOME\bat"
$env:RIPGREP_CONFIG_PATH = "$env:XDG_CONFIG_HOME\ripgrep\config"
$env:EDITOR = $env:VISUAL = 'nvim'
foreach ($d in "$HOME\.dotnet\tools", "$HOME\.local\bin") {
  if (($env:PATH -split ';') -notcontains $d) { $env:PATH = "$d;$env:PATH" }
}

if (Get-Command mise -ErrorAction Ignore) { mise activate pwsh | Out-String | Invoke-Expression }
$completions = "$env:LOCALAPPDATA\powershell-completions.ps1"
if (Test-Path $completions) { . $completions }
# tv before atuin, which takes Ctrl-R back from tv. tv names the shell power-shell.
foreach ($init in 'tv power-shell', 'zoxide powershell', 'atuin powershell', 'starship powershell') {
  $t, $shell = -split $init
  if (Get-Command $t -ErrorAction Ignore) { & $t init $shell | Out-String | Invoke-Expression }
}
# Emacs-style keys bash has too; none collide with tv's or atuin's (Ctrl+T, Ctrl+R, Up).
Set-PSReadLineKeyHandler -Key 'Ctrl+p' -Function HistorySearchBackward  # previous line starting with what's typed
Set-PSReadLineKeyHandler -Key 'Ctrl+n' -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key 'Ctrl+y' -Function AcceptSuggestion       # take the grey prediction
Set-PSReadLineKeyHandler -Key 'Ctrl+d' -Function DeleteCharOrExit

# Built-in aliases win over functions, so drop the ones replaced below.
'ls', 'cat', 'gl' | ForEach-Object { Remove-Item "Alias:$_" -Force -ErrorAction Ignore }
function ls { eza --group-directories-first --icons=auto --hyperlink=auto @args }
function ll { eza --long --all --git --header --time-style=relative --group-directories-first --icons=auto --hyperlink=auto @args }
function la { eza --all --group-directories-first --icons=auto --hyperlink=auto @args }
function lt {                                   # lt [level] [path...]
  $a = @($args); $level = 2
  if ($a[0] -match '^\d+$') { $level = $a[0]; $a = @($a | Select-Object -Skip 1) }
  eza --tree --level=$level --group-directories-first --icons=auto --git-ignore @a
}
function cat { bat --paging=never --style=plain @args }
Set-Alias e lf
Set-Alias gg lazygit
Set-Alias vim nvim
function ee($Path = '.') { explorer.exe $Path }

# --- Pickers, named after LazyVim's keys ---
function Get-TvRoot { $r = git rev-parse --show-toplevel 2>$null; if ($r) { $r } else { $PWD.Path } }
function Open-TvFiles($Dir, $Query) {
  $files = @(tv files --input "$Query" $Dir)
  if ($files) { nvim -- @($files | ForEach-Object { Join-Path $Dir $_ }) }
}
function Open-TvGrep($Dir, $Query) {
  $hits = @(tv text --input "$Query" $Dir)
  if ($hits.Count -eq 1) {
    $i = $hits[0].LastIndexOf(':')
    nvim "+$($hits[0].Substring($i + 1))" -- (Join-Path $Dir $hits[0].Substring(0, $i))
  } elseif ($hits) {
    $qf = New-TemporaryFile
    $hits | ForEach-Object { "$Dir/$($_): " } | Set-Content $qf
    nvim -q $qf +copen
    Remove-Item $qf
  }
}
function ff { Open-TvFiles (Get-TvRoot) "$args" }
function fF { Open-TvFiles $PWD.Path "$args" }
function sg { Open-TvGrep (Get-TvRoot) "$args" }
function sG { Open-TvGrep $PWD.Path "$args" }
function gb {                                    # origin/x → a local x tracking it
  $b = tv git-branch
  if (-not $b) { return }
  if ($b -like '*/*' -and -not (git rev-parse -q --verify "refs/heads/$b")) {
    git switch ($b -replace '^[^/]+/', ''); if ($?) { return }
  }
  git switch $b
}
function gl { tv git-log }

# --- Sessions (psmux + sesh) ---
# tm and sesh-dir are scripts in ~/.local/bin: psmux runs its popups without this profile.
# nv stays a function, as ~/.local/bin/nv on Linux.
function nv {
  $id = (tmux display -p '#{session_id}' 2>$null) -replace '\$'
  $pipe = "\\.\pipe\nvim-tmux-$(if ($id) { $id } else { 'none' })"
  if (Test-Path $pipe) { nvim @args } else { nvim --listen $pipe @args }
}
