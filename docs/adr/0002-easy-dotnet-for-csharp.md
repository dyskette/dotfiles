# 0002 — easy-dotnet.nvim for C#

## Status
Accepted — 2026-11-21

## Context
LazyVim's `lang.dotnet` extra (v16.0.2) still uses OmniSharp + omnisharp-extended, `neotest-vstest` and Mason's `netcoredbg`. Issue #6918, about moving it to Roslyn, was closed as *not planned*. `neotest-vstest` also breaks when the cwd is not the solution folder. The Roslyn language server is the maintained path.

## Decision
Leave `lang.dotnet` disabled and use **easy-dotnet.nvim**. It provides:
- a built-in Roslyn client (`lsp.enabled = true`);
- a bundled debugger (`netcoredbg`, switchable to `dncdbg` or `sharpdbg`);
- a neotest adapter (`easy-dotnet.neotest` with `test_runner.neotest_integration = true`).

Explicitly disable OmniSharp in nvim-lspconfig. Keys live under `<leader>N`, because LazyVim already uses `<leader>n` for notification history.

## Consequences
- Requires the `EasyDotnet` and `roslyn-language-server` global tools; they are installed by `.chezmoiscripts`.
- Every Neovim, and so every worktree session, runs its own Roslyn server. Expect high memory use with many worktrees open.
- If `omnisharp` is ever installed through Mason, mason-lspconfig may auto-enable it. Remove it with `:MasonUninstall omnisharp`.

## Alternatives
- **seblyng/roslyn.nvim:** finer control over which solution to load in monorepos with many `.sln` files (`lock_target`, `choose_target`), and a daemon mode shared across Neovim instances. If it is used, set easy-dotnet's `lsp.enabled = false` so only one Roslyn client runs.
- **LazyVim `lang.dotnet` extra:** no extra configuration, but it uses OmniSharp, which is slower and has less complete language features.
