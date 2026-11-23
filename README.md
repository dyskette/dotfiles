# dotfiles — terminal-first LazyVim IDE (Stack A)

A [chezmoi](https://www.chezmoi.io/) source repo that turns a blank Linux machine into a terminal IDE for C#, Python, TypeScript, Rust and Go:

```
Ghostty → tmux (+ sesh: one session per repo/worktree) → bash + mise activate → nvim (LazyVim)
                                                                      ├─ LSP / DAP / neotest
lazygit (<leader>gg or prefix+g popup) ──── nv-edit ─────────────────┘
```

Each layer has one job and hands the next a predictable environment: Ghostty draws, tmux/sesh own sessions, mise owns runtimes and env vars, Neovim inherits them and starts language servers, debuggers and test runners.

## Who installs what

| Layer | Owner | Examples |
|---|---|---|
| System / GUI | OS package manager (`dnf`, `rpm-ostree`, `apt`, `pacman`) | ghostty, tmux, bash-completion, gcc, wl-clipboard |
| Runtimes, CLIs, Neovim | **mise** (`dot_config/mise/config.toml`, plus each repo's `mise.toml`) | node, python, uv, go, rust, dotnet, neovim, lazygit, sesh, lf, rg, fd, claude, copilot… |
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
| `after_26-bash-completions` | one completion file per command → `~/.local/share/bash-completion/completions` | `mise/config.toml` changes |
| `after_30-fonts` | JetBrainsMono Nerd Font → `~/.local/share/fonts` | font version bump |
| `after_35-bat-cache` | `bat cache --build` for the Flexoki themes (bat + delta) | bat config / externals change |
| `after_40-dotnet-tools` | EasyDotnet + roslyn-language-server | `mise/config.toml` changes |
| `after_50-tmux-plugins` | TPM + plugins | `tmux.conf` changes |
| `after_60-nvim-plugins` | headless `Lazy! restore`/`sync`, `TSUpdate` | `lazyvim.json` / `lazy-lock.json` change |
| `once_after_90-login-shell` | sets bash as login shell | once |

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

Repos under the project roots `~/Proyectos`, `~/Projects`, `~/source/repos` and `/c/s` are trusted automatically (`trusted_config_paths`), listed in the session picker (`~/.local/bin/projects`, git repos up to three levels deep) and get a sesh layout with three windows: `nv`, `test`, `git`. The roots are listed in three places — `dot_config/sesh/sesh.toml`, `dot_config/mise/config.toml` and `dot_local/bin/executable_projects` (or `PROJECT_ROOTS`) — keep them in sync.

## Theme: Flexoki light/dark

Ghostty is the only switch: it follows the OS light/dark setting and tells programs when it changes. tmux (≥ 3.6) reloads `flexoki-light.conf` / `flexoki-dark.conf` from its theme hooks and forwards the change to Neovim, which reloads its colorscheme. Tools that use the 16 ANSI colors (starship, eza, atuin, delta in the pager, difftastic, television) re-color instantly. bat and lazygit pick light or dark when they start. Details: [ADR 0003](docs/adr/0003-flexoki-theme-following-terminal.md).

To check it: switch the desktop theme with Ghostty open; the tmux status bar and Neovim should flip within a second.

## Daily keys

| Action | Key |
|---|---|
| Move between splits and panes / resize them | `M-h/j/k/l` / `M-H/J/K/L` (Alt, Alt-Shift) |
| Switch session or project / previous session | `prefix s` (or `tm` in a shell) / `prefix L` (prefix = `M-a`, i.e. Alt-a) |
| Open a session in any folder (lf: Enter on the folder; `q` cancels) | `prefix a` |
| Open a folder's session from a shell | `tm DIR` |
| Split pane / split whole window (full height, full width) | `prefix \|` `prefix -` / `prefix \` `prefix _` |
| Copy mode select char / line / block, copy | `v` / `V` / `C-v`, `y` or mouse drag |
| Git UI | `<leader>gg` (in Neovim), `prefix g` (popup) |
| Guided Conventional Commit (lazygit files panel) | `C` |
| Nearest test / debug nearest test | `<leader>tr` / `<leader>td` |
| Breakpoint / continue | `<leader>db` / `<leader>dc` |
| .NET: solution, build, run, debug, test runner | `<leader>N` + `s`/`b`/`r`/`d`/`t` |

### Shell

The pickers are [television](https://github.com/alexpasmantier/television) (`tv`) channels with its defaults, in rounded boxes like LazyVim's snacks.nvim pickers. The names follow LazyVim's leader keys: `f` find, `s` search, `g` git. The root is the git toplevel, else the cwd.

| Command | What it does |
|---|---|
| `ff [q]` / `fF [q]` | find files from the git root / the cwd, open in nvim (like `<leader>ff` / `<leader>fF`) |
| `sg [q]` / `sG [q]` | grep from the git root / the cwd (reads the tree once, then filters); one hit opens at its line, several go to the quickfix list (like `<leader>sg` / `<leader>sG`) |
| `gb` / `gl` | switch branch (`origin/x` switches to `x`) / browse the log (prints the picked hashes) |
| `e` / `gg` | lf / lazygit |
| `ee [path]` | open in the file manager: Nautilus, or Windows Explorer inside WSL |
| `ls` `ll` `la` `lt [level]` / `cat` | eza (icons, git, hyperlinks, tree) / bat; `man` pages render through bat |
| `Ctrl-T` | tv picks for the command typed: files after `nvim`, `cat`, `cp`…, folders after `cd`, repos after `git clone` (Ctrl-R stays atuin) |

Picker keys: `Tab` select, `C-j/C-k` move, `C-d/C-u` scroll list, `C-f/C-b` scroll preview, `A-p` toggle preview, `C-s` cycle sources, `C-h` help (tv defaults plus snacks-like scrolling in `~/.config/television/config.toml`).

In the session picker (`prefix s`, `tm`, `~/.config/television/cable/sesh.toml`): `C-s` cycles All / Projects / Tmux / Zoxide, `C-d` kills the highlighted session.

Tab completion covers the mise-managed CLIs (generated into `~/.local/share/bash-completion/completions` whenever the mise config changes, loaded on the first Tab after each command); git, tmux, ssh and the rest come from the `bash-completion` package. After `mise up` with `"latest"` pins, refresh them with `chezmoi state delete-bucket --bucket=scriptState && chezmoi apply`.

`sg` hides shadow-utils' `/usr/bin/sg` in interactive shells only. Plain `rg` reads `~/.config/ripgrep/config`, which has snacks' grep defaults.

## Environment variables

| Variable | Set by | Purpose |
|---|---|---|
| `XDG_CONFIG_HOME` | `~/.bash_profile` | lazygit and others read `~/.config` |
| `EDITOR`, `VISUAL` | `~/.bash_profile` | `nvim` |
| `PATH` | `~/.bash_profile` (and mise shims), `~/.bashrc` (`mise activate`) | `~/.local/bin`, `~/.dotnet/tools`, mise |
| `DOTNET_ROOT`, `DOTNET_MULTILEVEL_LOOKUP` | mise (dotnet backend) | global dotnet tools find the mise SDK |
| `NVIM` | Neovim `:terminal` | used by the `<leader>gg` lazygit edit commands |
| `RIPGREP_CONFIG_PATH` | `~/.bash_profile` | `~/.config/ripgrep/config`: snacks grep defaults |
| `DISABLE_AUTOUPDATER`, `COPILOT_AUTO_UPDATE` | mise `[env]` | Claude Code and Copilot CLI don't self-update; mise owns them (`mise up`) |
| `GHOSTTY_RESOURCES_DIR` | Ghostty (inherited by the tmux server) | `~/.bashrc` sources Ghostty's bash integration from it, also inside tmux |
| `PROJECT_ROOTS`, `PROJECT_DEPTH` | optional | override the roots and depth `projects` scans |

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

**Testing on fresh machines:** before merging changes to `.chezmoiscripts/`, `install.sh`, the mise toolchain or the theme, run the container tests in [docs/testing.md](docs/testing.md) (Fedora and Ubuntu with podman, including the light/dark theme checks).

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
| tmux bindings can't find `sesh`/`tv` | start tmux from a login bash (Ghostty's `command` does this); `tmux kill-server` and reopen |
| tmux or Neovim stays dark after switching to light | needs tmux ≥ 3.6 (`tmux -V`) and a terminal that reports theme changes (Ghostty does); `prefix r` re-sources the config |

## Layout

```
.chezmoi.toml.tmpl        machine data (name, email, work)
.chezmoiexternal.toml     Flexoki bat themes, lf icons, eza/lf bash completions (pinned commits)
.chezmoiignore            repo-only files
.chezmoiscripts/          bootstrap steps (see table above)
dot_bash_profile, dot_bashrc, dot_gitconfig.tmpl
dot_local/bin/            nv, nv-edit, projects, sesh-dir, tm, ee
dot_config/               ghostty, tmux, sesh, mise, lazygit, git, bat, television, ripgrep, lf, atuin, starship, nvim
project-template/         per-repo files (not applied to $HOME)
docs/adr/                 architecture decisions
docs/testing.md           container test runbook
install.sh                bootstrap entrypoint
```

## Decisions

- [ADR 0001 — chezmoi + single-owner toolchain](docs/adr/0001-chezmoi-and-tool-ownership.md)
- [ADR 0002 — easy-dotnet.nvim for C#](docs/adr/0002-easy-dotnet-for-csharp.md)
- [ADR 0003 — Flexoki, following the terminal's light/dark](docs/adr/0003-flexoki-theme-following-terminal.md)
- [ADR 0004 — smart-splits.nvim for moving and resizing across Neovim and tmux](docs/adr/0004-smart-splits-for-panes.md)
