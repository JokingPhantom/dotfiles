# History: large, timestamped, deduplicated, and written after every command,
# so a crashed or closed shell loses nothing. Same as bash/history.bash.
# (Setting INC_APPEND_HISTORY also turns off macOS Terminal's per-tab history.)

HISTFILE=${HISTFILE:-${ZDOTDIR:-$HOME}/.zsh_history}
HISTSIZE=110000 # a little above SAVEHIST so duplicates are dropped before unique entries
SAVEHIST=100000
HISTORY_IGNORE='(exit|clear|history)'

setopt EXTENDED_HISTORY     # save timestamps and durations
setopt INC_APPEND_HISTORY   # write each command as it runs
setopt HIST_IGNORE_SPACE    # a command starting with a space isn't saved
setopt HIST_IGNORE_ALL_DUPS # a repeated command replaces its older copy
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY          # !! and !$ expand onto the line for review instead of running
setopt INTERACTIVE_COMMENTS # `# notes` at the prompt, as in bash
