# Entry point for interactive bash. ~/.bashrc sources this file; see README.md.
#
# Load order matters: env sets PATH before tools look for binaries, and the
# prompt goes last so its PROMPT_COMMAND hook runs before any other tool's and
# can still read the previous command's exit status.

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export DOTFILES

# kb- commands are on PATH even in non-interactive shells (ssh host cmd,
# scripts, AI agents). Appended, so they never shadow anything.
case ":$PATH:" in
  *":$DOTFILES/bin:"*) ;;
  *) export PATH="$PATH:$DOTFILES/bin" ;;
esac

case $- in
  *i*) ;;
  *) return ;;
esac

for __dotfiles_module in env history defaults functions tools prompt; do
  # shellcheck source=/dev/null
  . "$DOTFILES/bash/$__dotfiles_module.bash"
done
unset __dotfiles_module

# Machine-local drop-ins (not in the repo): work aliases, secrets-free host tweaks.
if [ -d "$HOME/.bashrc.d" ]; then
  for __dotfiles_local in "$HOME"/.bashrc.d/*.bash; do
    # shellcheck source=/dev/null
    [ -r "$__dotfiles_local" ] && . "$__dotfiles_local"
  done
  unset __dotfiles_local
fi
