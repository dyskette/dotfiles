# Print every git repository or worktree under the project roots, as tv's sesh channel lists them.
#   PROJECT_ROOTS  semicolon-separated roots; keep the default in sync with sesh.toml and mise
#   PROJECT_DEPTH  how deep to look for .git (default 3: <root>/<org>/<repo>/.git)
$roots = @(($env:PROJECT_ROOTS ?? "$HOME\Proyectos;$HOME\Projects;$HOME\source\repos;C:\s") -split ';' | Where-Object { Test-Path $_ })
if ($roots) {
  fd --hidden --no-ignore --type d --type f --max-depth ($env:PROJECT_DEPTH ?? 3) --prune --format '{//}' '^\.git$' @roots |
    Sort-Object -Unique | ForEach-Object { "$([char]0xf114) $_" }
}
