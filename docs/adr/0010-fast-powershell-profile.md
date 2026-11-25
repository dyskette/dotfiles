# 0010 — A faster PowerShell profile without a build step

## Status
Accepted — 2026-11-25

## Context
On Windows the profile took ~1.3 s of a 1.9 s start (time until you can type), and every prompt took ~260 ms. On this hardware, endpoint security makes each process spawn cost 40 ms warm and 0.4–0.9 s cold. Measured costs, warm:

- Running the five init scripts (mise, tv, zoxide, atuin, starship): ~800 ms, mostly PowerShell evaluating ~70 KB of generated script. Spawning the tools to produce them: ~240 ms warm, ~2 s cold.
- Dot-sourcing one 1.3 MB completions file: 140–330 ms.
- `starship prompt` on every prompt: ~260 ms, ~145 ms of it `git_status`. No starship setting got it under ~100 ms: `use_git_executable` halves `git_status`, but modules run in parallel, so the total barely moves.
- `pwsh -c` from editors, lazygit and tasks paid the whole profile too.

The experiment in `~/Projects/fast-pwsh` reached 0.65 s and 0.7 ms per prompt with a build step, a compiled C# helper and a background `git status` with a forced redraw. That build is machine-specific and lives outside the repo, so profile edits made in this repo stopped reaching the shell. Its lessons that need no build step are the ones taken here.

## Decision
- **Cached init scripts.** `__pwsh_init_cache` keeps each tool's init output in `%LOCALAPPDATA%\pwsh-init`, keyed on the tool executable's path and mtime: one file read per tool, no spawn. A changed or missing executable regenerates that one file. mise's leading `${Env:PATH}=` line is dropped, so a cached copy doesn't pin PATH.
- **Completions on first Tab.** `run_onchange_after_26-completions` writes one script per CLI to `%LOCALAPPDATA%\powershell-completions`, with `Register-ArgumentCompleter` renamed to `__pwsh_register_completer`. The profile registers one stub for all of them; a CLI's script loads, as a module, on its first Tab.
- **tv on first Ctrl+T.** Only tv's functions load, as a module. Its key handlers are skipped (atuin owns Ctrl+R).
- **No `atuin uuid` spawn.** The profile sets `ATUIN_SESSION` to an in-process UUIDv7 (pwsh 7.5+), which atuin's script then keeps.
- **In-process prompt instead of starship on Windows.** It shows the directory (repo-relative, last three parts), the branch read from `.git/HEAD` (worktrees and detached HEAD too), the last command's duration from 2 s, and a ❯ that turns red after a failure. ANSI colours, so it follows the terminal's Flexoki theme. It hands `$?` and `$LASTEXITCODE` back unchanged, for atuin. starship stays on Linux and macOS; mise installs it only there.
- **Non-interactive shells stop early.** With `-Command`, `-File` or `-EncodedCommand` (without `-NoExit`), `-NonInteractive` or redirected stdin, the profile sets the environment, mise and the functions, then returns. `PWSH_INTERACTIVE=1|0` overrides the detection.

## Consequences
- Measured with `fast-pwsh/bench/bench.ps1` (10 runs, medians): start until ready 1.94 s → 1.04 s (empty profile: 0.65 s); prompt ~260 ms → 1.1 ms; `pwsh -c "node --version"` 1.97 s → 0.83 s.
- The prompt has no dirty, ahead/behind or language-version markers. Adding git status back would need a background job and a redraw: fast-pwsh's mechanism, and the reason it needed compiled code.
- mise's prompt hook is not chained, as it wasn't under starship: mise updates the environment on `cd`, not after editing `mise.toml` in the current directory (`cd .` refreshes it).
- Remaining costs: evaluating mise's and atuin's scripts (~400 ms together), and atuin's synchronous `history start` on every Enter (~60 ms).
- A cached init script changes only when its executable does. After changing a tool's own config in a way that changes its init output, delete `%LOCALAPPDATA%\pwsh-init`.

## Alternatives
- **Keep starship with `git_status` disabled:** one line of config and the same look on every OS, but ~100 ms per prompt and still no dirty markers.
- **Adopt fast-pwsh (build step and compiled helper):** 0.65 s start and a full git status, but a machine-specific build outside the repo, C# to maintain, and a prompt to keep in parity with starship by hand.
- **mise shims instead of `mise activate`:** nothing to evaluate at start, but no per-project `[env]` and a shim hop on every tool call; `project-template/mise.toml` uses `[env]`.
