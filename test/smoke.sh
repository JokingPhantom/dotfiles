#!/usr/bin/env bash
# Install into a throwaway $HOME, then check that an interactive shell starts
# cleanly and the aliases, git aliases, and prompt work.  Usage: test/smoke.sh
set -euo pipefail

DOTFILES=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export HOME=$TMP/home
mkdir -p "$HOME"
fail() { echo "FAIL: $*" >&2; exit 1; }

printf '[user]\n\tname = Test\n\temail = test@example.com\n' >"$HOME/.gitconfig"
"$DOTFILES/install.sh" >/dev/null
second=$("$DOTFILES/install.sh")
case $second in *wrote* | *linked* | *backup*) fail "second install changed something: $second" ;; esac
grep -q 'email = test@example.com' "$HOME/.gitconfig" || fail "existing gitconfig not kept"
[ "$(git config --global user.email)" = test@example.com ] || fail "local identity lost"
[ "$(git config --global --includes pull.ff)" = only ] || fail "shared git config not included"

# Interactive shell: startup must be silent on stderr.
DOTFILES_SSH_AGENT=0 bash -i -c 'type ll git-log c-less tsv2csv gsw __prompt_command >/dev/null' \
  2>"$TMP/stderr" </dev/null || fail "interactive startup: $(cat "$TMP/stderr")"
grep -v -e 'no job control' -e 'cannot set terminal process group' "$TMP/stderr" | grep . && fail "startup wrote to stderr"

# git aliases
repo=$TMP/repo
git init -q -b main "$repo"
GIT_COMMITTER_DATE='2001-01-01T00:00:00' git -C "$repo" commit -q --allow-empty -m first
git -C "$repo" switch -q -c feature
echo x >"$repo/a.rb"; echo y >"$repo/b.js"
git -C "$repo" add a.rb
git -C "$repo" commit -q -m second
[ "$(git -C "$repo" changed main -- '*.rb' '*.js' | tr '\n' ' ')" = "a.rb b.js " ] || fail "git changed"
lg=$(git -C "$repo" lg)
case $lg in *second*) ;; *) fail "git lg: $lg" ;; esac
[ "$(git -C "$repo" br | tail -1 | sed $'s/\e\\[[0-9;]*m//g' | cut -c1-9)" = "* feature" ] || fail "git br: newest branch should be last"

# tsv2csv
out=$(printf 'a\tb,c\td"e\tf\\nx\n' | bash -c ". '$DOTFILES/bash/functions.bash'; tsv2csv")
[ "$out" = "$(printf 'a,"b,c","d""e","f\nx"')" ] || fail "tsv2csv: $out"

# Prompt timing (bash 5+): drive a real interactive shell through a pty.
if command -v script >/dev/null 2>&1 && bash -c '[ -n "$EPOCHREALTIME" ]'; then
  cmds=$'sleep 0.3; true\nfalse\n\nexit\n'
  if script --version >/dev/null 2>&1; then # util-linux
    printf '%s' "$cmds" | DOTFILES_SSH_AGENT=0 TERM=xterm script -qec 'bash -i' /dev/null >"$TMP/pty" 2>&1 || true
  else # BSD script: stdin EOF reaches bash as ^D at once, so hold stdin open until bash has read the commands
    { printf '%s' "$cmds"; sleep 3; } | DOTFILES_SSH_AGENT=0 TERM=xterm script -q /dev/null bash -i >"$TMP/pty" 2>&1 || true
  fi
  grep -aqE 'Last cmd: ([3-9][0-9]{2}ms|[0-9]+\.[0-9]{3}s)' "$TMP/pty" || fail "prompt did not time 'sleep 0.3; true' as ~0.3s. pty output:$(tr -d '\r' <"$TMP/pty" | sed -n '1,40p' | cat -v)"
  grep -aq '\[exit 1\]' "$TMP/pty" || fail "prompt did not show exit status"
fi

echo "smoke: ok"
