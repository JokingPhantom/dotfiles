# Shell functions.

# Notify when a long command finishes:  make build; alert
alert() {
  local status=$? title cmd
  cmd=$(fc -ln -1 | sed -E 's/^[[:space:]]+//; s/[;&|][[:space:]]*alert[[:space:]]*$//')
  if [ "$status" -eq 0 ]; then title="Done"; else title="Failed ($status)"; fi
  if command -v notify-send >/dev/null 2>&1 && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    notify-send --urgency=low -i "$([ "$status" -eq 0 ] && echo terminal || echo error)" "$title" "$cmd"
  elif command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"${cmd//\"/\\\"}\" with title \"$title\""
  fi
  printf '\a%s: %s\n' "$title" "$cmd" # the bell flashes the taskbar in Windows Terminal and most others
  return "$status"
}

# Convert tab-separated input to CSV, e.g.  mysql -B -e 'select ...' | tsv2csv > out.csv
# Undoes mysql --batch escaping (\t \n \\) and quotes fields as RFC 4180 requires.
tsv2csv() {
  awk 'BEGIN { FS = "\t"; OFS = "," }
  {
    for (i = 1; i <= NF; i++) {
      f = $i
      gsub(/\\\\/, "\001", f); gsub(/\\t/, "\t", f); gsub(/\\n/, "\n", f); gsub(/\001/, "\\", f)
      if (f ~ /[",\n\r]/) { gsub(/"/, "\"\"", f); f = "\"" f "\"" }
      $i = f
    }
    print
  }' "$@"
}
alias mysql-txt-to-csv='tsv2csv'

mkcd() { mkdir -p -- "$1" && cd -- "$1" || return; }

# Switch branch. With no argument, pick from recent branches with fzf.
gsw() {
  if [ $# -gt 0 ] || ! command -v fzf >/dev/null 2>&1; then
    git switch "$@"
    return
  fi
  local branch
  branch=$(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/ |
    fzf --prompt='switch> ' --preview='git lg -20 --color=always {}') &&
    git switch "$branch"
}
