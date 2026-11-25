# Entry point for interactive zsh, sourced from ~/.zshrc. The zsh counterpart of
# bash/init.bash: same settings, prompt, and kb- commands.

. "${${(%):-%x}:A:h}/zshenv.zsh" # DOTFILES and PATH, in case ~/.zshenv doesn't source it

[[ -o interactive ]] || return 0

for __dotfiles_module in env history defaults functions completion keys tools prompt; do
  . "$DOTFILES/zsh/$__dotfiles_module.zsh"
done
unset __dotfiles_module

# Machine-local drop-ins (not in the repo): work aliases, secrets-free host tweaks.
for __dotfiles_local in "$HOME"/.zshrc.d/*.zsh(N); do
  [[ -r $__dotfiles_local ]] && . "$__dotfiles_local"
done
unset __dotfiles_local
