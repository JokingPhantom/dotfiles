# Integrations, each loaded only when the tool is installed.

# Programmable completion (Linux; Homebrew on macOS).
if ! shopt -oq posix; then
  for __f in /usr/share/bash-completion/bash_completion /etc/bash_completion \
    /opt/homebrew/etc/profile.d/bash_completion.sh /usr/local/etc/profile.d/bash_completion.sh; do
    # shellcheck source=/dev/null
    if [ -r "$__f" ]; then . "$__f"; break; fi
  done
  unset __f
fi

# Source a tool's generated init script, caching it until the tool is updated.
# Generating rbenv's takes ~120ms; sourcing the cached copy takes ~1ms.
#   __dotfiles_cached_init NAME COMMAND...
__dotfiles_cached_init() {
  local name=$1 bin cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
  shift
  bin=$(__dotfiles_which "$1") || return 0
  local cache="$cache_dir/$name.bash"
  if [ ! -s "$cache" ] || [ "$bin" -nt "$cache" ]; then
    mkdir -p "$cache_dir" && "$@" >"$cache.tmp" 2>/dev/null && mv "$cache.tmp" "$cache" || return 0
  fi
  # shellcheck source=/dev/null
  . "$cache"
}

# Version managers
if [ -x "$HOME/.rbenv/bin/rbenv" ]; then path_prepend "$HOME/.rbenv/bin"; fi
__dotfiles_cached_init rbenv rbenv init - --no-rehash bash

# nvm: sourcing nvm.sh normally takes ~250ms, almost all of it `nvm use default`.
# Load it with --no-use and put the default version on PATH directly when the
# default alias resolves to an installed version; otherwise let nvm do it.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh" --no-use
  __v=default __hops=0
  while [ -f "$NVM_DIR/alias/$__v" ] && [ $__hops -lt 5 ]; do
    read -r __v <"$NVM_DIR/alias/$__v"
    __hops=$((__hops + 1))
  done
  if [ -d "$NVM_DIR/versions/node/$__v/bin" ]; then
    path_prepend "$NVM_DIR/versions/node/$__v/bin"
    export NVM_BIN="$NVM_DIR/versions/node/$__v/bin" NVM_INC="$NVM_DIR/versions/node/$__v/include/node"
  elif [ "$__hops" -gt 0 ]; then
    nvm use default --silent >/dev/null 2>&1
  fi
  unset __v __hops
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
fi

if __dotfiles_have mise; then eval "$(mise activate bash)"; fi
__dotfiles_cached_init direnv direnv hook bash
__dotfiles_cached_init zoxide zoxide init bash # z <dir-fragment>

# fzf: Ctrl-R history search, Ctrl-T file picker, Alt-C cd
if __dotfiles_have fzf; then
  if fzf --bash >/dev/null 2>&1; then # fzf 0.48+
    eval "$(fzf --bash)"
  else
    for __f in /usr/share/doc/fzf/examples/key-bindings.bash /usr/share/fzf/key-bindings.bash \
      /opt/homebrew/opt/fzf/shell/key-bindings.bash "$HOME/.fzf/shell/key-bindings.bash"; do
      # shellcheck source=/dev/null
      if [ -r "$__f" ]; then . "$__f"; break; fi
    done
    unset __f
  fi
  export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border --info=inline'
  if __dotfiles_have fd || __dotfiles_have fdfind; then
    FZF_DEFAULT_COMMAND="$(__dotfiles_which fd || __dotfiles_which fdfind) --type f --hidden --exclude .git"
  elif __dotfiles_have rg; then
    FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!.git'"
  fi
  if [ -n "${FZF_DEFAULT_COMMAND:-}" ]; then
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
# Set DOTFILES_SSH_AGENT=0 in ~/.bashrc before the source line to turn this off.
if [ "${DOTFILES_SSH_AGENT:-1}" = 1 ] && [ "$(uname -s)" != Darwin ] && __dotfiles_have ssh-agent; then
  ssh-add -l >/dev/null 2>&1
  if [ $? = 2 ]; then # no reachable agent
    # shellcheck source=/dev/null
    [ -r "$HOME/.ssh-agent" ] && . "$HOME/.ssh-agent" >/dev/null
    ssh-add -l >/dev/null 2>&1
    if [ $? = 2 ]; then
      (umask 066; ssh-agent >"$HOME/.ssh-agent")
      # shellcheck source=/dev/null
      . "$HOME/.ssh-agent" >/dev/null
    fi
  fi
  ssh-add -l >/dev/null 2>&1
  if [ $? = 1 ] && [ -t 0 ]; then ssh-add; fi # agent has no keys yet
fi
