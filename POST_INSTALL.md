# Post-Install Guide

Follow these steps after `install.sh` completes. They are ordered by dependency —
secrets first, then auth, then first-launch bootstrapping.

This guide is written for both human and agent use. Agent note: do **not**
generate, guess, or fabricate secret values. Ask the user to supply them.

---

## 1. Secrets — do this before launching any tool

### Shell secrets

```bash
cp ~/.zshrc.local.example ~/.zshrc.local
```

Edit `~/.zshrc.local` and set any tokens you use in interactive shells.
The file already has commented examples showing what to set.

### Git identity

```bash
cp ~/dotfiles/git/.gitconfig.local.example ~/.gitconfig.local
```

Edit `~/.gitconfig.local` and set `user.name` and `user.email`.

### Hermes API keys

```bash
cp ~/.hermes/.env.example ~/.hermes/.env
```

Edit `~/.hermes/.env` and fill in at minimum `ANTHROPIC_TOKEN` and any
communication tokens (`TELEGRAM_BOT_TOKEN`, etc.) you use.

---

## 2. Authenticate each tool

Run these in order. Each one must succeed before proceeding to the next.

| Tool | Command | Success check |
|------|---------|---------------|
| Claude | `claude` then type `/login` | `claude --print -p "hi"` returns a response |
| Pi | `pi login` | `pi -p "hi"` returns a response |
| Hermes | `hermes login` | `hermes` opens without an auth error |

---

## 3. First-launch bootstrapping

These steps cannot be automated. Each must be done manually once.

### tmux plugins

```bash
tmux new-session -s setup
# Inside tmux: press Ctrl-a then I (capital i)
# Wait for tpm to finish installing plugins, then press Enter
```

Done when: you see "TMUX environment reloaded" and the status bar is styled.

### Neovim (LazyVim)

```bash
nvim
```

LazyVim detects its first run and downloads all plugins automatically.
Done when: nvim opens normally without a "bootstrapping" progress bar.

### Spacemacs

```bash
emacs
```

Spacemacs installs all configured layers on first launch. This takes 3–5
minutes. When it finishes, it will prompt you to restart — do so.

Done when: Spacemacs opens to the home buffer on second launch without
installing anything.

---

## 4. Verify everything works

Run these checks after completing the steps above.

```bash
# zsh autosuggestions active
echo $ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE
# Expected: fg=#666666

# tmux: C-a prefix, vim pane navigation
tmux new-session -s verify
# Inside: Ctrl-a | to split vertically, then Ctrl-h/j/k/l to navigate panes
# Ctrl-a d to detach
tmux kill-session -t verify

# nvim health
nvim +checkhealth +qall 2>&1 | grep -E "ERROR|WARNING" | head -20

# Spacemacs version
emacs --batch --eval "(message \"%s\" spacemacs-version)" 2>&1

# AI tools
claude --print -p "say: ok"
pi -p "say: ok"
hermes -p "say: ok"
```

---

## 5. Clojure LSP in Spacemacs

Open any `.clj` file:

```bash
emacs ~/some-project/src/core.clj
```

On first open per project, clojure-lsp indexes the project (30–60 seconds
for large projects). LSP is working when the mode-line shows
`LSP[clojure-lsp]`.

If LSP does not start, run `SPC m h h` (cider-doc) to trigger it, or check
`*lsp-log*` buffer for errors.

---

## 6. Keeping configs in sync across machines

To pull config updates pushed from another machine:

```bash
cd ~/dotfiles && ./sync.sh
```

`sync.sh` runs `git pull --rebase` then re-stows all packages. It never
touches secrets files. See `sync.sh` for full details on what it does and
does not do.

To upgrade tool versions (not managed by sync.sh):

| Tool | Upgrade command |
|------|----------------|
| nvim, tmux, emacs | `brew upgrade` / `apt upgrade` |
| claude | `claude update` |
| pi | `npm update -g @earendil-works/pi-coding-agent` |
| hermes | `cd ~/.hermes/hermes-agent && git pull && uv pip install -e .` |
| LazyVim plugins | inside nvim: `:Lazy update` |
| Spacemacs layers | inside emacs: `SPC f e U` |
| tpm plugins | inside tmux: `prefix + U` |
