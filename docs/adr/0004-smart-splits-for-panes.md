# 0004 — smart-splits.nvim for moving and resizing across Neovim and tmux

## Status
Accepted — 2026-11-22

## Context
`M-h/j/k/l` moves between Neovim splits and tmux panes as if they were one layout (vim-tmux-navigator). We also want `M-H/J/K/L` (Alt-Shift) to resize them the same way: a Neovim split when Neovim has one in that direction, otherwise the tmux pane. vim-tmux-navigator only moves.

## Decision
Use smart-splits.nvim (`^3.0.0`) with smart-splits-nvim/backend-tmux, which marks Neovim's pane in tmux (`@pane-is-vim`), pinned to a commit until it tags a release, and loaded at startup (`lazy = false`). The tmux side is the backend README's "by hand" bindings in `tmux.conf`, not its TPM plugin, because TPM can't pin a commit. `move.at_edge = 'wrap'` on both sides.

## Consequences
- One plugin and one set of keys for moving and resizing, in both directions across the Neovim/tmux boundary.
- tmux decides from a pane option instead of a `ps` call per keypress.
- smart-splits loads at startup. Until it has loaded, tmux keeps `M-h/j/k/l` for itself.
- Normal-mode `M-j`/`M-k` no longer move lines (LazyVim). Insert and visual mode still do.
- The backend is young: we update its pinned commit by hand. If it stalls, switch to tmux.nvim (same keys, `ps` detection), which needs only `navigation.lua` and the tmux bindings rewritten.
- A Neovim reached over ssh can't mark the remote pane in the local tmux. That was also true of the `ps` check.

## Alternatives
- **aserowy/tmux.nvim:** move, resize and swap, `ps`-based detection, lazy loadable, maintained; its register/clipboard sync would have to be turned off. The fallback.
- **vim-tmux-navigator + better-vim-tmux-resizer:** smallest change, but the resizer was last updated in 2021.
- **Navigator.nvim, nvim-tmux-navigation:** movement only.
- **tmux-only `resize-pane` bindings:** Neovim's splits couldn't be resized with the same keys.
