export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

export EDITOR="nvim"
export PATH="$HOME/.local/bin:$PATH"

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
