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
- IdeaVim config on LazyVim's options and keys (pickers, LSP, diagnostics, git hunks, buffers/windows, debug, tests with Rider variants), with IdeaVim's bundled mini-ai, sneak, NERDTree, commentary, surround and which-key.
- VS Code runs LazyVim through vscode-neovim with LazyVim's keys (`plugins/vscode.lua`, ADR 0007); VSCodeVim, magit and oil keymaps removed; language extensions matching the LazyVim lang extras.
- VS Code installed on Linux (Flathub) and Windows (winget), extensions from `.chezmoidata/vscode.toml`, Flexoki theme following the OS, host bash / PowerShell 7 terminals; mise shims on the Windows user `PATH`.
- terraform, Azure CLI, Azure Functions Core Tools and the Aspire CLI through mise.
- Java (Temurin 21) through mise.
- `project-template/` with mise tasks, lefthook, commitlint and CI.
- WSL: SSH through the Windows OpenSSH agent (systemd relay) and SSH config/public keys synced from Windows (ADR 0005).
- Windows setup from the same repo: `install.ps1`, Noctty, psmux (shared `tmux/common.conf`), a PowerShell profile with the same pickers and commands, and `.ps1` setup scripts (ADR 0006).
- Windows: Visual Studio Enterprise 2026 with the components in `.chezmoidata/visualstudio.toml`, installed or completed on `chezmoi apply`.
- Visual Studio extensions from `.chezmoidata/visualstudio.toml`: VsVim 2026 from the Marketplace, VsNerdX and the Flexoki theme from their GitHub releases, installed into the VS 2026 instance only (not SSMS). Visual Studio follows the system light/dark mode with Flexoki Dark and Light.
- `~/.vsvimrc` (Windows): VsVim with the IdeaVim config's LazyVim options and keys, through Visual Studio commands.
- pandoc through mise, with bash completion.
- Windows: `less` from winget, so `bat` and `delta` page outside git.
- `ocm`: a tv channel (`opencode-sessions`) listing the current project's opencode sessions, newest first, plus a new-session entry, opened in `opencode mini`.
- Windows: `tm` and `sesh-dir` are `~/.local/bin` scripts instead of profile functions, so psmux's `prefix s` and `prefix a` popups find them.
- PowerShell profile: UTF-8 console encoding with native programs; `Ctrl+p`/`Ctrl+n` prefix history search, `Ctrl+y` accept suggestion, `Ctrl+d` delete or exit.
- Windows Explorer settings for the user: file extensions and hidden files shown, taskbar and Alt+Tab across all virtual desktops, Alt+Tab without browser tabs.
- ADRs 0001–0006 and `docs/testing.md`.

### Changed
- Windows: the PowerShell profile starts in ~1.0 s instead of ~1.9 s and renders each prompt in ~1 ms instead of ~260 ms: cached tool init scripts, completions and tv loaded on first use, an in-process prompt instead of starship, and `pwsh -c`/`-File` skip the interactive setup (ADR 0010). starship is installed only on Linux and macOS.
- The shell is bash instead of zsh.
- Ghostty no longer starts tmux on its own.
- tmux prefix is `M-a` instead of `C-Space`; the sesh picker moved from `prefix T` to `prefix s`.
- `M-h/j/k/l` moves and `M-H/J/K/L` resizes across Neovim and tmux; smart-splits.nvim replaces vim-tmux-navigator (ADR 0004).
- Flexoki replaces Catppuccin.
- Windows: .NET comes from winget (SDK 10) and Visual Studio instead of mise, and `DOTNET_ROOT` is no longer set; mise installs .NET only on Linux and macOS (ADR 0001).
- Windows: the television sesh channel runs its sources through `cmd`, so its Projects source finds the `projects.cmd` shim instead of a `projects.ps1` that Windows PowerShell's execution policy blocks.
- `project-template/mise.toml` skips .NET on Windows too, so entering a project made from it no longer installs a second SDK and `dotnet` shim through mise.
- Neovim on Windows: lookups, Mason tool starts, clipboard and the ps1 ftplugin no longer cost a PATH walk or a process each; LSP, gitsigns, nvim-lint and todo-comments load after the first screen, blink.cmp while idle, smart-splits on its keys, gitsigns without a `git --version` per start (ADR 0008).
- Neovim: lualine and bufferline replaced by a cached statusline and tabline with the same layout and keys (ADR 0008).

### Removed
- fzf and yazi (television and lf replace them).

### Fixed
- Windows: `nuget.exe restore` and `vswhere -latest -requires Microsoft.Component.MSBuild` scripts picked the MSVC Build Tools' MSBuild, which has no .NET SDK resolver, and skipped SDK-style projects. MSVC now comes from Visual Studio Enterprise 2026 and the Build Tools are no longer installed (ADR 0009).
- Neovim on Windows: the mise shims were appended to PATH with `:`, corrupting its last entry.
- .NET global tools (easy-dotnet, roslyn-language-server) and JDK lookups failed outside interactive terminals: `DOTNET_ROOT` and `JAVA_HOME` are now set for the whole session.
- Login-shell script aborted when `$USER` is unset; falls back to `id -un`.
- .NET SDK crashed on fresh Debian/Ubuntu for lack of ICU.
