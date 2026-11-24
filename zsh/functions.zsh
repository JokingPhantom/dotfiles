# kb- commands that have to run inside the current shell (they change its
# directory, read its history, or replace it). The zsh versions of
# bash/functions.bash. Document each with a "# kb-NAME: summary" line so
# kb-help lists it.

# kb-cd: cd; with no argument, pick a directory below here with fzf
#
# Usage: kb-cd [DIR]
# A DIR that doesn't exist is looked up with zoxide when installed (frecent dirs).
kb-cd() {
  if (( $# )); then
    if [[ -d $1 ]] || (( ! $+functions[__zoxide_z] )); then cd "$@"; else __zoxide_z "$@"; fi
    return
  fi
  (( $+commands[fzf] )) || { cd; return; }
  local dir finder
  if finder=$(__dotfiles_which fd || __dotfiles_which fdfind); then
    dir=$("$finder" --type d --hidden --exclude .git | fzf --prompt='cd> ')
  else
    dir=$(find . -mindepth 1 \( -name .git -o -name node_modules \) -prune -o -type d -print | fzf --prompt='cd> ')
  fi
  [[ -n $dir ]] && cd -- "$dir"
}

# kb-mkdir: create a directory (and parents) and cd into it
#
# Usage: kb-mkdir DIR
kb-mkdir() { mkdir -p -- "$1" && cd -- "$1"; }

# kb-history: search shell history, newest last
#
# Usage: kb-history [PATTERN]      last 50 entries, or the last 50 matching PATTERN
# Ctrl-R gives an interactive search.
kb-history() {
  if (( $# == 0 )); then fc -li -50; else fc -li 1 | grep -i -- "$*" | tail -n 50; fi
}

# kb-zsh: restart zsh to pick up config changes
#
# Usage: kb-zsh
kb-zsh() { exec zsh; }

# kb-alert: notify when the previous command finishes
#
# Usage: long-command; kb-alert
# Desktop notification (notify-send, macOS) plus a terminal bell, which
# flashes the taskbar in Windows Terminal and most others.
kb-alert() {
  local st=$? title cmd
  # The line being run (zsh's `fc -l -1` is the one before it, unlike bash's).
  cmd=${history[$HISTCMD]:-$(fc -ln -1)}
  cmd=$(print -r -- "$cmd" | sed -E 's/^[[:space:]]+//; s/[;&|][[:space:]]*kb-alert[[:space:]]*$//')
  if (( st == 0 )); then title="Done"; else title="Failed ($st)"; fi
  if (( $+commands[notify-send] )) && [[ -n ${DISPLAY:-}${WAYLAND_DISPLAY:-} ]]; then
    notify-send --urgency=low "$title" "$cmd"
  elif (( $+commands[osascript] )); then
    osascript -e "display notification \"${cmd//\"/\\\"}\" with title \"$title\""
  fi
  printf '\a%s: %s\n' "$title" "$cmd"
  return $st
}

# Old names → kb- names, shown when an old name is typed. Added 2026-11-22;
# delete this block once the new names are habit. ~/.zshrc.d files add their own.
typeset -gA __kb_renamed
__kb_renamed+=(
  ll kb-ls la kb-ls l kb-ls lt kb-tree lessf kb-tail c-less kb-tail
  git-log kb-git-log git-branch kb-git-branch git-diff-name kb-git-changed
  gsw kb-git-switch mkcd kb-mkdir alert kb-alert tsv2csv kb-tsv2csv
  mysql-txt-to-csv kb-tsv2csv path 'kb-printenv PATH' reload kb-zsh kb-bash kb-zsh
  .. 'cd ..' ... 'cd ../..'
)

# Wrap any existing handler (e.g. Ubuntu's command-not-found package suggestions).
if (( $+functions[command_not_found_handler] && ! $+functions[__kb_prev_cnf_handler] )); then
  functions[__kb_prev_cnf_handler]=$functions[command_not_found_handler]
fi
command_not_found_handler() {
  if [[ -n ${__kb_renamed[$1]:-} ]]; then
    printf '%s is now %s (run kb-help for the full list)\n' "$1" "${__kb_renamed[$1]}" >&2
    return 127
  fi
  if (( $+functions[__kb_prev_cnf_handler] )); then __kb_prev_cnf_handler "$@"; return; fi
  printf 'zsh: command not found: %s\n' "$1" >&2
  return 127
}
