# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- chezmoi source tree and `install.sh` bootstrap for Fedora, Fedora Atomic, Debian/Ubuntu and Arch.
- Ghostty 1.4 config (OSC 52, ssh terminfo, auto-attach to tmux).
- tmux config with sesh project switching, lazygit popup and vim-tmux-navigator.
- sesh config (`~/code/*` wildcard with editor, test-watcher and lazygit windows).
- mise global toolchain (Neovim, runtimes, dev CLIs, sesh via the GitHub backend).
- LazyVim config: Python (basedpyright + ruff), Go, Rust, TypeScript (vtsls), DAP, neotest;
  C# via easy-dotnet.nvim instead of the `lang.dotnet` extra.
- lazygit config using `git.diffRenderers` (delta, difftastic) and a guided Conventional Commit command.
- `nv` / `nv-edit` scripts so lazygit popups open files in the session's Neovim.
- `project-template/` with mise tasks, lefthook, commitlint (rejects `Co-authored-by`), CI check and `launch.json`.
- ADRs 0001, 0002 and 0003.
- Flexoki light/dark theme across Ghostty, tmux, Neovim, lazygit, bat, delta, fzf and yazi, switching with the
  terminal's light/dark (live in tmux, Neovim and ANSI-colored tools).
- yazi config (`theme.toml`) and `.chezmoiremove` for files the repo no longer manages.

### Changed
- Replaced Catppuccin with Flexoki everywhere; removed the catppuccin tmux plugin (TPM now cleans unlisted plugins).
- delta's syntax theme moved into features so lazygit can pass an exact Flexoki theme.

### Fixed
- Login-shell script aborted when `$USER` is unset (containers, cron, systemd); falls back to `id -un`.
- .NET SDK crashed on fresh Debian/Ubuntu for lack of ICU; ICU is now an explicit OS package on every distro.
