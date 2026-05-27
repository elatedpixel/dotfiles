#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { echo "[info]  $*"; }
ok()   { echo "[ok]    $*"; }
warn() { echo "[warn]  $*"; }

has() { command -v "$1" &>/dev/null; }

###############################################################################
# Pull latest changes
###############################################################################

pull_latest() {
  info "Pulling latest from origin/main..."
  local before; before=$(git -C "$DOTFILES" rev-parse HEAD)
  git -C "$DOTFILES" pull --rebase origin main
  local after; after=$(git -C "$DOTFILES" rev-parse HEAD)

  if [[ "$before" == "$after" ]]; then
    ok "Already up to date."
  else
    echo ""
    info "Changes pulled:"
    git -C "$DOTFILES" log --oneline "${before}..${after}"
    echo ""
  fi
}

###############################################################################
# Re-stow all packages
###############################################################################

restow_packages() {
  info "Re-stowing packages..."
  cd "$DOTFILES"
  local packages=(zsh tmux nvim spacemacs git hermes pi claude)
  for pkg in "${packages[@]}"; do
    if [[ ! -d "$DOTFILES/$pkg" ]]; then
      warn "package $pkg not found — skipping (run install.sh to install new packages)"
      continue
    fi
    # Check if the target tool appears to be installed before stowing
    case "$pkg" in
      nvim)    has nvim    || { warn "nvim not installed — skipping nvim stow"; continue; } ;;
      spacemacs) [[ -d "$HOME/.emacs.d" ]] || { warn "spacemacs not installed — skipping"; continue; } ;;
      hermes)  [[ -d "$HOME/.hermes" ]]   || { warn "hermes not installed — skipping"; continue; } ;;
      pi)      [[ -d "$HOME/.pi" ]]       || { warn "pi not installed — skipping"; continue; } ;;
    esac
    stow --restow "$pkg"
    ok "restowed $pkg"
  done
}

###############################################################################
# Main
###############################################################################

pull_latest
restow_packages
echo ""
ok "Sync complete. Restart your shell or run: source ~/.zshrc"
