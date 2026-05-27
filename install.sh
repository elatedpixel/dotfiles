#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

###############################################################################
# Helpers
###############################################################################

info()  { echo "[info]  $*"; }
ok()    { echo "[ok]    $*"; }
warn()  { echo "[warn]  $*"; }
die()   { echo "[error] $*" >&2; exit 1; }

has() { command -v "$1" &>/dev/null; }

backup_if_exists() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    local backup="${target}.bak.$(date +%Y%m%d_%H%M%S)"
    info "Backing up $target → $backup"
    mv "$target" "$backup"
  fi
}

###############################################################################
# OS detection
###############################################################################

detect_os() {
  if [[ "$(uname)" == "Darwin" ]]; then
    OS="macos"
  elif [[ -f /etc/debian_version ]]; then
    OS="debian"
  elif [[ -f /etc/arch-release ]]; then
    OS="arch"
  else
    die "Unsupported OS: $(uname)"
  fi
  info "Detected OS: $OS"
}

###############################################################################
# Package manager setup
###############################################################################

setup_package_manager() {
  if [[ "$OS" == "macos" ]]; then
    if ! has brew; then
      info "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    PKG_INSTALL="brew install"
    PKG_UPDATE="brew update"
  elif [[ "$OS" == "debian" ]]; then
    sudo apt-get update -qq
    PKG_INSTALL="sudo apt-get install -y"
    PKG_UPDATE="sudo apt-get update -qq"
  elif [[ "$OS" == "arch" ]]; then
    PKG_INSTALL="sudo pacman -S --noconfirm"
    PKG_UPDATE="sudo pacman -Sy"
  fi
}

###############################################################################
# Core tools
###############################################################################

install_core() {
  info "Installing core tools..."

  local tools=(git stow zsh tmux curl)
  for tool in "${tools[@]}"; do
    if ! has "$tool"; then
      info "Installing $tool..."
      $PKG_INSTALL "$tool"
    else
      ok "$tool already installed"
    fi
  done

  # neovim
  if ! has nvim; then
    info "Installing neovim..."
    if [[ "$OS" == "macos" ]]; then
      $PKG_INSTALL neovim
    elif [[ "$OS" == "debian" ]]; then
      # apt neovim is often outdated; use AppImage for current version
      local nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
      curl -Lo /tmp/nvim.appimage "$nvim_url"
      chmod +x /tmp/nvim.appimage
      sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
    elif [[ "$OS" == "arch" ]]; then
      $PKG_INSTALL neovim
    fi
  else
    ok "nvim already installed"
  fi

  # emacs
  if ! has emacs; then
    info "Installing emacs..."
    if [[ "$OS" == "macos" ]]; then
      $PKG_INSTALL emacs
    elif [[ "$OS" == "debian" ]]; then
      $PKG_INSTALL emacs-nox
    elif [[ "$OS" == "arch" ]]; then
      $PKG_INSTALL emacs
    fi
  else
    ok "emacs already installed"
  fi

  # git-delta (optional, enhances git diffs)
  if ! has delta; then
    info "Installing git-delta..."
    if [[ "$OS" == "macos" ]]; then
      $PKG_INSTALL git-delta
    elif [[ "$OS" == "debian" ]]; then
      local delta_url
      delta_url=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest \
        | grep "browser_download_url.*amd64.deb" | cut -d '"' -f 4)
      curl -Lo /tmp/git-delta.deb "$delta_url"
      sudo dpkg -i /tmp/git-delta.deb
    elif [[ "$OS" == "arch" ]]; then
      $PKG_INSTALL git-delta
    fi
  else
    ok "delta already installed"
  fi
}
