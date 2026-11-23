# PATH, editor, pager, and colors.

path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}
# Find a command without searching Windows directories (/mnt/c/...) on WSL.
# A `command -v` miss scans all of PATH, and each /mnt/c entry costs
# milliseconds, which added up to ~200ms at startup. Elsewhere this is the same
# as `command -v`.
__dotfiles_which() {
  local IFS=: dir
  for dir in $PATH; do
    case $dir in /mnt/[a-z]/*) continue ;; esac
    if [ -x "$dir/$1" ] && [ ! -d "$dir/$1" ]; then
      printf '%s\n' "$dir/$1"
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
export PAGER=less

# less: -R keep colors, -F quit if it fits on one screen, -i smart-case search,
# -M verbose status line, -j.3 put search hits a third of the way down, -x4 tabs.
LESS='-R -F -i -M -j.3 -x4'
__less_version=$(less --version 2>/dev/null | awk 'NR==1 { print $2 + 0 }')
if [ "${__less_version:-0}" -lt 530 ]; then
  LESS="$LESS -X" # older less blanks the screen on exit when -F applies
fi
if [ "${__less_version:-0}" -ge 581 ]; then
  LESS="$LESS --incsearch"
fi
export LESS
unset __less_version

# Make less open archives, PDFs, etc. via lesspipe when installed.
if __dotfiles_have lesspipe; then
  eval "$(SHELL=/bin/sh lesspipe)"
elif __dotfiles_have lesspipe.sh; then
  export LESSOPEN="|lesspipe.sh %s"
fi

# Colored man pages: bat when available, otherwise less's termcap colors.
if __dotfiles_have bat || __dotfiles_have batcat; then
  __bat=$(__dotfiles_which bat || __dotfiles_which batcat)
  export MANPAGER="sh -c 'col -bx | $__bat -l man -p'"
  export MANROFFOPT='-c'
  unset __bat
else
  export GROFF_NO_SGR=1 # let LESS_TERMCAP_* apply to man pages
  export LESS_TERMCAP_md=$'\e[1;36m' LESS_TERMCAP_me=$'\e[0m'
  export LESS_TERMCAP_us=$'\e[4;32m' LESS_TERMCAP_ue=$'\e[0m'
  export LESS_TERMCAP_so=$'\e[1;30;43m' LESS_TERMCAP_se=$'\e[0m'
fi

# ls colors: GNU reads LS_COLORS, BSD/macOS reads CLICOLOR.
if __dotfiles_have dircolors; then
  if [ -r "$HOME/.dircolors" ]; then
    eval "$(dircolors -b "$HOME/.dircolors")"
  else
    eval "$(dircolors -b)"
  fi
else
  export CLICOLOR=1
fi
