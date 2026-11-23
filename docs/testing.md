# Testing in containers

Checks that `install.sh` turns a blank Fedora or Ubuntu machine into a working setup, with rootless podman. Arch, Fedora Atomic and a real Ghostty window are checked by hand.

Each installed container takes about **7 GB**; check `df -h /var` first. Don't `podman commit` installed containers: it needs as much space again.

```sh
T=$(mktemp -d)                       # Containerfiles, logs, helpers
REPO=$PWD                            # the repo root
```

## 1. Images

A fresh distro with `sudo` and a passwordless-sudo user `tester`, plus sshd to log in by hand (localhost only, throwaway password).

```sh
cat > "$T/Containerfile" <<'EOF'
ARG BASE
FROM ${BASE}
RUN if command -v dnf >/dev/null; then dnf install -y sudo openssh-server && dnf clean all; \
    else apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y sudo openssh-server && rm -rf /var/lib/apt/lists/*; fi \
 && useradd -m -s /bin/bash tester \
 && echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester \
 && mkdir -p /run/sshd && ssh-keygen -A && echo 'tester:tester' | chpasswd
CMD ["/bin/sh", "-c", "mkdir -p /run/sshd && exec /usr/sbin/sshd -D -e"]
EOF
podman build --build-arg BASE=registry.fedoraproject.org/fedora:latest -t dotfiles-test-fedora -f "$T/Containerfile" "$T"
podman build --build-arg BASE=docker.io/library/ubuntu:latest -t dotfiles-test-ubuntu -f "$T/Containerfile" "$T"
```

## 2. Install

`--init` reaps orphaned processes; without it a container can hang in "Stopping".

```sh
D=fedora PORT=2222                   # or: D=ubuntu PORT=2223
C=dotfiles-$D
podman run -d --init --name "$C" -p 127.0.0.1:$PORT:22 -v "$REPO":/src:ro,Z dotfiles-test-$D

podman exec -u tester -w /home/tester "$C" bash -c '
  mkdir -p ~/.local/share ~/.config/chezmoi
  cp -a /src ~/.local/share/chezmoi
  printf "[data]\n  name = \"Test User\"\n  email = \"test@example.com\"\n" \
    > ~/.config/chezmoi/chezmoi.toml'
podman exec -u tester -w /home/tester "$C" ~/.local/share/chezmoi/install.sh \
  </dev/null >"$T/$D.log" 2>&1; echo "exit=$?" >>"$T/$D.log"
```

About 10 minutes. Expected noise: `sysctl: permission denied`, `Failed to connect to audit log`, `unknown variable: TMUX_PLUGIN_MANAGER_PATH`.

## 3. Verify

```sh
x() { podman exec -u tester -e TERM=xterm-256color -e COLORTERM=truecolor "$C" bash -lic "$1" 2>/dev/null; }
```

| Check | Command | Expect |
|---|---|---|
| Install finished | `tail -1 "$T/$D.log"`; `grep -c '^chezmoi:' "$T/$D.log"` | `exit=0`; `0` |
| Login shell | `x 'getent passwd tester \| cut -d: -f7'` | `/usr/bin/bash` |
| Runtimes from mise | `x 'which node python go nvim dotnet claude'` | under `~/.local/share/mise/` |
| .NET tools | `x 'dotnet tool list -g'` | `easydotnet`, `roslyn-language-server` |
| mise | `x 'mise doctor \| grep "problems found"'` | `No problems found` |
| Neovim plugins | `x 'nvim --headless "+lua print(#require(\"lazy\").plugins())" +qa'` | a count, no errors |
| bat themes | `x 'bat --list-themes --color=never \| grep Flexoki'` | `Flexoki Dark`, `Flexoki Light` |
| Completions | `x '_comp_load git && complete -p git'` | `-F __git_wrap__git_main` |

```sh
x 'miss=""; for t in nvim node python go dotnet cargo rust-analyzer lazygit rg fd bat eza \
   zoxide delta difft sg tv atuin starship lefthook gotestsum sesh gh tree-sitter jq yq \
   poetry lf java claude copilot opencode terraform az func aspire tmux ghostty projects sesh-dir tm ee nv nv-edit; do
   command -v $t >/dev/null || miss="$miss $t"; done; echo "missing:${miss:- none}"'
```

## 4. Theme

The helper attaches tmux in a pty and plays Ghostty: it answers background queries (`ESC]11;?`) and sends theme reports (`ESC[?997;2n` light, `ESC[?997;1n` dark). With `--nvim` it logs Neovim's `background` changes.

```sh
cat > "$T/theme2031.py" <<'EOF'
import os, pty, select, subprocess, sys, time
BG = {"dark": b"rgb:1010/0f0f/0f0f", "light": b"rgb:ffff/fcfc/f0f0"}
LOG = "/tmp/nvim-bg.log"
mode = "dark"
cmd = ["tmux", "-L", "t", "-f", os.path.expanduser("~/.config/tmux/tmux.conf"), "new-session", "-s", "t"]
if "--nvim" in sys.argv:
    if os.path.exists(LOG): os.remove(LOG)
    cmd += ["nvim", "-c", f'au OptionSet background call writefile([v:option_new], "{LOG}", "a")']
pid, fd = pty.fork()
if pid == 0:
    os.environ["TERM"] = "xterm-256color"; os.execvp("tmux", cmd)
def pump(seconds):
    end = time.time() + seconds
    while time.time() < end:
        if select.select([fd], [], [], 0.1)[0]:
            try: data = os.read(fd, 65536)
            except OSError: return
            if b"\x1b]11;?" in data:
                os.write(fd, b"\x1b]11;" + BG[mode] + b"\x1b\\")
def style():
    return subprocess.run(["tmux", "-L", "t", "show", "-gv", "status-style"], capture_output=True, text=True).stdout.strip()
pump(4)
for mode, code in (("light", b"2"), ("dark", b"1")):
    os.write(fd, b"\x1b[?997;" + code + b"n"); pump(3)
    nv = open(LOG).read().split() if os.path.exists(LOG) else "-"
    print(f"after {mode:<5}: tmux status-style={style()}  nvim background log={nv}")
subprocess.run(["tmux", "-L", "t", "kill-server"])
EOF
podman cp "$T/theme2031.py" "$C":/tmp/theme2031.py
x 'python3 -I /tmp/theme2031.py --nvim'
```

| After | tmux `status-style` | Neovim log |
|---|---|---|
| light | `bg=#f2f0e5,fg=#6f6e69` | `['light']` |
| dark | `bg=#1c1b1a,fg=#878580` | `['light', 'dark']` |

delta: in a repo with a change, `delta --show-config | grep syntax-theme` shows `Base16`, and `delta --features flexoki-light --light --show-config` shows `Flexoki Light`.

## 5. Re-test after a change

```sh
tar -C "$REPO" --exclude=./.research --exclude=./.git -cf - . |
  podman exec -i -u tester "$C" bash -c 'cd ~/.local/share/chezmoi && tar -xf -'
x 'chezmoi apply --force'            # no TTY to confirm LazyVim's rewritten lazyvim.json
```

Before merging, run the full install from a fresh container once. To log in: `ssh -p 2222 tester@127.0.0.1` (password `tester`).

## 6. Clean up

```sh
podman rm -f -t 0 dotfiles-fedora dotfiles-ubuntu
podman rmi dotfiles-test-fedora dotfiles-test-ubuntu
rm -rf "$T"
```
