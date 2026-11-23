# Aliases. Each modern tool is used when installed and falls back to the
# standard one, so the same names work on any machine.

# Debian/Ubuntu ship bat and fd under different names.
if ! __dotfiles_have bat && __dotfiles_have batcat; then
  alias bat='batcat'
fi
if ! __dotfiles_have fd && __dotfiles_have fdfind; then
  alias fd='fdfind'
fi

# ls (detect GNU ls before any ls alias exists)
__gnu_ls=; if command ls --color=auto -d . >/dev/null 2>&1; then __gnu_ls=1; fi
if __dotfiles_have eza; then
  alias ls='eza --group-directories-first'
  alias ll='eza -alF --git --group-directories-first --time-style=long-iso'
  alias la='eza -a --group-directories-first'
  alias l='eza -F --group-directories-first'
  alias lt='eza --tree --level=2 --git-ignore'
elif [ -n "$__gnu_ls" ]; then
  alias ls='ls --color=auto --group-directories-first'
  alias ll='ls -alFh --time-style=long-iso'
  alias la='ls -A'
  alias l='ls -CF'
else # BSD/macOS ls
  alias ll='ls -alFh'
  alias la='ls -A'
  alias l='ls -CF'
fi
unset __gnu_ls

# grep (egrep/fgrep are deprecated and warn on grep 3.8+)
alias grep='grep --color=auto'
alias egrep='grep -E --color=auto'
alias fgrep='grep -F --color=auto'
if diff --color=auto /dev/null /dev/null >/dev/null 2>&1; then
  alias diff='diff --color=auto'
fi

# less
alias lessf='less -R +F' # follow a growing file like tail -f; Ctrl-C to scroll, F to resume
alias c-less='lessf'

# git (the real definitions are git aliases in git/config, usable without this shell)
alias git-log='git lg'
alias git-branch='git br'
alias git-diff-name='git dn'

# navigation and misc
alias ..='cd ..'
alias ...='cd ../..'
alias path='tr ":" "\n" <<<"$PATH"'
alias reload='exec bash'
