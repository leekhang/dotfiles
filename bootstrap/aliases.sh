# ── dotfiles: portable aliases ────────────────
alias ls='eza'
alias ll='eza -l'
alias la='eza -la'
alias lt='eza --tree'
alias ..='cd ..'
alias ...='cd ../..'
alias reload='source ~/.zshrc'
cdl() { cd "$1" && ls; }
tunnel() { ssh -N -L "${2}:localhost:${2}" "${1}"; }
# ─────────────────────────────────────────────
