# 0008 — Keep LazyVim, remove its Windows startup and lookup costs

## Status
Accepted — 2026-11-24

## Context
On Windows (Neovim 0.12, a 100-entry PATH, Defender on) LazyVim took ~430 ms to show a `.lua`
file and ~1.4 s for a `.ps1` file; Linux is fast. Measured causes:

- `executable()`/`exepath()` stat every PATH dir × every PATHEXT extension: 11–35 ms per miss.
  `vim.system` calls `exepath()` on every spawn; conform, nvim-lint and `vim.lsp` call them per
  formatter, linter and server. The runtime ps1 ftplugin calls `executable()` up to four times.
- Mason's tools are `.cmd` shims: every LSP server and formatter start goes through cmd.exe.
- `clipboard=unnamedplus` starts `win32yank.exe` for every yank and put.
- LSP, gitsigns, nvim-lint and todo-comments load on `LazyFile`, before the first screen.
- smart-splits activates with two blocking `tmux` calls (~100 ms under psmux).
- `options.lua` appended the mise shims to PATH with `:`, corrupting PATH's last entry on Windows.

A separate experiment (fast-lazyvim: vim.pack, own loader, own statusline) showed that lazy.nvim
and LazyVim themselves cost only ~10 ms at startup; the rest is the list above, which doesn't
depend on the distro.

## Decision
Keep LazyVim and add a Windows layer:

- `lua/fast/perf.lua`, loaded from `init.lua` before lazy.nvim, Windows only: drop duplicate and
  missing PATH dirs, PATHEXT `.COM;.EXE;.BAT;.CMD`, answer Lua's `executable()`/`exepath()` from
  an index of the PATH dirs built on a worker thread, and run Mason shims' target directly
  (`.exe`, or `node script.js` for npm shims).
- `lua/fast/clipboard.lua`: the Win32 clipboard API through LuaJIT FFI (win32yank as fallback).
- `ftplugin/ps1.lua`: the runtime ps1 settings without the startup `executable()` calls.
- `lua/plugins/perf.lua`: LSP, gitsigns, nvim-lint and todo-comments load on `VeryLazy` (after
  the first screen); blink.cmp loads while idle.
- smart-splits loads on its keys; `@pane-is-vim` is set by a non-blocking `tmux` call (amends
  ADR 0004).
- `:!` uses cmd.exe when Neovim inherited bash as `$SHELL` with cmd.exe's flags (Git Bash).
- gitsigns gets last session's `git --version` (cached in Neovim's state dir, refreshed in the
  background) through a `package.preload` hook: its `plugin/` file calls `setup()` before
  LazyVim's opts, so `_git_version` in opts comes too late.
- lualine and bufferline are replaced by `lua/fast/ui/statusline.lua` and `tabline.lua`: the
  same layout and keys, with each part cached per buffer and rebuilt only on the event that
  changes it. Per redraw: statusline ~80 µs vs lualine's 340–590 µs refresh, tabline ~7 µs vs
  bufferline's ~290 µs. noice stays.

## Consequences
- LazyVim updates, extras and `:Lazy` keep working; nothing patches LazyVim's modules.
- Vimscript callers still use the builtin `executable()` (faster with the shorter PATH/PATHEXT).
- `exepath()` returns lowercase paths on Windows (case-insensitive file system).
- A tool installed mid-session is found within 10 s (the index rebuilds on a stale miss).
- The first file shown at startup has no git signs, diagnostics or LSP for a few tens of
  milliseconds. Treesitter stays on `LazyFile`, so it is highlighted.
- If the shim format of Mason or npm changes, unknown shims run as before through cmd.exe.
- gitsigns still runs `setup()` twice (its `plugin/` file and LazyVim's config). The version
  hook depends on gitsigns' module layout; if it moves, gitsigns just runs `git --version` again.
- The statusline and tabline are ours to maintain: LazyVim's later additions to its lualine or
  bufferline config don't show up. Not ported: Trouble symbols in the statusline, lazy.nvim's
  update count and the profiler status.

## Alternatives
- **fast-lazyvim** (vim.pack, own loader, ui2 instead of noice): ~10–30 ms faster to start, but
  every LazyVim change has to be ported by hand.
- **Keep lualine and bufferline**: no UI code to maintain, at several hundred µs per cursor move.
- **Shorter user PATH and a Defender exclusion for nvim-data**: helps, needs admin rights and
  doesn't remove the per-call lookups or cmd.exe shims; complementary.
- **Patch LazyVim's `LazyFile` event or its util modules**: breaks on LazyVim updates.
