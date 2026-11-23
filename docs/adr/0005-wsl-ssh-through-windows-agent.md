# 0005 — WSL uses the Windows OpenSSH agent

## Status
Accepted — 2026-11-23

## Context
On Windows machines the SSH keys live in the Windows OpenSSH agent and `~/.ssh`. WSL needs the same keys and host aliases without copying private keys into Linux. The setup runs on machines owned by different companies, so it can't hard-code paths: the Windows profile, user name, drive and npiperelay location vary.

## Decision
- A systemd user service (`ssh-agent-relay`) runs `socat` from `$XDG_RUNTIME_DIR/ssh-agent.sock` to `npiperelay.exe` and the agent's named pipe. `~/.bash_profile` exports `SSH_AUTH_SOCK` when the socket exists.
- `ssh-sync` copies `config`, `known_hosts` and `*.pub` from Windows' `~/.ssh` (CRLF stripped, removed keys deleted). A user timer runs it at login and every 5 minutes, because Windows-side edits under `/mnt/c` raise no inotify events.
- `chezmoi apply` resolves the Windows `~/.ssh` (`cmd.exe` + `wslpath`) and `npiperelay.exe` (`lookPath`) on each machine into `~/.config/environment.d/ssh-agent-relay.conf`; user services have no Windows `PATH`.
- Applied only on WSL (`wsl` in chezmoi data, from the kernel release).

## Consequences
- One relay per session instead of one per shell; it restarts on failure.
- Needs systemd in WSL (`[boot] systemd=true`), WSL interop, and npiperelay installed on Windows. If interop drops, the relay fails until it's back.
- A moved Windows profile or npiperelay needs `chezmoi apply` and a re-login.

## Alternatives
- **wsl2-ssh-agent** (mame): one Linux binary through mise, talks to the agent via `powershell.exe`, no socat or npiperelay. Third-party agent shim; still needs interop.
- **Per-shell relay** (as in `.dotconfigs`): no systemd needed, but a check-and-start in every shell, with races between shells.
- **chezmoi owns `~/.ssh/config`**: one config for both OSes in this repo, but Windows would have to read it from here.
