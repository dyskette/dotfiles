# 0003 — Flexoki everywhere, following the terminal's light/dark

## Status
Accepted — 2026-11-21
Amended — 2026-11-22: fzf and yazi removed (television and lf replace them).

## Context
The stack used Catppuccin (Latte/Mocha) in Ghostty, tmux, Neovim, lazygit and bat/delta. Several tools hard-coded the Mocha (dark) variant, so switching the desktop to light mode left most of the stack dark. We want [Flexoki](https://stephango.com/flexoki) instead, in light and dark, switching with the OS without restarting anything that can avoid it.

What the tools support (researched in `.research/`, November 2026):
- **Ghostty 1.4** ships `Flexoki Light` and `Flexoki Dark`, matching the spec (600 accents on light, 400 on dark). It switches themes with the OS and reports changes to programs through DEC mode 2031.
- **tmux ≥ 3.6** has `client-light-theme` / `client-dark-theme` hooks and forwards theme changes to panes. Ubuntu 26.04 ships 3.6 and Fedora 45 ships 3.8. The 3.8-only `theme` option and `theme*` colors are not usable on Ubuntu yet.
- **Neovim 0.12** enables mode 2031, re-queries the background (OSC 11) on a change and updates `'background'`. Changing `'background'` reloads a colorscheme that follows it.
- **Most CLIs** (starship, eza, atuin, television's default theme, difftastic) only use the 16 ANSI colors, so Ghostty's palette re-colors them live with no configuration.
- **The official tmux port** swaps the accent shades (600 on dark, 400 on light) and hard-code colors, so they cannot switch.
- **No standalone Flexoki `.tmTheme`** exists for bat/delta. The Sublime port uses `.sublime-color-scheme`, which bat cannot read. The Yazi flavors by @gosxrgxx include one (MIT, © Steph Ango) that follows the Flexoki syntax mapping.

## Decision
Ghostty is the single switch. Each layer either uses ANSI colors (follows live) or is told about the change.

| Tool | Mechanism |
|---|---|
| Ghostty | `theme = light:Flexoki Light,dark:Flexoki Dark` |
| tmux | Our own `flexoki-{light,dark}.conf` (spec-correct accents), sourced by the theme hooks and on `client-attached`; the catppuccin plugin is removed |
| Neovim | `nuvic/flexoki-nvim` with `variant = "auto"` |
| lazygit | ANSI color names in `gui.theme`; delta renderer gets `--features flexoki-{{colorScheme}}` |
| bat | `--theme-light` / `--theme-dark` with the Flexoki `.tmTheme` files (chezmoi externals, pinned to commits) |
| delta (git pager) | `base16` syntax theme, i.e. the terminal's ANSI palette, set through a feature so lazygit's `--features` can replace it |

ANSI 0 and 15 are identical in both Ghostty Flexoki palettes, so the ANSI-based configs avoid them.

## Consequences
- tmux, Neovim and every ANSI-based tool switch live. bat, delta in lazygit and lazygit itself pick the mode when they start.
- The tmux theme is server-wide: two clients on terminals in different modes share one status bar (the last report wins).
- Terminals without mode 2031 never report a change; tmux then stays on its dark default.
- nuvic's port is a rose-pine fork and kept rose-pine's dark `surface` (`#1f1d2e`, a violet) for every floating window. `plugins/colorscheme.lua` overrides `surface` with Flexoki `bg-2` in both variants; re-check for leftovers when updating the plugin.
- Three third-party sources are now trusted: nuvic/flexoki-nvim (via lazy.nvim, follows its default branch) and the two Yazi flavor repos (pinned by commit in `.chezmoiexternal.toml`).
- Upgrading to tmux 3.8 everywhere would allow replacing the hook-loaded files with the built-in `light-theme-*` / `dark-theme-*` options.

## Alternatives
- **kepano/flexoki-neovim** (official): exact spec values, but it themes far fewer of the plugins this setup uses (no DAP UI, neotest, LSP semantic tokens, trouble or render-markdown groups). Switch by changing `plugins/colorscheme.lua`; both use the colorscheme name `flexoki`.
- **ANSI-only tmux status bar:** no theme files or hooks, but no Flexoki background shades (`bg-2`, `ui`), so the status bar and borders look flat.
- **Official tmux port:** ready-made, but swapped accents and no switching.
- **Stay on Catppuccin:** it already had both variants, but several tools were pinned to dark.
