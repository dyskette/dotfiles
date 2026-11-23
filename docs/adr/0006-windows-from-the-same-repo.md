# 0006 — Windows from the same repo

## Status
Accepted — 2026-11-23

## Context
The same workflow is needed on Windows machines owned by different companies: same keys, tools and editor config, with as little extra code as possible and no hard-coded machine paths. Ghostty and tmux don't run on Windows.

## Decision
- One chezmoi repo for both systems; `.chezmoiignore` picks files by OS, and chezmoi runs `.ps1` scripts with `pwsh -NoProfile -ExecutionPolicy Bypass`.
- Same mise config; winget only for what mise can't provide (Noctty, psmux, npiperelay, less, MSVC Build Tools) and the bootstrap (Git, PowerShell 7, mise).
- **Noctty** (Ghostty's core on Windows) reads the Ghostty config through an include template, plus `command = pwsh.exe`.
- **psmux** as the multiplexer: `tmux/common.conf` holds what tmux and psmux both support, sourced by `tmux.conf` and `~/.psmux.conf`.
- The PowerShell profile sets `XDG_CONFIG_HOME` (and lf's and bat's equivalents) so tools read `~/.config` as on Linux; VS Code, Zed and Noctty get one-line include templates for their AppData paths. The profile is loaded from `$PROFILE`, so a OneDrive-redirected Documents folder works.
- The shell pickers and `nv` are profile functions; `tm`, `sesh-dir`, `nv-edit` and `projects` are `.ps1` scripts in `~/.local/bin`, so psmux popups (run with `pwsh -NoProfile`) find them, with `.cmd` shims for callers that use cmd (lazygit, tv).

## Consequences
- Untested on Windows: psmux's support for the shared tmux config (Alt prefix, `@pane-is-vim`, popups), Noctty's light/dark theme pairs, the PowerShell init of tv and atuin, and some completion generators. Failures there are skipped, not fatal.
- psmux stays on Flexoki Dark: it has no theme-change hooks.
- Admin is needed once (ssh-agent service, Build Tools, Visual Studio); everything else runs as the user.

## Alternatives
- **Windows Terminal, no multiplexer:** fewer moving parts, but no sessions or sesh.
- **WezTerm:** follows the OS theme and has a smart-splits backend, but replaces both terminal and multiplexer with its own Lua config.
- **A separate Windows repo:** no OS conditionals, but every shared config would be duplicated.
