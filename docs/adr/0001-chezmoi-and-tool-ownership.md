# 0001 — chezmoi for dotfiles, one owner per tool

## Status
Accepted — 2026-11-21

## Context
A blank Linux machine needs a terminal IDE for five languages. The same binary (e.g. `ruff`, `node`) can come from the OS, mise, Mason or `dotnet tool`. When two of them install it, whichever is first on `PATH` wins without warning. That breaks per-project version pins. The setup also has to work across Fedora (including Atomic), Debian/Ubuntu and Arch, and must keep secrets out of git.

## Decision
- Manage dotfiles with **chezmoi**: templates for machine data, `run_onchange_` scripts for idempotent installs, password-manager integration for any future secrets.
- Each binary has exactly one owner:
  - OS packages: system and GUI pieces.
  - mise: runtimes, CLIs and Neovim itself. On Windows, .NET instead comes from Microsoft's machine-wide install (winget and Visual Studio): Visual Studio puts its SDKs there regardless, and that `dotnet` comes first on `PATH` outside mise's shells, while the `dotnet` launcher already picks the SDK from `global.json`.
  - Mason: editor-only servers and adapters, except pip-based ones, whose venvs break when their Python changes: basedpyright comes from mise (npm) and debugpy from `uvx` ([ADR 0011](0011-python-editor-tools-without-mason-venvs.md)).
  - `dotnet tool`: .NET editor tooling.
  - rustup: rust-analyzer.
- Mason's bin dir is **appended** to `PATH` so repo-pinned (mise) tools win inside Neovim.
- One Neovim per sesh session, started in the repo root, so it inherits the mise environment.

## Consequences
- Bootstrap is `install.sh` → `chezmoi init --apply`; scripts re-run only when their inputs change.
- Tool upgrades are mostly one-line edits in `dot_config/mise/config.toml`.
- Fedora Atomic needs a reboot between package layering and the rest of the setup.
- Ghostty is not in Debian/Ubuntu repos, so on those distros it has to be installed by hand.

## Alternatives
- **GNU stow:** simpler (only symlinks). It has no templating or per-OS logic, so the install steps would have to live in a separate script.
- **yadm:** a git wrapper with alternates and encryption. It sits between stow and chezmoi in features, but its install hooks are less structured.
- **Mason for everything:** fewer moving parts, but no per-project versions and nothing shared with CI.
