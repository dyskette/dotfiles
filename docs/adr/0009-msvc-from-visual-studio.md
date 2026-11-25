# 0009 — MSVC from Visual Studio, not Build Tools

## Status
Accepted — 2026-11-25. Supersedes the MSVC Build Tools part of ADR 0006.

## Context
ADR 0006 installed MSVC (rust's linker, tree-sitter's C compiler) as Visual Studio Build Tools 2026 with only the `VCTools` workload, separate from Visual Studio Enterprise 2026, so the native toolchain would not depend on the IDE.

That made two MSBuild 18 instances. winget installs the Build Tools from a newer build than the IDE's (18.12.12412 vs 18.12.12405), so they rank as the newest MSBuild. Their `SdkResolvers` folder has no `Microsoft.DotNet.MSBuildSdkResolver`. Tools that take the newest MSBuild therefore cannot evaluate SDK-style .NET projects:
- `nuget.exe restore` restored only the `packages.config` projects, skipped the SDK-style ones without an error, and the build then failed with NETSDK1004 (missing `obj\project.assets.json`).
- `vswhere -latest -products * -requires Microsoft.Component.MSBuild` returns the Build Tools, so build scripts using that query fail the same way.

The native side worked with either instance: rustc used the Build Tools' `link.exe`, and the Windows SDK is machine-wide. But the IDE already had the same MSVC toolset, so the two copies were redundant and would drift apart, since winget and the Visual Studio updater update them separately.

## Decision
- MSVC (`Microsoft.VisualStudio.Component.VC.Tools.x86.x64`) and the Windows 11 SDK (`Microsoft.VisualStudio.Component.Windows11SDK.26100`) are components of Visual Studio Enterprise 2026 in `.chezmoidata/visualstudio.toml`.
- `10-packages.ps1` no longer installs `Microsoft.VisualStudio.BuildTools`.
- Machines that already have the Build Tools from this repo uninstall them once by hand: `winget uninstall --id Microsoft.VisualStudio.BuildTools`. Nothing removes them automatically, because a company image may install the Build Tools for its own reasons.

## Consequences
- One MSBuild 18 and one MSVC per machine; `nuget.exe`, `vswhere -latest` scripts, rustc and tree-sitter all resolve to the IDE.
- rust and tree-sitter need Visual Studio Enterprise. Nothing compiles before `47-visualstudio` (mise tools are prebuilt; nvim-treesitter builds parsers in `60-nvim-plugins`), so the apply order still works on a blank machine.
- A machine without an Enterprise license would need the Build Tools again, with the .NET build tools workloads added so their MSBuild can resolve SDK-style projects.

## Alternatives
- **Keep the Build Tools, add `ManagedDesktopBuildTools` and `NetCoreBuildTools`:** restore works, but there are still two MSBuild 18 instances, and which one tools pick changes with every update.
- **Keep the Build Tools, pass `-MSBuildPath` to every `nuget.exe` call:** fixes only the calls you control; third-party build scripts still pick the newest instance.
