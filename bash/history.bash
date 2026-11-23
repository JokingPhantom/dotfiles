# History: large, timestamped, deduplicated, and written after every command
# (prompt.bash calls `history -a`) so a crashed or closed shell loses nothing.

HISTCONTROL=ignoreboth:erasedups
HISTSIZE=100000
HISTFILESIZE=200000
HISTTIMEFORMAT='%F %T  '
HISTIGNORE='exit:clear:history'

shopt -s histappend # append on exit instead of overwriting
shopt -s cmdhist    # store a multi-line command as one entry
shopt -s checkwinsize
shopt -s globstar 2>/dev/null # ** matches nested directories (bash 4+)
