# PATH, editor, pager, and colors. Same settings as bash/env.bash.

path_prepend() {
  [[ -d $1 ]] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}
# Find a command without searching Windows directories (/mnt/c/...) on WSL,
# where each miss costs milliseconds. Elsewhere this is the same as `command -v`.
__dotfiles_which() {
  local dir
  for dir in ${(s.:.)PATH}; do
    [[ $dir == /mnt/[a-z]/* ]] && continue
    if [[ -x $dir/$1 && ! -d $dir/$1 ]]; then
      print -r -- "$dir/$1"
      return 0
    fi
  done
  return 1
}
__dotfiles_have() { __dotfiles_which "$1" >/dev/null; }

path_prepend "$HOME/bin"
path_prepend "$HOME/.local/bin"
export PATH

export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"
# Programs that page (git, man, psql, delta) use kb-less; typing `less` stays stock.
export PAGER=kb-less

if __dotfiles_have lesspipe; then
  eval "$(SHELL=/bin/sh lesspipe)"
elif __dotfiles_have lesspipe.sh; then
  export LESSOPEN="|lesspipe.sh %s"
fi

# Colored man pages: bat when available, otherwise less's termcap colors.
if __dotfiles_have bat || __dotfiles_have batcat; then
  export MANPAGER="sh -c 'col -bx | $(__dotfiles_which bat || __dotfiles_which batcat) -l man -p'"
  export MANROFFOPT='-c'
else
  export GROFF_NO_SGR=1
  export LESS_TERMCAP_md=$'\e[1;36m' LESS_TERMCAP_me=$'\e[0m'
  export LESS_TERMCAP_us=$'\e[4;32m' LESS_TERMCAP_ue=$'\e[0m'
  export LESS_TERMCAP_so=$'\e[1;30;43m' LESS_TERMCAP_se=$'\e[0m'
fi

# ls colors: GNU reads LS_COLORS, BSD/macOS reads CLICOLOR.
if __dotfiles_have dircolors; then
  if [[ -r $HOME/.dircolors ]]; then
    eval "$(dircolors -b "$HOME/.dircolors")"
  else
    eval "$(dircolors -b)"
  fi
else
  export CLICOLOR=1
fi
