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
    PKG_INSTALL=(brew install)
    PKG_UPDATE=(brew update)
  elif [[ "$OS" == "debian" ]]; then
    sudo apt-get update -qq
    PKG_INSTALL=(sudo apt-get install -y)
    PKG_UPDATE=(sudo apt-get update -qq)
  elif [[ "$OS" == "arch" ]]; then
    PKG_INSTALL=(sudo pacman -S --noconfirm)
    PKG_UPDATE=(sudo pacman -Sy)
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
      "${PKG_INSTALL[@]}" "$tool"
    else
      ok "$tool already installed"
    fi
  done

  # neovim
  if ! has nvim; then
    info "Installing neovim..."
    if [[ "$OS" == "macos" ]]; then
      "${PKG_INSTALL[@]}" neovim
    elif [[ "$OS" == "debian" ]]; then
      local arch; arch=$(uname -m)
      if [[ "$arch" == "x86_64" ]]; then
        local nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
        curl -Lo /tmp/nvim.appimage "$nvim_url"
        chmod +x /tmp/nvim.appimage
        sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
      else
        "${PKG_INSTALL[@]}" neovim
      fi
    elif [[ "$OS" == "arch" ]]; then
      "${PKG_INSTALL[@]}" neovim
    fi
  else
    ok "nvim already installed"
  fi

  # emacs
  if ! has emacs; then
    info "Installing emacs..."
    if [[ "$OS" == "macos" ]]; then
      "${PKG_INSTALL[@]}" emacs
    elif [[ "$OS" == "debian" ]]; then
      "${PKG_INSTALL[@]}" emacs-nox
    elif [[ "$OS" == "arch" ]]; then
      "${PKG_INSTALL[@]}" emacs
    fi
  else
    ok "emacs already installed"
  fi

  # git-delta (optional, enhances git diffs)
  if ! has delta; then
    info "Installing git-delta..."
    if [[ "$OS" == "macos" ]]; then
      "${PKG_INSTALL[@]}" git-delta
    elif [[ "$OS" == "debian" ]]; then
      local delta_url
      delta_url=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest \
        | grep "browser_download_url.*amd64.deb" | cut -d '"' -f 4)
      [[ -n "$delta_url" ]] || { warn "Could not resolve delta download URL — skipping"; return; }
      curl -Lo /tmp/git-delta.deb "$delta_url"
      sudo dpkg -i /tmp/git-delta.deb
    elif [[ "$OS" == "arch" ]]; then
      "${PKG_INSTALL[@]}" git-delta
    fi
  else
    ok "delta already installed"
  fi
}

###############################################################################
# Node / npm via nvm
###############################################################################

install_node() {
  if [[ -d "$HOME/.nvm" ]]; then
    ok "nvm already installed"
    return
  fi
  info "Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  info "Installing Node.js LTS..."
  nvm install --lts
  nvm use --lts
  nvm alias default 'lts/*'
  ok "node $(node --version) installed"
}

###############################################################################
# Python via uv
###############################################################################

install_python() {
  if has uv; then
    ok "uv already installed"
    return
  fi
  info "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
  ok "uv $(uv --version) installed"
}

###############################################################################
# AI tools: claude, pi, hermes
###############################################################################

install_ai_tools() {
  # Claude Code CLI
  if ! has claude; then
    info "Installing Claude Code CLI..."
    npm install -g @anthropic-ai/claude-code
  else
    ok "claude already installed"
  fi

  # pi coding agent
  if ! has pi; then
    info "Installing pi..."
    npm install -g @earendil-works/pi-coding-agent
  else
    ok "pi already installed"
  fi

  # hermes agent
  if [[ -d "$HOME/.hermes/hermes-agent" ]]; then
    ok "hermes already installed"
    return
  fi
  info "Installing hermes..."
  mkdir -p "$HOME/.hermes"
  git clone https://github.com/NousResearch/hermes-agent.git "$HOME/.hermes/hermes-agent"
  cd "$HOME/.hermes/hermes-agent"
  uv venv
  uv pip install -e .
  cd - >/dev/null

  # Write wrapper script
  mkdir -p "$HOME/.local/bin"
  cat > "$HOME/.local/bin/hermes" << 'WRAPPER'
#!/usr/bin/env bash
unset PYTHONPATH
unset PYTHONHOME
exec "$HOME/.hermes/hermes-agent/venv/bin/hermes" "$@"
WRAPPER
  chmod +x "$HOME/.local/bin/hermes"
  ok "hermes installed"
}


###############################################################################
# Spacemacs + clojure-lsp
###############################################################################

install_spacemacs() {
  if [[ -d "$HOME/.emacs.d" ]]; then
    ok "Spacemacs already installed"
  else
    info "Installing Spacemacs..."
    git clone https://github.com/syl20bnr/spacemacs "$HOME/.emacs.d"
  fi

  # clojure-lsp binary
  if has clojure-lsp; then
    ok "clojure-lsp already installed"
    return
  fi
  info "Installing clojure-lsp..."
  mkdir -p "$HOME/.local/bin"
  if [[ "$OS" == "macos" ]]; then
    brew tap clojure-lsp/brew 2>/dev/null || true
    brew install clojure-lsp/brew/clojure-lsp-native || \
      { warn "clojure-lsp brew install failed — skipping"; return; }
  elif [[ "$OS" == "debian" ]]; then
    local lsp_url
    lsp_url=$(curl -s https://api.github.com/repos/clojure-lsp/clojure-lsp/releases/latest \
      | grep "browser_download_url.*linux.*amd64" | grep -v ".jar" | cut -d '"' -f 4)
    [[ -n "$lsp_url" ]] || { warn "Could not resolve clojure-lsp download URL — skipping"; return; }
    curl -Lo "$HOME/.local/bin/clojure-lsp" "$lsp_url"
    chmod +x "$HOME/.local/bin/clojure-lsp"
  elif [[ "$OS" == "arch" ]]; then
    "${PKG_INSTALL[@]}" clojure-lsp
  fi
  ok "clojure-lsp installed"
}

###############################################################################
# Shell: oh-my-zsh + plugins
###############################################################################

install_shell() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "oh-my-zsh already installed"
  else
    info "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [[ ! -d "$custom/plugins/zsh-autosuggestions" ]]; then
    info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      "$custom/plugins/zsh-autosuggestions"
  else
    ok "zsh-autosuggestions already installed"
  fi

  if [[ ! -d "$custom/plugins/zsh-syntax-highlighting" ]]; then
    info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting \
      "$custom/plugins/zsh-syntax-highlighting"
  else
    ok "zsh-syntax-highlighting already installed"
  fi
}

###############################################################################
# tmux plugin manager
###############################################################################

install_tpm() {
  if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    ok "tpm already installed"
    return
  fi
  info "Installing tpm..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  ok "tpm installed"
}

###############################################################################
# Back up conflicts + stow all packages
###############################################################################

backup_and_stow() {
  info "Backing up conflicting files..."

  backup_if_exists "$HOME/.zshrc"
  backup_if_exists "$HOME/.tmux.conf"
  backup_if_exists "$HOME/.config/tmux"
  backup_if_exists "$HOME/.config/nvim"
  backup_if_exists "$HOME/.spacemacs"
  backup_if_exists "$HOME/.gitconfig"
  backup_if_exists "$HOME/.gitignore_global"
  backup_if_exists "$HOME/.hermes/config.yaml"
  backup_if_exists "$HOME/.hermes/SOUL.md"
  backup_if_exists "$HOME/.pi/agent/settings.json"
  backup_if_exists "$HOME/.pi/agent/models.json"
  backup_if_exists "$HOME/.claude/settings.json"

  info "Stowing packages..."
  cd "$DOTFILES"
  local packages=(zsh tmux nvim spacemacs git hermes pi claude)
  for pkg in "${packages[@]}"; do
    if [[ -d "$DOTFILES/$pkg" ]]; then
      stow --restow "$pkg"
      ok "stowed $pkg"
    else
      warn "package $pkg not found in $DOTFILES — skipping"
    fi
  done
}

###############################################################################
# Post-install message
###############################################################################

post_install_msg() {
  echo ""
  echo "========================================================"
  echo "  Installation complete!"
  echo "========================================================"
  echo ""
  echo "Next steps — see POST_INSTALL.md for the full guide:"
  echo "  cat $DOTFILES/POST_INSTALL.md"
  echo ""
  echo "Quick checklist:"
  echo "  1. cp ~/.zshrc.local.example ~/.zshrc.local  (fill in secrets)"
  echo "  2. cp ~/.hermes/.env.example ~/.hermes/.env  (fill in API keys)"
  echo "  3. claude  ->  /login"
  echo "  4. pi login"
  echo "  5. hermes login"
  echo "  6. tmux -> prefix+I  (install tpm plugins)"
  echo "  7. nvim  (LazyVim bootstraps automatically)"
  echo "  8. emacs  (Spacemacs installs layers, ~5 min)"
  echo ""
}

###############################################################################
# Main
###############################################################################

main() {
  echo "Setting up dotfiles from $DOTFILES"
  detect_os
  setup_package_manager
  install_core
  install_node
  install_python

  # nvm must be sourced before AI tools that need npm
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

  install_ai_tools
  install_spacemacs
  install_shell
  install_tpm
  backup_and_stow
  post_install_msg
}

main "$@"
