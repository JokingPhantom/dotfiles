# Stock command names keep their stock behavior. Preferred versions are kb-*
# commands (bin/ and functions.bash; run kb-help). The only changes here are
# color, which the distributions' default bashrc applies too, and Debian's
# renamed bat/fd binaries.

if ! __dotfiles_have bat && __dotfiles_have batcat; then alias bat='batcat'; fi
if ! __dotfiles_have fd && __dotfiles_have fdfind; then alias fd='fdfind'; fi

if command ls --color=auto -d . >/dev/null 2>&1; then alias ls='ls --color=auto'; fi
alias grep='grep --color=auto'
if diff --color=auto /dev/null /dev/null >/dev/null 2>&1; then alias diff='diff --color=auto'; fi
