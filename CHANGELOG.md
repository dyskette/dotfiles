# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- chezmoi source tree and `install.sh` bootstrap for Fedora, Fedora Atomic, Debian/Ubuntu and Arch.
- Ghostty 1.4 config (OSC 52, ssh terminfo, auto-attach to tmux).
- tmux config with sesh project switching, lazygit popup and vim-tmux-navigator.
- sesh config (wildcard with editor, test-watcher and lazygit windows).
- mise global toolchain (Neovim, runtimes, dev CLIs, sesh via the GitHub backend).
- LazyVim config: Python (basedpyright + ruff), Go, Rust, TypeScript (vtsls), DAP, neotest;
  C# via easy-dotnet.nvim instead of the `lang.dotnet` extra.
- lazygit config using `git.diffRenderers` (delta, difftastic) and a guided Conventional Commit command.
- `nv` / `nv-edit` scripts so lazygit popups open files in the session's Neovim.
- `project-template/` with mise tasks, lefthook, commitlint (rejects `Co-authored-by`), CI check and `launch.json`.
- ADRs 0001, 0002 and 0003.
- Flexoki light/dark theme across Ghostty, tmux, Neovim, lazygit, bat and delta, switching with the
  terminal's light/dark (live in tmux, Neovim and ANSI-colored tools).
- jq, yq and poetry in the mise toolchain.
- Project roots `~/Proyectos`, `~/Projects`, `~/source/repos`, `/c/s`: sesh wildcards (`/**`, any depth),
  mise auto-trust, and a `projects` lister that feeds the session picker.
- television `sesh` channel (tmux `prefix s`, `tm`; `C-s` cycles All/Projects/Tmux/Zoxide), `sesh-dir` (tmux `prefix a`, lf as folder picker), `tm [DIR]`.
- lf (GitHub backend in mise) with rounded borders and Nerd Font icons, as the tmux folder chooser.
- Claude Code and GitHub Copilot CLI through mise, with their self-updaters disabled.
- zsh completions for the mise-managed CLIs (`run_onchange_after_25-zsh-completions`, `_eza`/`_lf` externals) and a
  once-a-day `compinit` rescan.
- Neovim picker layouts (`plugins/picker.lua`, wide and narrow): query, results and preview in separate rounded
  boxes, like the shell's television pickers; both stack the preview below the list under ~120 columns.
- Ghostty's zsh shell integration sourced from `~/.zshrc`, so it also works inside tmux (OSC 133 marks, OSC 7).
- tmux: pane and full-width/full-height splits, vi copy-mode keys, window titles, `update-environment` for `TERM`/`TERM_PROGRAM`.
- Shell pickers named after LazyVim's keys (`ff`, `fF`, `sg`, `sG`, `gb`, `gl`) and Ctrl-T, as television
  (`tv`) channels with its defaults; ripgrep config with snacks.nvim's search defaults.
- Neovim's grep pickers show the file name first (snacks `filename_first`).
- `e` (lf) and `gg` (lazygit); eza (`ls`/`ll`/`la`/`lt`) and bat (`cat`, `MANPAGER`) integration.
- `ee` to open the file manager (Nautilus, or Explorer in WSL).
- `docs/testing.md`: runbook for testing a fresh install in Fedora and Ubuntu podman containers.

### Changed
- tmux prefix is now `M-a` (Alt-a) instead of `C-Space`.
- Moving between Neovim splits and tmux panes is now `M-h/j/k/l` (Alt) instead of `C-h/j/k/l`, and
  `M-H/J/K/L` resizes them; smart-splits.nvim replaces vim-tmux-navigator (ADR 0004).
- sesh picker moved from `prefix T` to `prefix s`; the `~/code/*` wildcard is replaced by the project roots.
- Replaced Catppuccin with Flexoki everywhere; removed the catppuccin tmux plugin (TPM now cleans unlisted plugins).
- delta's syntax theme moved into features so lazygit can pass an exact Flexoki theme.

### Fixed
- Login-shell script aborted when `$USER` is unset (containers, cron, systemd); falls back to `id -un`.
- .NET SDK crashed on fresh Debian/Ubuntu for lack of ICU; ICU is now an explicit OS package on every distro.
