# Integrations, each loaded only when the tool is installed. Same as
# bash/tools.bash, using each tool's zsh init.

# Source a tool's generated init script, caching it until the tool is updated.
#   __dotfiles_cached_init NAME COMMAND...
__dotfiles_cached_init() {
  local name=$1 bin cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
  shift
  bin=$(__dotfiles_which "$1") || return 0
  local cache="$cache_dir/$name.zsh"
  if [[ ! -s $cache || $bin -nt $cache ]]; then
    mkdir -p "$cache_dir" && "$@" >"$cache.tmp" 2>/dev/null && mv "$cache.tmp" "$cache" || return 0
  fi
  . "$cache"
}

# Version managers
if [[ -x $HOME/.rbenv/bin/rbenv ]]; then path_prepend "$HOME/.rbenv/bin"; fi
__dotfiles_cached_init rbenv rbenv init - --no-rehash zsh

# nvm: sourcing nvm.sh normally takes ~250ms, almost all of it `nvm use default`.
# Load it with --no-use and put the default version on PATH directly when the
# default alias resolves to an installed version; otherwise let nvm do it.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -s $NVM_DIR/nvm.sh ]]; then
  . "$NVM_DIR/nvm.sh" --no-use
  __v=default __hops=0
  while [[ -f $NVM_DIR/alias/$__v ]] && (( __hops < 5 )); do
    read -r __v <"$NVM_DIR/alias/$__v"
    (( __hops++ ))
  done
  if [[ -d $NVM_DIR/versions/node/$__v/bin ]]; then
    path_prepend "$NVM_DIR/versions/node/$__v/bin"
    export NVM_BIN="$NVM_DIR/versions/node/$__v/bin" NVM_INC="$NVM_DIR/versions/node/$__v/include/node"
  elif (( __hops > 0 )); then
    nvm use default --silent >/dev/null 2>&1
  fi
  unset __v __hops
fi

if __dotfiles_have mise; then eval "$(mise activate zsh)"; fi
__dotfiles_cached_init direnv direnv hook zsh
__dotfiles_cached_init zoxide zoxide init zsh # z <dir-fragment>

# fzf: Ctrl-R history search, Ctrl-T file picker, Alt-C cd
if __dotfiles_have fzf; then
  if fzf --zsh >/dev/null 2>&1; then # fzf 0.48+
    eval "$(fzf --zsh)"
  else
    for __f in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/fzf/key-bindings.zsh \
      /opt/homebrew/opt/fzf/shell/key-bindings.zsh "$HOME/.fzf/shell/key-bindings.zsh"; do
      if [[ -r $__f ]]; then . "$__f"; break; fi
    done
    unset __f
  fi
  export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border --info=inline'
  if __dotfiles_have fd || __dotfiles_have fdfind; then
    FZF_DEFAULT_COMMAND="$(__dotfiles_which fd || __dotfiles_which fdfind) --type f --hidden --exclude .git"
  elif __dotfiles_have rg; then
    FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!.git'"
  fi
  if [[ -n ${FZF_DEFAULT_COMMAND:-} ]]; then
    export FZF_DEFAULT_COMMAND FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi
  if __dotfiles_have bat || __dotfiles_have batcat; then
    export FZF_CTRL_T_OPTS="--preview '$(__dotfiles_which bat || __dotfiles_which batcat) --color=always --style=numbers --line-range=:200 {}'"
  fi
fi

# delta: syntax-highlighted git diffs. Set through the environment so git/config
# stays valid on machines without delta (interactive.diffFilter would break add -p).
if __dotfiles_have delta; then
  export GIT_PAGER=delta
  export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=interactive.diffFilter GIT_CONFIG_VALUE_0='delta --color-only'
fi

# ssh-agent: reuse one agent across shells (Linux/WSL; macOS's launchd provides one).
# Set DOTFILES_SSH_AGENT=0 in ~/.zshrc before the source line to turn this off.
if [[ ${DOTFILES_SSH_AGENT:-1} == 1 && $(uname -s) != Darwin ]] && __dotfiles_have ssh-agent; then
  ssh-add -l >/dev/null 2>&1
  if (( $? == 2 )); then # no reachable agent
    [[ -r $HOME/.ssh-agent ]] && . "$HOME/.ssh-agent" >/dev/null
    ssh-add -l >/dev/null 2>&1
    if (( $? == 2 )); then
      (umask 066; ssh-agent >"$HOME/.ssh-agent")
      . "$HOME/.ssh-agent" >/dev/null
    fi
  fi
  ssh-add -l >/dev/null 2>&1
  if (( $? == 1 )) && [[ -t 0 ]]; then ssh-add; fi # agent has no keys yet
fi
