# Line editing, matching bash's readline (inputrc).

# Emacs keys. zsh picks vi keys when $EDITOR contains "vi", unlike bash.
bindkey -e

# Up/Down search history for lines starting with what's typed so far.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
for __k in '^[[A' '^[OA' ${terminfo[kcuu1]:-}; do [[ -n $__k ]] && bindkey "$__k" up-line-or-beginning-search; done
for __k in '^[[B' '^[OB' ${terminfo[kcud1]:-}; do [[ -n $__k ]] && bindkey "$__k" down-line-or-beginning-search; done
unset __k

bindkey '^U' backward-kill-line # bash: Ctrl-U deletes to the start of the line, not all of it
bindkey '^[[3~' delete-char     # Delete
bindkey '^[[H' beginning-of-line; bindkey '^[OH' beginning-of-line # Home
bindkey '^[[F' end-of-line; bindkey '^[OF' end-of-line             # End
bindkey '^[[1;5D' backward-word; bindkey '^[[1;5C' forward-word    # Ctrl-Left/Right
bindkey '^[[1;3D' backward-word; bindkey '^[[1;3C' forward-word    # Alt-Left/Right

# As in bash: Alt-Backspace stops at / and . (deletes one path part), while
# Ctrl-W deletes back to the previous space.
WORDCHARS=${WORDCHARS//[\/.]/}
autoload -Uz backward-kill-word-match
zle -N backward-kill-space-word backward-kill-word-match
zstyle ':zle:backward-kill-space-word' word-style space
bindkey '^W' backward-kill-space-word
