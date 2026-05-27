# dotfiles

Terminal environment configs for macOS and Linux. One script to install everything, [GNU Stow](https://www.gnu.org/software/stow/) to manage symlinks.

## What's inside

### Shell & terminal
| Tool | Config | Links |
|------|--------|-------|
| [Zsh](https://www.zsh.org/) + [Oh My Zsh](https://ohmyz.sh/) | `zsh/.zshrc` | Shell framework with sensible defaults |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | bundled in `.zshrc` | Gray-shadow completions from history |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | bundled in `.zshrc` | Live syntax coloring as you type |
| [tmux](https://github.com/tmux/tmux) + [tpm](https://github.com/tmux-plugins/tpm) | `tmux/.config/tmux/tmux.conf` | `C-a` prefix, vi keys, split/navigate with `\|` and `-` |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | tmux + nvim | `Ctrl-h/j/k/l` across tmux panes and nvim splits |

### Editors
| Tool | Config | Links |
|------|--------|-------|
| [Neovim](https://neovim.io/) + [LazyVim](https://www.lazyvim.org/) | `nvim/.config/nvim/` | LazyVim distribution; repo contains overrides only |
| [Spacemacs](https://www.spacemacs.org/) | `spacemacs/.spacemacs` | Clojure dev setup with [clojure-lsp](https://clojure-lsp.io/) + [clj-kondo](https://github.com/clj-kondo/clj-kondo) |

### Git
| Tool | Config | Links |
|------|--------|-------|
| [Git](https://git-scm.com/) | `git/.gitconfig` | Rebase-on-pull, `current` push default, `nvim` editor |
| [delta](https://github.com/dandavison/delta) | bundled in `.gitconfig` | Syntax-highlighted diffs |

### AI coding agents
| Tool | Config | Links |
|------|--------|-------|
| [Claude Code](https://claude.ai/code) | `claude/.claude/settings.json` | Anthropic's CLI coding agent |
| [Pi](https://github.com/earendil-works/pi-coding-agent) | `pi/.pi/agent/` | `@earendil-works/pi-coding-agent` |
| [Hermes](https://github.com/NousResearch/hermes-agent) | `hermes/.hermes/` | NousResearch agent with Telegram integration |

### Languages & runtimes
[nvm](https://github.com/nvm-sh/nvm) (Node.js LTS) · [uv](https://github.com/astral-sh/uv) (Python)

---

## Install

```bash
git clone https://github.com/elatedpixel/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` will:

1. Detect your OS (macOS, Debian/Ubuntu, or Arch)
2. Install missing tools via Homebrew / apt / pacman
3. Set up nvm (Node.js LTS) and uv (Python)
4. Install Claude Code, Pi, and Hermes
5. Clone Spacemacs and install clojure-lsp
6. Install Oh My Zsh and plugins
7. Clone tpm (tmux plugin manager)
8. Back up any conflicting dotfiles to `*.bak.<timestamp>`
9. Symlink all configs with `stow --restow`

Everything is idempotent — safe to run multiple times.

After install, follow **[POST_INSTALL.md](POST_INSTALL.md)** to fill in secrets, authenticate each tool, and do the one-time bootstrapping steps for tmux, nvim, and Spacemacs.

---

## Sync

To pull updates pushed from another machine:

```bash
cd ~/dotfiles && ./sync.sh
```

Runs `git pull --rebase` then re-stows all packages. Never touches secrets.

---

## Structure

Each top-level directory is a [GNU Stow](https://www.gnu.org/software/stow/) package that mirrors the home directory layout.

```
dotfiles/
  install.sh              # install tools + stow everything
  sync.sh                 # pull updates + restow
  POST_INSTALL.md         # post-install guide (secrets, auth, bootstrap)
  zsh/
    .zshrc
    .zshrc.local.example  # copy to ~/.zshrc.local and add secrets
  tmux/
    .config/tmux/tmux.conf
  nvim/
    .config/nvim/
      lua/plugins/        # LazyVim overrides only
  spacemacs/
    .spacemacs
  git/
    .gitconfig
    .gitconfig.local.example
    .gitignore_global
  hermes/
    .hermes/
      config.yaml
      SOUL.md
      .env.example
  pi/
    .pi/agent/
      settings.json
      models.json
  claude/
    .claude/
      settings.json
```

---

## Secrets

Secrets live on-machine only — never in this repo.

| Secret | Location | How to set up |
|--------|----------|---------------|
| Shell env vars (tokens, API keys) | `~/.zshrc.local` | `cp ~/.zshrc.local.example ~/.zshrc.local` |
| Git identity (name, email) | `~/.gitconfig.local` | `cp ~/dotfiles/git/.gitconfig.local.example ~/.gitconfig.local` |
| Hermes API keys | `~/.hermes/.env` | `cp ~/.hermes/.env.example ~/.hermes/.env` |

`.gitignore` covers `*.local`, `.env`, `auth.json`, `.credentials.json`, and other secrets patterns.
