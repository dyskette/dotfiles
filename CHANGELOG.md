# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- chezmoi source tree and `install.sh` bootstrap for Fedora, Fedora Atomic, Debian/Ubuntu and Arch.
- Ghostty, tmux, sesh, mise, lazygit, LazyVim (C# via easy-dotnet.nvim), lf, television, atuin and starship configs.
- Flexoki light/dark everywhere, following the terminal (ADR 0003).
- Project roots `~/Proyectos`, `~/Projects`, `~/source/repos`, `/c/s` for sesh, mise auto-trust and the session picker.
- Shell pickers named after LazyVim's keys (`ff`, `fF`, `sg`, `sG`, `gb`, `gl`), `tm`, `e`, `gg`, `ee`.
- bash completions for the mise-managed CLIs.
- Claude Code, GitHub Copilot CLI and opencode through mise; opencode's config and Copilot 1M-context plugin.
- Claude Code settings: no commit/PR attribution, auto permission mode, theme following the terminal.
- VS Code (native and Flatpak), Zed and JetBrains IdeaVim settings.
- terraform, Azure CLI, Azure Functions Core Tools and the Aspire CLI through mise.
- Java (Temurin 21) through mise.
- `project-template/` with mise tasks, lefthook, commitlint and CI.
- ADRs 0001–0004 and `docs/testing.md`.

### Changed
- The shell is bash instead of zsh.
- Ghostty no longer starts tmux on its own.
- tmux prefix is `M-a` instead of `C-Space`; the sesh picker moved from `prefix T` to `prefix s`.
- `M-h/j/k/l` moves and `M-H/J/K/L` resizes across Neovim and tmux; smart-splits.nvim replaces vim-tmux-navigator (ADR 0004).
- Flexoki replaces Catppuccin.

### Removed
- fzf and yazi (television and lf replace them).

### Fixed
- Login-shell script aborted when `$USER` is unset; falls back to `id -un`.
- .NET SDK crashed on fresh Debian/Ubuntu for lack of ICU.
