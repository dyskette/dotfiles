#!/usr/bin/env bash
# install.sh — bootstrap a blank Linux machine with these dotfiles.
#
# Usage (from a clone of this repo):   ./install.sh
# Usage (fresh machine, no clone yet): bash -c "$(curl -fsSL <raw-url>/install.sh)" -- <git-url>
#
# Steps: ensure curl+git → install mise (~/.local/bin/mise) → install chezmoi through mise →
# `chezmoi init --apply`, which runs .chezmoiscripts/ (OS packages, mise tools, fonts,
# dotnet tools, tmux plugins, Neovim plugins, login shell).
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = "Linux" ] || die "This bootstrap targets Linux only."

# --- 1. curl + git (needed before anything else) ---------------------------------
if ! command -v curl >/dev/null || ! command -v git >/dev/null; then
  log "Installing curl and git"
  if   command -v rpm-ostree >/dev/null && [ -e /run/ostree-booted ]; then die "Fedora Atomic ships curl+git; check your image."
  elif command -v dnf    >/dev/null; then sudo dnf install -y curl git
  elif command -v apt-get >/dev/null; then sudo apt-get update && sudo apt-get install -y curl git ca-certificates
  elif command -v pacman >/dev/null; then sudo pacman -Sy --needed --noconfirm curl git
  else die "Unsupported package manager: install curl and git manually."
  fi
fi

# --- 2. mise ---------------------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
if ! command -v mise >/dev/null; then
  log "Installing mise"
  curl -fsSL https://mise.run | sh
fi

# --- 3. chezmoi (owned by mise, see dot_config/mise/config.toml) -----------------
# `mise exec` installs it on demand without writing ~/.config/mise/config.toml,
# which chezmoi is about to manage.
cz() { mise exec chezmoi@latest -- chezmoi "$@"; }

# --- 4. apply --------------------------------------------------------------------
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "${script_dir}" ] && [ -f "${script_dir}/.chezmoi.toml.tmpl" ]; then
  log "Applying dotfiles from ${script_dir}"
  cz init --apply --source "${script_dir}"
elif [ -n "${1:-}" ]; then
  log "Cloning and applying dotfiles from $1"
  cz init --apply "$1"
else
  die "Run from a clone of the repo, or pass the git URL as the first argument."
fi

log "Done. Log out and back in (login shell → bash), then open Ghostty."
