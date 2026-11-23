# Testing in containers

How to check that `install.sh` turns a blank machine into a working setup, using rootless podman containers for Fedora and Ubuntu. Run it before merging changes to `.chezmoiscripts/`, `install.sh`, the mise toolchain or the theme files.

This doesn't cover Arch, Fedora Atomic (needs a reboot), or how things actually look in a real Ghostty window. Check those by hand.

## Before you start

- **Disk:** each installed environment takes about **7 GB**. Run `df -h /var` first. If there's room for only one, test one distro at a time and remove its container before building the next.
- **Don't snapshot installed containers** with `podman commit`: it needs as much free space again, and when it ran out of space here, the commands chained after it deleted the containers. Bake ports and sshd into the image before installing instead.
- **Work outside the repo.** Put Containerfiles, logs and helper scripts in a scratch directory (`$T` below). The repo is mounted read-only.

```sh
T=$(mktemp -d)                       # scratch: Containerfiles, logs, helpers
REPO=$PWD                            # run from the repo root
```

## 1. Images

The base image is a fresh distro with only `sudo` and a user `tester` with passwordless sudo, like a new machine.

```sh
cat > "$T/Containerfile.fedora" <<'EOF'
FROM registry.fedoraproject.org/fedora:latest
RUN dnf install -y sudo && dnf clean all \
 && useradd -m -s /bin/bash tester \
 && echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester
USER tester
WORKDIR /home/tester
EOF

cat > "$T/Containerfile.ubuntu" <<'EOF'
FROM docker.io/library/ubuntu:latest
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y sudo && rm -rf /var/lib/apt/lists/* \
 && useradd -m -s /bin/bash tester \
 && echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester
USER tester
WORKDIR /home/tester
EOF

podman build -t dotfiles-test-fedora -f "$T/Containerfile.fedora" "$T"
podman build -t dotfiles-test-ubuntu -f "$T/Containerfile.ubuntu" "$T"
```

**Optional SSH layer**, to log in and try things by hand. It uses a throwaway password and the port is published on localhost only:

```sh
cat > "$T/Containerfile.ssh" <<'EOF'
ARG BASE
FROM ${BASE}
USER root
RUN if command -v dnf >/dev/null; then dnf install -y openssh-server && dnf clean all; \
    else apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server && rm -rf /var/lib/apt/lists/*; fi \
 && mkdir -p /run/sshd && ssh-keygen -A && echo 'tester:tester' | chpasswd
CMD ["/bin/sh", "-c", "mkdir -p /run/sshd && exec /usr/sbin/sshd -D -e"]
EOF
podman build --build-arg BASE=localhost/dotfiles-test-fedora -t dotfiles-ssh-fedora -f "$T/Containerfile.ssh" "$T"
podman build --build-arg BASE=localhost/dotfiles-test-ubuntu -t dotfiles-ssh-ubuntu -f "$T/Containerfile.ssh" "$T"
```

## 2. Start a container

`--init` reaps orphaned processes. Without it, a leftover `podman exec` session left a container stuck in "Stopping" until its `conmon` process was killed by hand.

```sh
D=fedora PORT=2222                   # or: D=ubuntu PORT=2223
C=dotfiles-$D

# With SSH:
podman run -d --init --name "$C" --user root -p 127.0.0.1:$PORT:22 \
  -v "$REPO":/src:ro,Z dotfiles-ssh-$D
# Without SSH:
# podman run -d --init --name "$C" -v "$REPO":/src:ro,Z dotfiles-test-$D sleep infinity
```

To remove a container, use `podman rm -f -t 0 "$C"`. Before reusing the name, wait until `podman container exists "$C"` returns false.

## 3. Install

Copy the repo to where the README says to clone it. There's no TTY, so pre-answer chezmoi's prompts.

```sh
podman exec -u tester -w /home/tester "$C" bash -c '
  mkdir -p ~/.local/share ~/.config/chezmoi
  cp -a /src ~/.local/share/chezmoi
  printf "[data]\n  name = \"Test User\"\n  email = \"test@example.com\"\n  work = false\n" \
    > ~/.config/chezmoi/chezmoi.toml'

podman exec -u tester -w /home/tester "$C" ~/.local/share/chezmoi/install.sh \
  </dev/null >"$T/$D.log" 2>&1; echo "exit=$?" >>"$T/$D.log"
```

It takes about 10 minutes. To follow progress without the noise:

```sh
tail -F "$T/$D.log" | grep -E --line-buffered \
  '==>|^chezmoi: |^exit=|unbound variable|Process terminated|API rate limit|mise ERROR|^E: '
```

Don't grep for bare `error` or `403`: dnf prints package names like `perl-Error` and download speeds like `403.7 KiB/s`.

### Expected noise (not failures)

| Message | Why |
|---|---|
| `sysctl: permission denied on key …` | containers can't change kernel limits; the script tolerates it |
| `Failed to connect to audit log` | no audit daemon in the container |
| `unknown variable: TMUX_PLUGIN_MANAGER_PATH` | TPM on a throwaway `tmux -L` server |

## 4. Verify

Run the checks as `tester` in a login shell, as the real session does:

```sh
x() { podman exec -u tester -e TERM=xterm-256color -e COLORTERM=truecolor "$C" bash -lic "$1" 2>/dev/null; }
```

| Check | Command | Expect |
|---|---|---|
| Install finished | `tail -1 "$T/$D.log"`; `grep -c '^chezmoi:' "$T/$D.log"` | `exit=0`; `0` |
| Login shell | `x 'getent passwd tester \| cut -d: -f7'` | `/usr/bin/bash` |
| Tools on PATH | see the loop below | `missing: none` |
| Runtimes from mise | `x 'which node python go nvim dotnet'` | paths under `~/.local/share/mise/` |
| .NET | `x 'dotnet --version; dotnet tool list -g'` | 10.x; `easydotnet`, `roslyn-language-server` |
| ICU (needed by .NET) | `x 'rpm -q libicu'` / `x 'dpkg -l \| grep libicu'` | installed |
| mise | `x 'mise doctor \| grep "problems found"'` | `No problems found` |
| tmux plugins | `x 'ls ~/.config/tmux/plugins'` | `tpm` |
| Font | `x 'ls ~/.local/share/fonts/JetBrainsMonoNerd \| wc -l'` | `96` |
| Neovim plugins | `x 'nvim --headless "+lua print(#require(\"lazy\").plugins())" +qa'` | a plugin count, no errors |
| bat themes | `x 'bat --list-themes --color=never \| grep Flexoki'` | `Flexoki Dark`, `Flexoki Light` |
| bash completions | `x 'ls ~/.local/share/bash-completion/completions \| wc -l; _comp_load git && complete -p git'` | about 22 files; `complete ... -F __git_wrap__git_main git` |
| AI CLIs owned by mise | `x 'which claude copilot; echo $DISABLE_AUTOUPDATER $COPILOT_AUTO_UPDATE'` | paths under `~/.local/share/mise/`; `1 false` |

```sh
x 'miss=""; for t in nvim node python go dotnet cargo rust-analyzer lazygit rg fd bat eza \
   zoxide delta difft sg tv atuin starship lefthook gotestsum sesh gh tree-sitter jq yq \
   poetry lf claude copilot tmux ghostty projects sesh-dir tm ee nv nv-edit; do
   command -v $t >/dev/null || miss="$miss $t"; done; echo "missing:${miss:- none}"'
```

## 5. Theme checks

These check that Flexoki switches with the terminal (see [ADR 0003](adr/0003-flexoki-theme-following-terminal.md)). Without a real Ghostty, the terminal is simulated by sending what Ghostty sends on a theme change: `ESC[?997;2n` for light and `ESC[?997;1n` for dark, plus answers to background-color queries (`ESC]11;?`).

### delta

Use a scratch repo. `COLORTERM=truecolor` (set by `x` above) is required, or delta falls back to 256 colors.

```sh
x 'cd /tmp && rm -rf dt && git init -q dt && cd dt && printf "def f(x):\n    return 1\n" > a.py &&
   git add a.py && git -c user.email=t@t -c user.name=t commit -qm init &&
   printf "def f(x):\n    return 2\n" > a.py
   for f in "" "--features flexoki-light --light" "--features flexoki-dark --dark"; do
     printf "%-34s %s\n" "${f:-(default)}" "$(delta $f --show-config | grep syntax-theme)"; done'
```

Expect `Base16` by default, then `Flexoki Light` and `Flexoki Dark`. If the features show `Base16`, something set `syntax-theme` in the main `[delta]` section, which beats features.

### Neovim

```sh
x 'cat > /tmp/bg.lua <<"EOF"
local function c(n,k) local h=vim.api.nvim_get_hl(0,{name=n,link=false}); return h[k] and ("#%06x"):format(h[k]) or "-" end
for _, bg in ipairs({ "dark", "light" }) do
  vim.o.background = bg
  print(("%s colors=%s Normal.bg=%s NormalFloat.bg=%s"):format(bg, vim.g.colors_name, c("Normal","bg"), c("NormalFloat","bg")))
end
EOF
nvim --headless "+luafile /tmp/bg.lua" +qa'
```

| Mode | Expect |
|---|---|
| dark | `colors=flexoki Normal.bg=#100f0f NormalFloat.bg=#1c1b1a` |
| light | `colors=flexoki Normal.bg=#fffcf0 NormalFloat.bg=#f2f0e5` |

When updating `nuvic/flexoki-nvim`, also scan every highlight group for leftovers from Rosé Pine, the theme it was forked from, such as `#1f1d2e`. Snacks highlight groups only exist after the snacks modules are `require`d.

### tmux hooks (and Neovim through tmux)

This helper attaches a tmux client in a pseudo-terminal and acts as the terminal: it answers background queries and sends theme reports. With `--nvim`, it runs Neovim in the pane and logs every change to `background`.

```sh
cat > "$T/theme2031.py" <<'EOF'
"""Fake terminal for tmux: answer OSC 11, send DEC 2031 theme reports, print what changed."""
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

Ubuntu ships tmux 3.6, which has the hooks but not the 3.8 `theme` option. To check the tmux config there without a full install:

```sh
podman run --rm -v "$REPO/dot_config/tmux":/cfg:ro,Z -v "$T":/t:ro,Z docker.io/library/ubuntu:latest bash -c '
  apt-get update -qq >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq tmux python3-minimal >/dev/null 2>&1
  mkdir -p ~/.config/tmux && cp /cfg/* ~/.config/tmux/ && tmux -V && TERM=xterm-256color python3 -I /t/theme2031.py'
```

### Full-screen apps (lazygit, lf)

Run them the same way: in a pseudo-terminal, answering `ESC]11;?`, then quit with `q`. Two things break this if missed:
- Set a window size, both with `TIOCSWINSZ` on the pty and with `LINES`/`COLUMNS`. Without it full-screen apps can exit or draw at the wrong size.
- Check for panel names (lazygit: `Status`, `Files`, `Commits`). lazygit's theme uses only basic colors, so it emits no truecolor codes.

## 6. Re-test after a change

There's no need to reinstall. Sync the source into the running container and apply:

```sh
tar -C "$REPO" --exclude=./.research --exclude=./.git -cf - . |
  podman exec -i -u tester "$C" bash -c 'cd ~/.local/share/chezmoi && tar -xf -'
x 'chezmoi apply --force'
```

`--force` is needed because LazyVim rewrites `~/.config/nvim/lazyvim.json` after its first start, and without a TTY chezmoi can't ask whether to overwrite it. Before merging, run the full install (steps 2–4) from a fresh container at least once.

## 7. Log in by hand (SSH image)

```sh
ssh -p 2222 tester@127.0.0.1         # password: tester; Ubuntu on 2223
tmux new -A -s main                  # attach to (or start) the main session
```

Each new container generates a new host key. If ssh warns about a changed key, run `ssh-keygen -R '[127.0.0.1]:2222'`.

Over SSH, tools that use basic terminal colors (lazygit's tmux popup, tv, starship, eza) are drawn with **your** terminal's palette, not Flexoki. Neovim and the tmux status bar use exact colors, so they show Flexoki in any terminal.

## 8. Clean up

```sh
podman rm -f -t 0 dotfiles-fedora dotfiles-ubuntu
podman rmi dotfiles-ssh-fedora dotfiles-ssh-ubuntu dotfiles-test-fedora dotfiles-test-ubuntu
rm -rf "$T"
```

## Bugs this has caught

| Symptom | Cause | Fix |
|---|---|---|
| `90-login-shell.sh: USER: unbound variable` | `$USER` is unset without a login session | fall back to `id -un` |
| `dotnet tool install` aborts: "Couldn't find a valid ICU package" | fresh Debian/Ubuntu has no ICU | ICU added to every distro's package list |
| lazygit's delta view ignores the Flexoki theme | delta lets `[delta]` options beat features | syntax theme moved into the `flexoki-ansi` feature |
| Violet floating windows in Neovim | Rosé Pine's `surface` color left in nuvic's port | overridden in `plugins/colorscheme.lua` |
