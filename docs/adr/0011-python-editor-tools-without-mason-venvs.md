# 0011 — Python editor tools without Mason's pip venvs

## Status
Accepted — 2026-11-26

## Context
Mason installs pip-based packages (basedpyright, debugpy) into their own venvs. A venv records the absolute path of the Python that was first on `PATH` at install time. When that Python goes away, the venv's launcher can't start: on Windows it prints `did not find executable at '…\python.exe'` and exits with code 103.

That happened on Windows: basedpyright's venv pointed at a python.org 3.14 that was later uninstalled, and Neovim showed `Client basedpyright quit with exit code 103`. Reinstalling only moves the problem. The new venv points at `mise\installs\python\3.13.18`, so the next 3.13 patch release breaks it again once mise removes the old version. Mason's basedpyright package also ships its own 99 MB unsigned `node.exe` (the `nodejs-wheel` dependency), one of the slowest binaries to start cold under Defender.

## Decision
- **basedpyright** comes from npm through mise (`"npm:basedpyright"` in `dot_config/mise/config.toml`) and runs on mise's node. lspconfig gets `mason = false` for it, so Mason neither installs nor enables its copy.
- **debugpy** runs as `uvx --from debugpy debugpy-adapter` (`dot_config/nvim/lua/plugins/python.lua`). uv keeps it in its cache on uv's own managed Python and recreates the environment when that interpreter changes. dap-python still picks the debugged program's interpreter (the project's `.venv`).
- mason-nvim-dap excludes the `python` adapter from automatic installation, so Mason's debugpy isn't reinstalled.
- On Windows, Neovim's `fast/shim.lua` also recognises the `.cmd` launchers that mise's npm backend writes, so basedpyright starts as `node langserver.index.js` without cmd.exe.

## Consequences
- Upgrading or removing a Python no longer breaks the language server or the debugger.
- Starting the debug adapter needs `uv` (a global mise tool). The first run downloads debugpy, which needs network access.
- basedpyright upgrades go through `mise upgrade` like the other CLIs, not `:MasonUpdate`.
- Neovim started without mise's PATH (VS Code, Explorer) reaches basedpyright through the mise shim, like every other mise tool.

## Alternatives
- **Build the venvs on mise's version-free junction (`python\3.13`):** keeps Mason, and the junction follows patch releases. It needs an override of how Mason creates venvs, still breaks on a minor-version change, and keeps Mason's bundled `node.exe`.
- **Reinstall Mason's Python packages from a chezmoi script when mise's Python changes:** simple, but it repairs after the fact, and only on machines that run `chezmoi apply`.
- **`uv run --with debugpy` (dap-python's built-in `uv` mode):** inside a uv project it syncs the project's environment before every debug session; `uvx` doesn't touch the project.
