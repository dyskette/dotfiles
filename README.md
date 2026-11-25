# dotfiles — terminal-first LazyVim IDE

A [chezmoi](https://www.chezmoi.io/) source repo that turns a blank Linux or Windows machine into a terminal IDE for C#, Python, TypeScript, Rust and Go:

```
Ghostty → tmux + sesh (one session per repo) → bash + mise → nvim (LazyVim)
Noctty  → psmux + sesh                     → pwsh + mise → nvim (LazyVim)     (Windows, ADR 0006)
```

Each binary has one owner: OS packages, mise, Mason (editor-only servers, appended to Neovim's `PATH` so a repo's mise pins win), `dotnet tool` or rustup ([ADR 0001](docs/adr/0001-chezmoi-and-tool-ownership.md)).

## Setup

Supported: Fedora, Fedora Atomic, Debian/Ubuntu, Arch.

```sh
git clone <this-repo-url> ~/.local/share/chezmoi
~/.local/share/chezmoi/install.sh
```

`install.sh` installs mise and chezmoi, then `chezmoi init --apply` asks for your git name/email and runs `.chezmoiscripts/`. On Fedora Atomic, reboot when asked and run `chezmoi apply` again.

Then log out and back in, open Ghostty, run `tmux new -A -s main`, start `nvim` once so Mason installs servers, and run `:checkhealth`. Commit the generated `lazy-lock.json` (`chezmoi re-add ~/.config/nvim/lazy-lock.json`).

### Windows

```powershell
git clone <this-repo-url> $HOME\.local\share\chezmoi
powershell -ExecutionPolicy Bypass -File $HOME\.local\share\chezmoi\install.ps1
```

`install.ps1` installs Git, PowerShell 7 and mise with winget, enables the Windows OpenSSH agent (one UAC prompt), and runs `chezmoi init --apply`. The `.ps1` scripts in `.chezmoiscripts/` install Noctty, psmux, npiperelay, less, and VS Code, put mise's shims on the user `PATH` (for VS Code and other apps started outside PowerShell), set Explorer to show file extensions and hidden files, then the same mise toolchain, fonts, .NET tools and Neovim plugins. They also install Visual Studio Enterprise 2026, which also provides MSVC ([ADR 0009](docs/adr/0009-msvc-from-visual-studio.md)), with the components and extensions (VsVim, VsNerdX, Flexoki) in `.chezmoidata/visualstudio.toml`, with Flexoki following the system light/dark mode. Then open Noctty and run `psmux`.

The keys and shell commands below are the same; the PowerShell profile is `~/.config/powershell/profile.ps1`, loaded from `$PROFILE`. On company machines: trust the corporate root certificate for mise, uv and npm (`SSL_CERT_FILE`, `NODE_EXTRA_CA_CERTS`) if TLS is inspected; a Defender exclusion for `%LOCALAPPDATA%\mise` and `LongPathsEnabled` speed up and unblock installs (both need admin).

## Per-project setup

Copy what a repo needs from `project-template/` (not applied to `$HOME`), then `mise trust && mise install && mise run hooks:install`.

Repos under `~/Proyectos`, `~/Projects`, `~/source/repos` and `/c/s` are auto-trusted by mise, listed in the session picker and opened with the sesh layout (`nv`, `test`, `git`). The roots are in `sesh.toml`, `mise/config.toml` and `~/.local/bin/projects`; keep them in sync.

## Keys

| Key | Action |
|---|---|
| `M-a` | tmux prefix |
| `M-h/j/k/l`, `M-H/J/K/L` | move / resize across Neovim splits and tmux panes |
| `prefix s`, `tm [DIR]` | session picker / open a folder's session |
| `prefix a` | open a session in a folder picked with lf |
| `prefix g`, `<leader>gg` | lazygit |
| `ff`/`fF`, `sg`/`sG`, `gb`, `gl` | shell pickers (tv), named after LazyVim's keys |
| `e`, `gg`, `ee` | lf, lazygit, desktop file manager |

VS Code runs the same LazyVim config through vscode-neovim, with LazyVim's keys mapped to VS Code commands ([ADR 0007](docs/adr/0007-vscode-runs-lazyvim.md)); uninstall VSCodeVim first.

## Theme

Flexoki follows Ghostty's light/dark; tmux (≥ 3.6) and Neovim switch live ([ADR 0003](docs/adr/0003-flexoki-theme-following-terminal.md)).

## Environment variables

| Variable | Set by | Purpose |
|---|---|---|
| `PATH`, `EDITOR`, `VISUAL`, `XDG_CONFIG_HOME` | `~/.bash_profile`, mise | |
| `RIPGREP_CONFIG_PATH` | `~/.bash_profile` | `rg` uses snacks' grep defaults |
| `DOTNET_ROOT`, `JAVA_HOME` | `~/.bash_profile`; Windows: `JAVA_HOME` only, a user variable refreshed on every `chezmoi apply` (.NET is the machine-wide install) | .NET global tools and IDEs find mise's SDKs outside terminals |
| `XDG_CONFIG_HOME`, `LF_CONFIG_HOME`, `BAT_CONFIG_DIR` | Windows: PowerShell profile; `XDG_CONFIG_HOME` is also a user variable, for programs started outside PowerShell (VS Code's Neovim from the Start menu) | tools read `~/.config` as on Linux |
| `DISABLE_AUTOUPDATER`, `COPILOT_AUTO_UPDATE` | mise `[env]` | mise updates Claude Code and Copilot CLI |
| `PROJECT_ROOTS`, `PROJECT_DEPTH` | optional | override what `projects` scans |
| `WIN_SSH_DIR`, `NPIPERELAY` | WSL: `~/.config/environment.d`, resolved by `chezmoi apply` | Windows `~/.ssh` and `npiperelay.exe` for the SSH relay ([ADR 0005](docs/adr/0005-wsl-ssh-through-windows-agent.md)) |
| `SSH_AUTH_SOCK` | WSL: `~/.bash_profile` | the relay to the Windows OpenSSH agent |

No secrets live in this repo: per-repo secrets go in `mise.local.toml` (git-ignored) from your vault; dotfiles secrets use chezmoi's password-manager functions.

## Runbook

**Update (on a branch):** `mise upgrade --bump`; in Neovim `:Lazy update`, `:MasonUpdate`, `:checkhealth`; `dotnet tool update -g EasyDotnet` and `dotnet tool update -g roslyn-language-server --prerelease`; run one test per language; `chezmoi re-add ~/.config/nvim/lazy-lock.json` and commit. Read the LazyVim and easy-dotnet changelogs first.

**Rollback:** `git revert` the update commit, `chezmoi apply`, then `:Lazy restore`.

**Testing:** before merging changes to `.chezmoiscripts/`, `install.sh`, the toolchain or the theme, run [docs/testing.md](docs/testing.md).

| Symptom | Fix |
|---|---|
| `xterm-ghostty: unknown terminal` over SSH | `infocmp -x xterm-ghostty \| ssh host -- tic -x -` |
| Two C# servers | `:MasonUninstall omnisharp`; keep the `lang.dotnet` extra off |
| Wrong solution picked by Roslyn | `dotnet restore`, open at the solution root, `<leader>Ns` |
| "No version is set" inside Neovim | `mise trust` in the repo |
| neotest-golang finds no tests | `:TSUpdate go` |
| Completions stale after `mise up` | `chezmoi state delete-bucket --bucket=scriptState && chezmoi apply` |
| tmux bindings can't find `sesh`/`tv` | `tmux kill-server`, start tmux from a shell that has them on `PATH` |
| tmux or Neovim stays dark | needs tmux ≥ 3.6; `prefix r` |
| WSL: `ssh-add -l` fails | `systemctl --user status ssh-agent-relay`; needs systemd, interop and npiperelay on Windows; after moving them, `chezmoi apply` and log in again |
| WSL: SSH config or keys out of date | `ssh-sync` (also runs every 5 minutes) |
| `chezmoi apply` fails with "Close Visual Studio" | close it and apply again; the extensions install only while it is closed |

## Decisions

- [ADR 0001 — chezmoi + single-owner toolchain](docs/adr/0001-chezmoi-and-tool-ownership.md)
- [ADR 0002 — easy-dotnet.nvim for C#](docs/adr/0002-easy-dotnet-for-csharp.md)
- [ADR 0003 — Flexoki, following the terminal's light/dark](docs/adr/0003-flexoki-theme-following-terminal.md)
- [ADR 0004 — smart-splits.nvim across Neovim and tmux](docs/adr/0004-smart-splits-for-panes.md)
- [ADR 0005 — WSL uses the Windows OpenSSH agent](docs/adr/0005-wsl-ssh-through-windows-agent.md)
- [ADR 0006 — Windows from the same repo](docs/adr/0006-windows-from-the-same-repo.md)
- [ADR 0007 — VS Code runs LazyVim through vscode-neovim](docs/adr/0007-vscode-runs-lazyvim.md)
- [ADR 0008 — Keep LazyVim, remove its Windows startup and lookup costs](docs/adr/0008-lazyvim-speed-on-windows.md)
- [ADR 0009 — MSVC from Visual Studio, not Build Tools](docs/adr/0009-msvc-from-visual-studio.md)
