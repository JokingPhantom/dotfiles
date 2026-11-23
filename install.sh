#!/usr/bin/env bash
# Install these dotfiles into $HOME. Safe to re-run.
#
#   ./install.sh            set up bash, git, readline, vim
#   ./install.sh --tools    also install optional CLI tools (bat, fd, eza, delta, zoxide, ...)
#   ./install.sh --dry-run  print what would change
#
# ~/.bashrc and ~/.gitconfig stay machine-local files that source/include this
# repo, rather than symlinks into it. Installers that append to ~/.bashrc and
# `git config --global` then write to the local file, not to the repo.
# Anything replaced is moved aside to <file>.pre-dotfiles.<timestamp>.

set -euo pipefail

DOTFILES=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
STAMP=$(date +%Y%m%d%H%M%S)
DRY_RUN=0
TOOLS=0

for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=1 ;;
    --tools) TOOLS=1 ;;
    -h | --help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

say() { printf '  %-10s %s\n' "$1" "$2"; }
run() { if [ "$DRY_RUN" = 1 ]; then say would "$*"; else "$@"; fi; }

backup() {
  if [ -e "$1" ] || [ -L "$1" ]; then
    run mv "$1" "$1.pre-dotfiles.$STAMP"
    say backup "$1 -> $1.pre-dotfiles.$STAMP"
  fi
}

link() { # link SRC DST
  local src=$1 dst=$2
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    say ok "$dst"
    return
  fi
  run mkdir -p "$(dirname "$dst")"
  backup "$dst"
  run ln -s "$src" "$dst"
  say linked "$dst -> $src"
}

install_bashrc() {
  local rc="$HOME/.bashrc" line=". \"$DOTFILES/bash/init.bash\""
  if [ -f "$rc" ] && grep -qF "$DOTFILES/bash/init.bash" "$rc"; then
    say ok "$rc"
    return
  fi
  backup "$rc"
  if [ "$DRY_RUN" = 0 ]; then
    cat >"$rc" <<EOF
# ~/.bashrc: machine-local. Shared settings come from $DOTFILES.
# Put settings for this machine only (work aliases, local paths) in
# ~/.bashrc.d/*.bash or below the next line. Tool installers that append here
# are fine; what they add stays on this machine.
$line
EOF
  fi
  say wrote "$rc"
  # A login shell reads ~/.bash_profile instead of ~/.bashrc when it exists (macOS, some ssh).
  if [ ! -e "$HOME/.bash_profile" ] && [ "$(uname -s)" = Darwin ]; then
    run sh -c "printf '%s\n' '[ -r ~/.bashrc ] && . ~/.bashrc' > '$HOME/.bash_profile'"
    say wrote "$HOME/.bash_profile"
  fi
}

install_gitconfig() {
  local gc="$HOME/.gitconfig" include="$DOTFILES/git/config"
  if [ -f "$gc" ] && grep -qF "$include" "$gc"; then
    say ok "$gc"
  else
    # Keep the existing settings, below the include so they still win.
    if [ -f "$gc" ]; then run cp "$gc" "$gc.pre-dotfiles.$STAMP"; say backup "$gc -> $gc.pre-dotfiles.$STAMP"; fi
    if [ "$DRY_RUN" = 0 ]; then
      {
        printf '[include]\n\tpath = %s\n' "$include"
        printf '# Machine-local settings below override the shared file above.\n'
        [ -f "$gc.pre-dotfiles.$STAMP" ] && cat "$gc.pre-dotfiles.$STAMP"
      } >"$gc.tmp" && mv "$gc.tmp" "$gc"
    fi
    say wrote "$gc"
  fi
  if command -v git >/dev/null 2>&1 && [ -z "$(git config --global user.email || true)" ]; then
    say todo "set your identity: git config --global user.name 'Your Name'; git config --global user.email you@example.com"
  fi
  if command -v gh >/dev/null 2>&1 && ! git config --global --get-regexp '^credential\..*github' >/dev/null 2>&1; then
    say todo "run 'gh auth login && gh auth setup-git' to use gh for GitHub credentials"
  fi
}

install_tools() {
  local apt_pkgs="bat fd-find ripgrep fzf eza git-delta zoxide shellcheck tmux"
  local brew_pkgs="bash bash-completion@2 bat fd ripgrep fzf eza git-delta zoxide shellcheck tmux"
  if command -v brew >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    run brew install $brew_pkgs
  elif command -v apt-get >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    run sudo apt-get install -y $apt_pkgs
  else
    say skip "no brew or apt-get; install manually: $apt_pkgs"
  fi
}

echo "dotfiles: $DOTFILES"
install_bashrc
install_gitconfig
link "$DOTFILES/git/ignore" "$HOME/.config/git/ignore"
link "$DOTFILES/inputrc" "$HOME/.inputrc"
link "$DOTFILES/vim/vimrc" "$HOME/.vimrc"
run mkdir -p "$HOME/.bashrc.d"
[ "$TOOLS" = 1 ] && install_tools
echo "Done. Open a new shell, or run: exec bash"
