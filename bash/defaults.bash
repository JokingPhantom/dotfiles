# Stock command names keep their stock behavior. Preferred versions are kb-*
# commands (bin/ and functions.bash; run kb-help). The only changes here are
# color, which the distributions' default rc files apply too, and Debian's
# renamed bat/fd binaries. Same as zsh/defaults.zsh.
#
# These are functions, not aliases, so `alias` lists only the aliases you
# define yourself (in ~/.bashrc.d/ or ~/.bashrc). `type ls` shows them.
# `function NAME` rather than `NAME()`: a NAME() line breaks if a system rc
# file already made NAME an alias.

unalias ls grep diff bat fd 2>/dev/null

if ! __dotfiles_have bat && __dotfiles_have batcat; then function bat { batcat "$@"; }; fi
if ! __dotfiles_have fd && __dotfiles_have fdfind; then function fd { fdfind "$@"; }; fi

if command ls --color=auto -d . >/dev/null 2>&1; then function ls { command ls --color=auto "$@"; }; fi
function grep { command grep --color=auto "$@"; }
if diff --color=auto /dev/null /dev/null >/dev/null 2>&1; then function diff { command diff --color=auto "$@"; }; fi
