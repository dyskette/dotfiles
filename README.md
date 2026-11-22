# dotfiles — terminal-first LazyVim IDE (Stack A)

A [chezmoi](https://www.chezmoi.io/) source repo that turns a blank Linux machine into a terminal IDE for C#, Python, TypeScript, Rust and Go:

```
Ghostty → tmux (+ sesh: one session per repo/worktree) → zsh + mise activate → nvim (LazyVim)
                                                                     ├─ LSP / DAP / neotest
lazygit (<leader>gg or prefix+g popup) ──── nv-edit ────────────────┘
```

Each layer has one job and hands the next a predictable environment: Ghostty draws, tmux/sesh own sessions, mise owns runtimes and env vars, Neovim inherits them and starts language servers, debuggers and test runners.

## Who installs what

| Layer | Owner | Examples |
|---|---|---|
| System / GUI | OS package manager (`dnf`, `rpm-ostree`, `apt`, `pacman`) | ghostty, tmux, zsh, gcc, wl-clipboard |
| Runtimes, CLIs, Neovim | **mise** (`dot_config/mise/config.toml`, plus each repo's `mise.toml`) | node, python, uv, go, rust, dotnet, neovim, lazygit, sesh, rg, fd… |
| Editor-only servers / debug adapters | **Mason** (via LazyVim extras) | basedpyright, vtsls, gopls, codelldb, js-debug-adapter, delve, debugpy, csharpier |
| .NET editor tooling | `dotnet tool install -g` | EasyDotnet, roslyn-language-server |
| rust-analyzer | `rustup component add` | — |
| Fonts | `.chezmoiscripts` (nerd-fonts release) | JetBrainsMono Nerd Font |

A binary comes from exactly one owner. Mason's bin dir is **appended** to `PATH` inside Neovim, so a tool pinned in a repo's `mise.toml` always wins.

## Setup (blank machine)

Supported: Fedora (dnf), Fedora Atomic (rpm-ostree), Debian/Ubuntu (apt), Arch (pacman).

```sh
git clone <this-repo-url> ~/.local/share/chezmoi
~/.local/share/chezmoi/install.sh
```

`install.sh` installs curl/git if missing, installs mise into `~/.local/bin`, installs chezmoi through mise, and runs `chezmoi init --apply`. chezmoi asks for your git name/email and whether this is a work machine, writes the files, and runs these scripts in order:

| Script | What it does | Re-runs when |
|---|---|---|
| `before_10-packages` | OS packages, Ghostty (COPR on Fedora), inotify limits | the script changes |
| `after_20-mise-install` | `mise install` for all global tools; rust-analyzer via rustup | `mise/config.toml` changes |
| `after_30-fonts` | JetBrainsMono Nerd Font → `~/.local/share/fonts` | font version bump |
| `after_35-bat-cache` | `bat cache --build` for the Flexoki themes (bat + delta) | bat config / externals change |
| `after_40-dotnet-tools` | EasyDotnet + roslyn-language-server | `mise/config.toml` changes |
| `after_50-tmux-plugins` | TPM + plugins | `tmux.conf` changes |
| `after_60-nvim-plugins` | headless `Lazy! restore`/`sync`, `TSUpdate` | `lazyvim.json` / `lazy-lock.json` change |
| `once_after_90-login-shell` | sets zsh as login shell | once |

**Fedora Atomic:** packages are layered with `rpm-ostree`. Reboot when asked, then run `chezmoi apply` again.

Then log out and back in, open Ghostty (it attaches to tmux session `main`), start `nvim` once so Mason installs servers, and run `:checkhealth`.

### Verify

```sh
mise doctor
nvim -c ':!which node python go dotnet'   # all should point into ~/.local/share/mise/installs/...
```

### After the first run

Commit the generated plugin lockfile so other machines restore the same commits:

```sh
chezmoi re-add ~/.config/nvim/lazy-lock.json
chezmoi cd && git add dot_config/nvim/lazy-lock.json && git commit -m "chore(nvim): pin plugin versions"
```

## Per-project setup

`project-template/` is **not** copied to `$HOME`. Copy what you need into a repo:

| File | Purpose |
|---|---|
| `mise.toml` | runtimes, `[env]` (python venv), tasks: `test`, `test:watch`, `lint`, `build`, `hooks:install` |
| `lefthook.yml` | commit-msg: commitlint + reject `Co-authored-by`; pre-commit: `mise run lint` |
| `commitlint.config.js` | Conventional Commits with the org's types only |
| `.github/workflows/commitlint.yml` | the same check in CI, so `--no-verify` cannot skip it |
| `.vscode/launch.json` | shared nvim-dap launch configs |

```sh
mise trust && mise install && mise run hooks:install
```

Repos under `~/code` are trusted automatically (`trusted_config_paths`) and get a sesh layout with three windows: `nv`, `test`, `git`.

## Theme: Flexoki light/dark

Ghostty is the only switch: it follows the OS light/dark setting and tells programs when it changes. tmux (≥ 3.6) reloads `flexoki-light.conf` / `flexoki-dark.conf` from its theme hooks and forwards the change to Neovim, which reloads its colorscheme. Tools that use the 16 ANSI colors (starship, eza, atuin, fzf, delta in the pager, difftastic, television) re-color instantly. bat, lazygit and yazi pick light or dark when they start. Details: [ADR 0003](docs/adr/0003-flexoki-theme-following-terminal.md).

To check it: switch the desktop theme with Ghostty open; the tmux status bar and Neovim should flip within a second.

## Daily keys

| Action | Key |
|---|---|
| Move between splits and panes | `C-h/j/k/l` |
| Switch project / previous project | `prefix T` / `prefix L` (prefix = `C-Space`) |
| Git UI | `<leader>gg` (in Neovim), `prefix g` (popup) |
| Guided Conventional Commit (lazygit files panel) | `C` |
| Nearest test / debug nearest test | `<leader>tr` / `<leader>td` |
| Breakpoint / continue | `<leader>db` / `<leader>dc` |
| .NET: solution, build, run, debug, test runner | `<leader>N` + `s`/`b`/`r`/`d`/`t` |

## Environment variables

| Variable | Set by | Purpose |
|---|---|---|
| `XDG_CONFIG_HOME` | `~/.zshenv` | lazygit and others read `~/.config` |
| `EDITOR`, `VISUAL` | `~/.zshenv` | `nvim` |
| `PATH` | `~/.zshenv`, `~/.zprofile` (shims), `~/.zshrc` (`mise activate`) | `~/.local/bin`, `~/.dotnet/tools`, mise |
| `DOTNET_ROOT`, `DOTNET_MULTILEVEL_LOOKUP` | mise (dotnet backend) | global dotnet tools find the mise SDK |
| `NVIM` | Neovim `:terminal` | used by the `<leader>gg` lazygit edit commands |
| `FZF_DEFAULT_OPTS` | `~/.zshenv` | Flexoki colors via the ANSI palette (also reaches the tmux server) |

No secrets live in this repo. Put per-repo secrets in `mise.local.toml` (git-ignored), generated from your vault; for dotfiles secrets use chezmoi's password-manager template functions.

## Runbook

**Monthly update (on a branch):**
1. `mise upgrade --bump` (or edit `dot_config/mise/config.toml`).
2. In Neovim: `:Lazy update`, `:MasonUpdate`, `:checkhealth`.
3. `dotnet tool update -g EasyDotnet && dotnet tool update -g roslyn-language-server --prerelease`.
4. Run one test per language in a sample polyglot repo (`<leader>tr`).
5. `chezmoi re-add ~/.config/nvim/lazy-lock.json`, commit `chore(deps): …`.

Read the LazyVim CHANGELOG and easy-dotnet `news.md` before updating.

**Rollback:** `git revert` the update commit, `chezmoi apply`, then `:Lazy restore` in Neovim.

**Troubleshooting:**

| Symptom | Fix |
|---|---|
| `xterm-ghostty: unknown terminal` over SSH | the `ssh` alias uses `ghostty +ssh`; otherwise `infocmp -x xterm-ghostty \| ssh host -- tic -x -` |
| Two C# servers / duplicate diagnostics | `:MasonUninstall omnisharp`; keep `lang.dotnet` extra disabled |
| Wrong solution picked by Roslyn | `dotnet restore`, open at solution root, `<leader>Ns` |
| Mason binary shadows a mise pin | `:!which ruff` — Mason PATH is appended, so check the repo's `mise.toml` |
| "No version is set" inside Neovim | `mise trust` in the repo; check `~/.local/state/mise/ignored-configs/` |
| neotest-golang finds no tests | `:TSUpdate go` (LazyVim uses nvim-treesitter `main`) |
| Roslyn/LSP stops watching files | inotify limits live in `/etc/sysctl.d/90-dev-inotify.conf` |
| tmux bindings can't find `sesh`/`fzf` | start tmux from a login zsh (Ghostty's `command` does this); `tmux kill-server` and reopen |
| tmux or Neovim stays dark after switching to light | needs tmux ≥ 3.6 (`tmux -V`) and a terminal that reports theme changes (Ghostty does); `prefix r` re-sources the config |

## Layout

```
.chezmoi.toml.tmpl        machine data (name, email, work)
.chezmoiexternal.toml     Flexoki bat themes and yazi flavors (pinned commits)
.chezmoiremove            leftovers to delete from $HOME
.chezmoiignore            repo-only files
.chezmoiscripts/          bootstrap steps (see table above)
dot_zshenv, dot_zprofile, dot_zshrc, dot_gitconfig.tmpl
dot_local/bin/            nv, nv-edit
dot_config/               ghostty, tmux, sesh, mise, lazygit, git, bat, yazi, atuin, starship, nvim
project-template/         per-repo files (not applied to $HOME)
docs/adr/                 architecture decisions
install.sh                bootstrap entrypoint
```

## Decisions

- [ADR 0001 — chezmoi + single-owner toolchain](docs/adr/0001-chezmoi-and-tool-ownership.md)
- [ADR 0002 — easy-dotnet.nvim for C#](docs/adr/0002-easy-dotnet-for-csharp.md)
- [ADR 0003 — Flexoki, following the terminal's light/dark](docs/adr/0003-flexoki-theme-following-terminal.md)
