#!/usr/bin/env bash
# Install into a throwaway $HOME, then check that an interactive shell starts
# cleanly and the kb- commands and prompt work.  Usage: test/smoke.sh
set -eu # no pipefail: checks are `cmd | grep -q`, where only grep's status matters
exec </dev/null # commands like rg search stdin when it is an open pipe

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

# Interactive shell: startup must be silent on stderr, and kb- functions defined.
DOTFILES_SSH_AGENT=0 bash -i -c 'type kb-cd kb-mkdir kb-alert kb-history kb-bash kb-ls __prompt_command >/dev/null' \
  2>"$TMP/stderr" </dev/null || fail "interactive startup: $(cat "$TMP/stderr")"
grep -v -e 'no job control' -e 'cannot set terminal process group' "$TMP/stderr" | grep . && fail "startup wrote to stderr"

# Old names point to new ones.
hint=$(DOTFILES_SSH_AGENT=0 bash -i -c 'll' 2>&1 </dev/null || true)
case $hint in *"ll is now kb-ls"*) ;; *) fail "renamed hint for ll: $hint" ;; esac

# kb- scripts are on PATH in a non-interactive shell too (ssh host cmd, agents).
[ "$(bash -c '. "$HOME/.bashrc"; command -v kb-ls' </dev/null)" = "$DOTFILES/bin/kb-ls" ] ||
  fail "kb-ls not on PATH in a non-interactive shell"
export PATH="$PATH:$DOTFILES/bin"
for f in "$DOTFILES"/bin/kb-*; do
  bash -n "$f" || fail "syntax: $f"
  [ -x "$f" ] || fail "not executable: $f"
  sed -n '2p' "$f" | grep -q "^# ${f##*/}: " || fail "${f##*/}: line 2 must be '# ${f##*/}: summary'"
done

# git commands
repo=$TMP/repo
git init -q -b main "$repo"
GIT_COMMITTER_DATE='2001-01-01T00:00:00' git -C "$repo" commit -q --allow-empty -m first
git -C "$repo" switch -q -c feature
echo x >"$repo/a.rb"; echo y >"$repo/b.js"
git -C "$repo" add a.rb
git -C "$repo" commit -q -m second
cd "$repo"
[ "$(kb-git-changed main -- '*.rb' '*.js' | tr '\n' ' ')" = "a.rb b.js " ] || fail "kb-git-changed"
lg=$(kb-git-log)
case $lg in *second*) ;; *) fail "kb-git-log: $lg" ;; esac
[ "$(kb-git-branch | tail -1 | cut -c1-9)" = "* feature" ] || fail "kb-git-branch: newest branch should be last"
kb-git-status | grep -q '## feature' || fail "kb-git-status"

# file and text commands
work=$TMP/work
mkdir -p "$work/sub" && cd "$work"
echo hello >a.txt; echo world >b.txt; printf 'x\ny\nx\n' >dup.txt; echo needle >sub/hay.txt
kb-ls | grep -q a.txt || fail "kb-ls"
kb-tree | grep -q sub || fail "kb-tree"
[ "$(kb-cat a.txt)" = hello ] || fail "kb-cat"
[ "$(kb-less a.txt </dev/null)" = hello ] || fail "kb-less"
kb-grep needle | grep -q hay.txt || fail "kb-grep"
kb-find hay | grep -q hay.txt || fail "kb-find"
kb-diff a.txt b.txt | grep -q '^+world' || fail "kb-diff"
[ "$(kb-uniq dup.txt | head -1 | tr -s ' ')" = " 2 x" ] || fail "kb-uniq"
kb-du | grep -q sub || fail "kb-du"
kb-df >/dev/null || fail "kb-df"
tar czf arc.tgz a.txt && mkdir ex && (cd ex && kb-tar ../arc.tgz >/dev/null 2>&1 && [ -f a.txt ]) || fail "kb-tar"
out=$(printf 'a\tb,c\td"e\tf\\nx\n' | kb-tsv2csv)
[ "$out" = "$(printf 'a,"b,c","d""e","f\nx"')" ] || fail "kb-tsv2csv: $out"
[ "$(SOME_TOKEN=abc kb-printenv | grep SOME_TOKEN)" = "SOME_TOKEN=***" ] || fail "kb-printenv masking"
[ "$(X=a:b kb-printenv X | wc -l | tr -d ' ')" = 2 ] || fail "kb-printenv split"

# system commands
kb-date | grep -q '^epoch' || fail "kb-date"
kb-date 1700000000 | grep -q '2023-11-14T22:13:20Z' || fail "kb-date epoch"
kb-ps | head -1 | grep -q PID || fail "kb-ps"
kb-free | grep -q 'Mem:' || fail "kb-free"
kb-ip >/dev/null || fail "kb-ip"
kb-netstat >/dev/null || fail "kb-netstat"
kb-help | grep -q '^kb-ls ' || fail "kb-help"
kb-help kb-tar | grep -q Usage || fail "kb-help kb-tar"

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
