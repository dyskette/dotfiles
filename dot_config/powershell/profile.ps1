# Windows counterpart of ~/.bash_profile + ~/.bashrc, loaded from $PROFILE.
# Kept cheap to start (ADR 0010): tool init scripts come from a cache, completions and tv load on first
# use, the prompt is rendered in-process, and `pwsh -c`/`-File` skip everything interactive.

# --- Environment, for every host ---
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

<#
.SYNOPSIS
Whether pwsh was started as a REPL: no -Command/-File/-EncodedCommand (unless with -NoExit), not
-NonInteractive, stdin not redirected. $env:PWSH_INTERACTIVE = '1' or '0' overrides it.
#>
function __pwsh_is_interactive {
  if ($env:PWSH_INTERACTIVE) { return $env:PWSH_INTERACTIVE -eq '1' }
  $argv = [Environment]::GetCommandLineArgs()
  $noExit = $false
  for ($i = 1; $i -lt $argv.Count; $i++) {
    if ($argv[$i] -notmatch '^[-/]+([^:]+)(:.*)?$') { return $noExit }  # a script path, as with -File
    $n = $Matches[1].ToLowerInvariant(); $inline = [bool]$Matches[2]
    if ($n -match '^(noe|noex|noexi|noexit)$') { $noExit = $true }
    elseif ($n -match '^nonin') { return $false }
    elseif ($n -match '^(c|co|com|comm|comma|comman|command|f|fi|fil|file|e|ec|en|enc|enco|encod|encode|encoded|encodedc.*|cwa|commandw.*)$') { return $noExit }
    elseif ($n -match '^(wd|wo.*|ep|ex.*|configurationn.*|configurationf.*|cu.*|if|in.*|o|of|ou.*|se.*|w|wi.*|ea|encodeda.*)$') {
      if (-not $inline) { $i++ }  # skip the value
    }
  }
  -not [Console]::IsInputRedirected
}
$__pwsh_interactive = __pwsh_is_interactive

<#
.SYNOPSIS
Path of TOOL's cached init script (`TOOL INITARGS` output), regenerated when the tool's executable changes.
.DESCRIPTION
Spawning a tool costs 40 ms warm and up to 900 ms cold on endpoint-scanned machines, so the output is kept
in %LOCALAPPDATA%\pwsh-init and checked against the executable's mtime: one file read, no spawn.
Returns nothing when the tool isn't installed. Must be dot-sourced by the caller, at the profile's scope.
#>
function __pwsh_init_cache([string]$Tool, [string[]]$InitArgs) {
  $file = "$env:LOCALAPPDATA\pwsh-init\$Tool.ps1"
  $key = "$file.key"
  if ([IO.File]::Exists($key) -and [IO.File]::Exists($file)) {
    $exe, $ticks = [IO.File]::ReadAllText($key) -split '\|'
    if ([IO.File]::GetLastWriteTimeUtc($exe).Ticks -eq [long]$ticks) { return $file }
  }
  $exe = (Get-Command $Tool -CommandType Application -ErrorAction Ignore | Select-Object -First 1).Source
  if (-not $exe) { return }
  # A shim's mtime doesn't change when the tool is upgraded; key on the real executable.
  if ($exe -like '*\mise\shims\*') { $exe = mise which $Tool 2>$null; if (-not $exe) { return } }
  $text = & $exe @InitArgs | Out-String
  if (-not $text) { return }
  # mise's script starts by setting PATH to this shell's PATH; a cached copy would pin every later shell to it.
  if ($Tool -eq 'mise') { $text = $text -replace '(?m)^\$\{Env:PATH\}=.*\r?\n', '' }
  $null = [IO.Directory]::CreateDirectory("$env:LOCALAPPDATA\pwsh-init")
  [IO.File]::WriteAllText($file, $text)
  [IO.File]::WriteAllText($key, "$exe|$([IO.File]::GetLastWriteTimeUtc($exe).Ticks)")
  $file
}

if ($f = __pwsh_init_cache mise 'activate', 'pwsh') { . $f }

# --- Commands ---
# Built-in aliases win over functions, so drop the ones replaced below.
# PowerShell's own nv alias (New-Variable) would win over the nv function too.
'ls', 'cat', 'gl', 'nv' | ForEach-Object { Remove-Item "Alias:$_" -Force -ErrorAction Ignore }
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
function ocm {                                   # opencode session picker; "+ New session" starts one
  $s = tv opencode-sessions
  if ($s -eq 'new') { opencode mini } elseif ($s) { opencode mini --session $s }
}
# cd pickers, searching from the current directory: a folder, or the folder holding a file.
function cdd { $d = @(tv dirs --input "$args")[0]; if ($d) { Set-Location -LiteralPath $d } }
function cdf {
  $f = @(tv files --input "$args")[0]
  if ($f -and ($d = Split-Path -Parent $f)) { Set-Location -LiteralPath $d }
}

# --- Sessions (psmux + sesh) ---
# tm and sesh-dir are scripts in ~/.local/bin: psmux runs its popups without this profile.
# nv stays a function, as ~/.local/bin/nv on Linux.
function nv {
  $id = (tmux display -p '#{session_id}' 2>$null) -replace '\$'
  $pipe = "\\.\pipe\nvim-tmux-$(if ($id) { $id } else { 'none' })"
  if (Test-Path $pipe) { nvim @args } else { nvim --listen $pipe @args }
}

if (-not $__pwsh_interactive) { return }

# --- Interactive only ---
# Completions: one stub for every CLI with a script in %LOCALAPPDATA%\powershell-completions (written by
# run_onchange_after_26-completions); a CLI's script loads on its first Tab.
$__pwsh_completions = "$env:LOCALAPPDATA\powershell-completions"
$global:__pwsh_completers = @{}
if ([IO.Directory]::Exists($__pwsh_completions)) {
  $names = foreach ($f in [IO.Directory]::GetFiles($__pwsh_completions, '*.ps1')) {
    $n = [IO.Path]::GetFileNameWithoutExtension($f); $n; "$n.exe"
  }
  if ($names) { Register-ArgumentCompleter -Native -CommandName $names -ScriptBlock { __pwsh_complete $args } }
}
function __pwsh_complete($a) {
  $name = [IO.Path]::GetFileNameWithoutExtension($a[1].GetCommandName())
  if (-not $__pwsh_completers.ContainsKey($name)) {
    $file = "$__pwsh_completions\$name.ps1"
    if (-not [IO.File]::Exists($file)) { return }
    $__pwsh_completers[$name] = $null
    # A module keeps the script's helper functions alive for its completer, as dot-sourcing it would.
    $null = New-Module -Name "completion-$name" -ScriptBlock ([scriptblock]::Create([IO.File]::ReadAllText($file)))
  }
  $block = $__pwsh_completers[$name]
  if ($block) { & $block @a }
}
# The completion scripts call this in place of Register-ArgumentCompleter, so the first Tab can run the
# completer it just loaded.
function __pwsh_register_completer([string[]]$CommandName, [string]$ParameterName, [scriptblock]$ScriptBlock, [switch]$Native) {
  foreach ($c in $CommandName) { $global:__pwsh_completers[[IO.Path]::GetFileNameWithoutExtension($c)] = $ScriptBlock }
  Microsoft.PowerShell.Core\Register-ArgumentCompleter @PSBoundParameters
}

# Emacs-style keys bash has too; none collide with tv's or atuin's (Ctrl+T, Ctrl+R, Up).
Set-PSReadLineKeyHandler -Key 'Ctrl+p' -Function HistorySearchBackward  # previous line starting with what's typed
Set-PSReadLineKeyHandler -Key 'Ctrl+n' -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key 'Ctrl+y' -Function AcceptSuggestion       # take the grey prediction
Set-PSReadLineKeyHandler -Key 'Ctrl+d' -Function DeleteCharOrExit
Set-PSReadLineOption -ContinuationPrompt "`e[90m∙`e[0m "

# tv's Ctrl+T, loaded on its first press. Only its functions: its key handlers would take Ctrl+R from
# atuin, and its completer loads on Tab like the others.
function __pwsh_tv {
  if (-not $global:__pwsh_tv_module) {
    if (-not ($f = __pwsh_init_cache tv 'init', 'power-shell')) { return }
    $ast = [Management.Automation.Language.Parser]::ParseFile($f, [ref]$null, [ref]$null)
    $text = @($ast.UsingStatements.Extent.Text) +
      @($ast.EndBlock.Statements | Where-Object { $_ -is [Management.Automation.Language.FunctionDefinitionAst] } | ForEach-Object { $_.Extent.Text })
    $global:__pwsh_tv_module = New-Module -Name tv-shell -ScriptBlock ([scriptblock]::Create($text -join "`n"))
  }
  $global:__pwsh_tv_module
}
Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock { if ($m = __pwsh_tv) { & $m { Invoke-TvSmartAutocomplete } } }

if ($f = __pwsh_init_cache zoxide 'init', 'powershell') { . $f }
# atuin's script spawns `atuin uuid` for a session id unless one is set for this process: make the same
# UUIDv7 in-process (.NET 9+, so pwsh 7.5+; older versions let atuin spawn).
if ($env:ATUIN_PID -ne "$PID") {
  try { $env:ATUIN_SESSION = [guid]::CreateVersion7().ToString('N'); $env:ATUIN_PID = $PID } catch { }
}
# The prompt is always two lines; atuin would otherwise render it once to count them.
$env:ATUIN_POWERSHELL_PROMPT_OFFSET = '-1'
if ($f = __pwsh_init_cache atuin 'init', 'powershell') { . $f }
Remove-Variable f, d, names, n -ErrorAction Ignore

# --- Prompt: starship's default look for this config, rendered in-process (ADR 0010) ---
# Line 1: directory (repo-relative, last 3 parts), git branch or detached commit, duration of the last
# command when it took 2 s or more. Line 2: ❯, red after a failure. ANSI colours, so it follows the theme.

<# .SYNOPSIS The git work tree containing DIR and its HEAD's content, read from .git without running git. #>
function __pwsh_git_head([string]$Dir) {
  for ($d = $Dir; $d; $d = [IO.Path]::GetDirectoryName($d)) {
    $dotGit = [IO.Path]::Join($d, '.git')
    if ([IO.Directory]::Exists($dotGit)) { $gitDir = $dotGit }
    elseif ([IO.File]::Exists($dotGit)) {               # a worktree or submodule: "gitdir: <path>"
      $line = [IO.File]::ReadAllText($dotGit).Trim()
      if (-not $line.StartsWith('gitdir:')) { continue }
      $gitDir = [IO.Path]::GetFullPath($line.Substring(7).Trim(), $d)
    } else { continue }
    $head = try { [IO.File]::ReadAllText([IO.Path]::Join($gitDir, 'HEAD')).Trim() } catch { '' }
    return @{ Root = $d; Head = $head }
  }
}

$global:__pwsh_prompt_failure = [Management.Automation.ErrorRecord]::new([Exception]::new('previous command failed'), 'Prompt', 'NotSpecified', $null)
$global:__pwsh_prompt_last_id = 0

function prompt {
  [CmdletBinding()] param()
  $ok = $?
  $code = $global:LASTEXITCODE
  $loc = $ExecutionContext.SessionState.Path.CurrentLocation
  $out = [Text.StringBuilder]::new()
  $repo = $null

  if ($loc.Provider.Name -eq 'FileSystem') {
    $path = $loc.ProviderPath
    $repo = __pwsh_git_head $path
    if ($repo -and ($parent = [IO.Path]::GetDirectoryName($repo.Root))) {
      $path = $path.Substring($parent.Length).TrimStart('\')   # truncate_to_repo
    } elseif ($path -eq $HOME -or $path.StartsWith("$HOME\", [StringComparison]::OrdinalIgnoreCase)) {
      $path = '~' + $path.Substring($HOME.Length)
    }
    $parts = $path.TrimEnd('\') -split '\\'
    if ($parts.Count -gt 3) { $path = $parts[-3..-1] -join '\' }
  } else {
    $path = $loc.Path
  }
  [void]$out.Append("`e[1;36m$path`e[0m ")

  if ($repo.Head -like 'ref: refs/heads/*') {
    [void]$out.Append("on `e[1;35m`u{e0a0} $($repo.Head.Substring(16))`e[0m ")
  } elseif ($repo.Head) {
    [void]$out.Append("`e[1;32m($($repo.Head.Substring(0, [Math]::Min(7, $repo.Head.Length))))`e[0m ")
  }

  # Only for a command that just ran, not again on an empty Enter.
  $last = Get-History -Count 1
  if ($last -and $last.Id -ne $global:__pwsh_prompt_last_id) {
    $global:__pwsh_prompt_last_id = $last.Id
    $t = $last.EndExecutionTime - $last.StartExecutionTime
    if ($t.TotalSeconds -ge 2) {
      $took = if ($t.TotalHours -ge 1) { '{0}h{1}m{2}s' -f [int][Math]::Floor($t.TotalHours), $t.Minutes, $t.Seconds }
              elseif ($t.TotalMinutes -ge 1) { '{0}m{1}s' -f $t.Minutes, $t.Seconds }
              else { '{0}s' -f $t.Seconds }
      [void]$out.Append("took `e[1;33m$took`e[0m ")
    }
  }

  [void]$out.Append("`n").Append($(if ($ok) { "`e[1;32m❯`e[0m " } else { "`e[1;31m❯`e[0m " }))
  $global:LASTEXITCODE = $code
  # Hand $? back as it was, for atuin's history: the only quiet way to leave it false is an ignored
  # error from an advanced function.
  if (-not $ok) { $ErrorActionPreference = 'Ignore'; $PSCmdlet.WriteError($global:__pwsh_prompt_failure) }
  $out.ToString()
}
