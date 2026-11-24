# Completion, matching inputrc: case-insensitive, - and _ interchangeable,
# matches listed on the first Tab, colored by file type.

# Homebrew's completions (git, gh, brew, ...); /usr/local is in fpath already.
[[ -d /opt/homebrew/share/zsh/site-functions ]] && fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

# compinit takes ~100ms when it checks every completion file. Do that at most
# once a day and load the cached dump otherwise. -i skips insecure directories
# silently instead of prompting.
autoload -Uz compinit
() {
  setopt local_options extended_glob
  local dump=${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/zcompdump-$ZSH_VERSION
  mkdir -p "${dump:h}"
  if [[ -n $dump(#qN.mh-24) ]]; then compinit -C -d "$dump"; else compinit -i -d "$dump"; fi
}

zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}'
zstyle ':completion:*' menu select            # Tab again to walk the list with arrow keys
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/zcompcache"
unsetopt LIST_AMBIGUOUS # list matches on the first Tab (readline's show-all-if-ambiguous)
unsetopt BEEP           # inputrc: bell-style none

# Give kb-git-* the matching git completions (branches, refs, options).
compdef _git kb-git-log=git-log kb-git-switch=git-switch kb-git-changed=git-diff \
  kb-git-status=git-status kb-git-commit=git-commit
