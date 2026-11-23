# Entry point for interactive bash. ~/.bashrc sources this file; see README.md.
#
# Load order matters: env sets PATH before tools look for binaries, and the
# prompt goes last so its PROMPT_COMMAND hook runs before any other tool's and
# can still read the previous command's exit status.

case $- in
  *i*) ;;
  *) return ;;
esac

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export DOTFILES

for __dotfiles_module in env history aliases functions tools prompt; do
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
