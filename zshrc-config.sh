#!/usr/bin/env zsh
#
# Custom Zsh Configuration for Fedora 43
# Enhanced shell experience with better history, completion, and aliases
#
# Author: Updated for Fedora 43
# Date: 2025-11-22

# ============================================================================
# History Configuration
# ============================================================================
HISTSIZE=10000                # Maximum number of events in internal history
SAVEHIST=10000                # Maximum number of events in history file
HISTFILE=~/.zsh_history       # History file location

# History options
setopt SHARE_HISTORY          # Share history between all sessions
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicate entries from history
setopt HIST_IGNORE_SPACE      # Don't save commands that start with space
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks from history
setopt HIST_VERIFY            # Show command with history expansion before running
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicates first when trimming history
setopt HIST_FIND_NO_DUPS      # Don't display duplicates when searching history

# ============================================================================
# Completion Configuration
# ============================================================================
autoload -Uz compinit && compinit

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Menu-based completion
zstyle ':completion:*' menu select

# Better completion for kill command
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always

# Colored completion (use LS_COLORS)
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Group completions
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%d%b'

# ============================================================================
# Colors and Appearance
# ============================================================================
autoload -U colors && colors

# Enable colored output for common commands
export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd

# ============================================================================
# Useful Aliases
# ============================================================================
# Directory listing
alias ls='ls --color=auto'
alias ll='ls -lAh --group-directories-first'
alias la='ls -A'
alias l='ls -CF'

# Grep with color
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# System management
alias update='sudo dnf update'
alias upgrade='sudo dnf upgrade'
alias install='sudo dnf install'
alias remove='sudo dnf remove'
alias search='dnf search'
alias info='dnf info'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Git shortcuts (if not provided by oh-my-zsh git plugin)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias glog='git log --oneline --graph --decorate'

# System information
alias df='df -h'
alias du='du -h'
alias free='free -h'

# Network
alias ports='netstat -tulanp'
alias myip='curl -s https://ipinfo.io/ip'

# Docker shortcuts
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlogs='docker logs'
alias dstop='docker stop $(docker ps -q)'

# ============================================================================
# Environment Variables
# ============================================================================
# Set default editor
export EDITOR='nano'
export VISUAL='nano'

# NVM configuration (if installed)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Load nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Load nvm bash_completion

# ============================================================================
# Key Bindings
# ============================================================================
# Use emacs key bindings (change to 'bindkey -v' for vi mode)
bindkey -e

# Better history search with arrow keys
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search   # Up arrow
bindkey "^[[B" down-line-or-beginning-search # Down arrow

# ============================================================================
# Performance Optimizations
# ============================================================================
# Skip verification of insecure directories for faster completion
ZSH_DISABLE_COMPFIX=true

# ============================================================================
# Custom Functions
# ============================================================================
# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive types
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.tar.xz)    tar xJf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.rar)       unrar x "$1"    ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1"       ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
