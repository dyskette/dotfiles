# 0007 — VS Code runs LazyVim through vscode-neovim

## Status
Accepted — 2026-11-23

## Context
VS Code used VSCodeVim with ~380 lines of JSON keymaps and ~250 lines of keybindings, with keys that differed from LazyVim (`<leader>ff` formatted, `<leader>d*` jumped diagnostics) and plugins (magit, oil) that LazyVim doesn't use. The goal is the same keys and editing behaviour as Neovim, maintained once.

## Decision
- **vscode-neovim** runs the real `~/.config/nvim`. LazyVim adds its `vscode` extra by itself when `vim.g.vscode` is set: only editing plugins load (mini.*, flash, treesitter text objects, snacks core); terminal Neovim is unaffected.
- `plugins/vscode.lua` maps the LazyVim keys whose Neovim versions open UI or need an LSP (pickers, explorer, lazygit, LSP, hunks, buffers/windows, DAP, tests) to VS Code commands, in the `LazyVimKeymapsDefaults` event so they win over core keymaps and plugin keys. It also routes `y`/`p` through VS Code's clipboard.
- `keybindings.json` keeps only VS Code-side keys: Alt-hjkl/HJKL across editors and panels, `<C-/>` terminal, `C-n/C-p/C-y` in menus, snacks-style explorer keys.
- Extensions follow the LazyVim lang extras (basedpyright, ruff, Go, rust-analyzer, C# (Roslyn), YAML); `nvim` comes from mise's shims (Windows user PATH; a per-user Flatpak PATH override on Linux).

## Consequences
- Insert mode, completion, snippets, scrolling and line numbers are VS Code's; undo, jumplist and dot-repeat behave like VS Code's.
- No which-key popup (which-key doesn't load in VS Code).
- One Neovim per VS Code window (~0.8 s to start in the test container).
- VSCodeVim must be uninstalled by hand: vscode-neovim won't start next to it.
- Verified headless with a stubbed `vscode` module (keys and clipboard); not yet in a real VS Code window.

## Alternatives
- **VSCodeVim remapped to LazyVim's keys + VSpaceCode.whichkey:** a which-key menu, but keymaps as JSON separate from the Lua config, and no mini.ai/flash/surround.
- **A `host-spawn` wrapper for nvim in the Flatpak:** works (tested over RPC), but covers only nvim, not the language extensions' tools.
