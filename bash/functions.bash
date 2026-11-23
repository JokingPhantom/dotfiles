# kb- commands that have to run inside the current shell (they change its
# directory, read its history, or replace it). Every other kb- command is a
# script in bin/. Document each with a "# kb-NAME: summary" line so kb-help
# lists it.

# kb-cd: cd; with no argument, pick a directory below here with fzf
#
# Usage: kb-cd [DIR]
# A DIR that doesn't exist is looked up with zoxide when installed (frecent dirs).
kb-cd() {
  if [ $# -gt 0 ]; then
    if [ -d "$1" ] || ! declare -F __zoxide_z >/dev/null; then cd "$@" || return; else __zoxide_z "$@"; fi
    return
  fi
  command -v fzf >/dev/null 2>&1 || { cd || return; return; }
  local dir finder
  if finder=$(__dotfiles_which fd || __dotfiles_which fdfind); then
    dir=$("$finder" --type d --hidden --exclude .git | fzf --prompt='cd> ')
  else
    dir=$(find . -mindepth 1 \( -name .git -o -name node_modules \) -prune -o -type d -print | fzf --prompt='cd> ')
  fi
  [ -n "$dir" ] && cd "$dir" || return
}

# kb-mkdir: create a directory (and parents) and cd into it
#
# Usage: kb-mkdir DIR
kb-mkdir() { mkdir -p -- "$1" && cd -- "$1" || return; }

# kb-history: search shell history, newest last
#
# Usage: kb-history [PATTERN]      last 50 entries, or the last 50 matching PATTERN
# Ctrl-R gives an interactive search.
kb-history() {
  if [ $# -eq 0 ]; then history 50; else history | grep -i -- "$*" | tail -n 50; fi
}

# kb-bash: restart the shell to pick up config changes
#
# Usage: kb-bash
kb-bash() { exec bash; }

# kb-alert: notify when the previous command finishes
#
# Usage: long-command; kb-alert
# Desktop notification (notify-send, macOS) plus a terminal bell, which
# flashes the taskbar in Windows Terminal and most others.
kb-alert() {
  local status=$? title cmd
  cmd=$(fc -ln -1 | sed -E 's/^[[:space:]]+//; s/[;&|][[:space:]]*kb-alert[[:space:]]*$//')
  if [ "$status" -eq 0 ]; then title="Done"; else title="Failed ($status)"; fi
  if command -v notify-send >/dev/null 2>&1 && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    notify-send --urgency=low "$title" "$cmd"
  elif command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"${cmd//\"/\\\"}\" with title \"$title\""
  fi
  printf '\a%s: %s\n' "$title" "$cmd"
  return "$status"
}

# Old names → kb- names, shown when an old name is typed. Added 2026-11-22;
# delete this block once the new names are habit. ~/.bashrc.d files add their own.
if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
  declare -gA __kb_renamed 2>/dev/null || declare -A __kb_renamed
  __kb_renamed+=(
    [ll]=kb-ls [la]=kb-ls [l]=kb-ls [lt]=kb-tree [lessf]=kb-tail [c-less]=kb-tail
    [git-log]=kb-git-log [git-branch]=kb-git-branch [git-diff-name]=kb-git-changed
    [gsw]=kb-git-switch [mkcd]=kb-mkdir [alert]=kb-alert [tsv2csv]=kb-tsv2csv
    [mysql-txt-to-csv]=kb-tsv2csv [path]='kb-printenv PATH' [reload]=kb-bash
    [..]='cd ..' [...]='cd ../..'
  )

  # Wrap any existing handler (Ubuntu's suggests packages to install).
  if declare -F command_not_found_handle >/dev/null && ! declare -F __kb_prev_cnf_handle >/dev/null; then
    eval "$(declare -f command_not_found_handle | sed '1s/command_not_found_handle/__kb_prev_cnf_handle/')"
  fi
  command_not_found_handle() {
    if [ -n "${__kb_renamed[$1]:-}" ]; then
      printf '%s is now %s (run kb-help for the full list)\n' "$1" "${__kb_renamed[$1]}" >&2
      return 127
    fi
    if declare -F __kb_prev_cnf_handle >/dev/null; then __kb_prev_cnf_handle "$@"; return; fi
    printf 'bash: %s: command not found\n' "$1" >&2
    return 127
  }
fi
