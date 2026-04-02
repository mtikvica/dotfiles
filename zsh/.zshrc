# ============================================
# Modern Zsh Configuration
# ============================================

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# ============================================
# Theme Configuration
# ============================================
ZSH_THEME="half-life"

# Alternative: if you prefer a simpler theme
# ZSH_THEME="agnoster"

# ============================================
# Oh-My-Zsh Settings
# ============================================
# Uncomment to disable auto-update
# DISABLE_AUTO_UPDATE="true"

# Auto-update behavior
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

# Disable marking untracked files under VCS as dirty
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Command execution timestamp format
HIST_STAMPS="dd-mm-yyyy"

# ============================================
# Plugins
# ============================================
# Standard plugins: $ZSH/plugins/
# Custom plugins: $ZSH_CUSTOM/plugins/
plugins=(
    git
    docker
    docker-compose
    kubectl
    terraform
    azure
    dotnet
    systemd
    sudo
    command-not-found
    colored-man-pages
    zsh-autosuggestions
    zsh-syntax-highlighting
    history-substring-search
    fzf
)

source $ZSH/oh-my-zsh.sh

# ============================================
# User Configuration
# ============================================

# Preferred editor
export EDITOR='nvim'
export VISUAL='nvim'

# Language environment
export LANG=en_US.UTF-8

# ============================================
# History Configuration
# ============================================
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history

setopt EXTENDED_HISTORY          # Write timestamps to history
setopt INC_APPEND_HISTORY        # Add commands immediately
setopt SHARE_HISTORY             # Share history between sessions
setopt HIST_IGNORE_DUPS          # Don't record duplicate entries
setopt HIST_IGNORE_ALL_DUPS      # Delete old duplicate entries
setopt HIST_FIND_NO_DUPS         # Don't display duplicates in search
setopt HIST_IGNORE_SPACE         # Don't record commands starting with space
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries
setopt HIST_REDUCE_BLANKS        # Remove extra blanks from commands

# ============================================
# Completion Configuration
# ============================================
setopt COMPLETE_IN_WORD          # Complete from both ends of word
setopt ALWAYS_TO_END             # Move cursor to end after completion
setopt AUTO_MENU                 # Show completion menu on tab
setopt AUTO_LIST                 # List choices on ambiguous completion

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Colored completion (different colors for dirs/files/etc)
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ============================================
# Key Bindings
# ============================================
# Vi mode (optional - comment out if you prefer emacs mode)
# bindkey -v

# Better history search with arrow keys
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Ctrl+arrow keys for word navigation
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ============================================
# Aliases
# ============================================

# ls with colors and better defaults
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

# grep with color
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Quick config edits
alias zshconfig='nvim ~/.zshrc'
alias tmuxconfig='nvim ~/.tmux.conf'
alias nvimconfig='nvim ~/.config/nvim/init.lua'

# ============================================
# Functions
# ============================================

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar x $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find process by name
psgrep() {
    ps aux | grep -v grep | grep -i -e VSZ -e $1
}

# ============================================
# Path Configuration
# ============================================
# Add custom paths here
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# .NET tools
export PATH="$HOME/.dotnet/tools:$PATH"

# Go (if installed)
# export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

# ============================================
# Tool Configurations
# ============================================

# fzf configuration (if installed)
if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
fi

# NVM (Node Version Manager) - uncomment if you use it
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# pyenv (Python version manager) - uncomment if you use it
# export PYENV_ROOT="$HOME/.pyenv"
# command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"

# ============================================
# Powerlevel10k Instant Prompt
# ============================================
# Enable instant prompt (should stay close to the top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Powerlevel10k configuration (run 'p10k configure' to customize)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ============================================
# Local Configuration
# ============================================
# Source local configuration (not tracked by git)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
export PATH="$HOME/.cargo/bin:$PATH"
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$HOME/.dotnet:$PATH
export DOTNET_CLI_TELEMETRY_OPTOUT=1
