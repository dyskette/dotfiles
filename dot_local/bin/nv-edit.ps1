# nv-edit FILE [LINE]: open FILE in this psmux session's Neovim (`nv`), else a new nvim.
param([Parameter(Mandatory)][string]$File, [string]$Line)
# In VS Code's terminal (lazygit from <leader>gg there), open it in that VS Code window instead.
if ($env:TERM_PROGRAM -eq 'vscode') { code --reuse-window --goto "$((Resolve-Path $File).Path)$(if ($Line) { ":$Line" })"; exit }
$id = (tmux display -p '#{session_id}' 2>$null) -replace '\$'
$pipe = "\\.\pipe\nvim-tmux-$(if ($id) { $id } else { 'none' })"
if (Test-Path $pipe) {
  nvim --server $pipe --remote (Resolve-Path $File).Path
  if ($Line) { nvim --server $pipe --remote-send "<C-\><C-n>:$Line<CR>" }
  tmux select-window -t "$(tmux display -p '#S'):1" 2>$null
} elseif ($Line) { nvim "+$Line" $File } else { nvim $File }
