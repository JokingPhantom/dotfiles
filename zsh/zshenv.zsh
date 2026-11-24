# Sourced from ~/.zshenv, which every zsh reads (interactive or not, including
# `ssh host cmd`, scripts, and AI agents), so the kb- commands are always on PATH.
# Keep it small and silent. Interactive settings are in init.zsh.

DOTFILES=${DOTFILES:-${${(%):-%x}:A:h:h}}
export DOTFILES

# Appended, so kb- commands never shadow anything. macOS's /etc/zprofile
# (path_helper) reorders PATH for login shells but keeps this entry.
case ":$PATH:" in
  *":$DOTFILES/bin:"*) ;;
  *) export PATH="$PATH:$DOTFILES/bin" ;;
esac
