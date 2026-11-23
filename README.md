# dotfiles

Bash, git, readline, and vim settings that set up any Linux, WSL, or macOS machine
the same way. Each modern tool (eza, bat, fd, delta, zoxide, fzf) is used
when installed and falls back to the standard one when not, so nothing breaks on a
bare server.

## Install

```sh
git clone https://github.com/JokingPhantom/dotfiles ~/dotfiles
~/dotfiles/install.sh            # add --tools to also install the optional CLI tools
exec bash
```

`install.sh` is safe to re-run. It moves anything it replaces to
`<file>.pre-dotfiles.<timestamp>`. `--dry-run` shows what it would change.

## How it fits together

| File in `$HOME`        | What it is                                                      |
| ---------------------- | --------------------------------------------------------------- |
| `~/.bashrc`            | Local stub that sources `bash/init.bash`                        |
| `~/.bashrc.d/*.bash`   | Machine-only shell settings (work aliases, local paths). Not in the repo |
| `~/.gitconfig`         | Local file that includes `git/config` first, then your identity and credentials |
| `~/.config/git/ignore` | Symlink to `git/ignore`                                         |
| `~/.inputrc`           | Symlink to `inputrc`                                            |
| `~/.vimrc`             | Symlink to `vim/vimrc`                                          |

`~/.bashrc` and `~/.gitconfig` are real files, not symlinks, so installers that
append to `.bashrc` and `git config --global` write to this machine only and
never into the repo.

## What you get

**Shell**
- Prompt: `[21:04:05.123 | Last cmd: 2.481s] user@host:~/repo (branch) [exit 1]$`.
  Times the whole command line (`a; b` included), shows the exit status when a
  command fails, and reads the git branch without running git.
- History: 100k entries, timestamps, no duplicates, saved after every command.
- Readline: case-insensitive Tab completion, and Up/Down search history for
  what you've already typed.
- fzf: Ctrl-R history, Ctrl-T files, Alt-C directories.

**Aliases and functions**

| Command | Does |
| ------- | ---- |
| `ll`, `la`, `l`, `lt` | ls (or eza) with human sizes and directories first; `lt` is a tree |
| `lessf` (`c-less`) | Follow a growing file. Ctrl-C to scroll, `F` to resume |
| `alert` | `long-command; alert` sends a desktop notification and rings the bell |
| `tsv2csv` (`mysql-txt-to-csv`) | `mysql -B -e '…' \| tsv2csv > out.csv` |
| `gsw` | Switch branch; with no argument, pick a recent one with fzf |
| `mkcd DIR`, `..`, `...`, `path`, `reload` | Small conveniences |

`less` defaults: keeps colors, quits when output fits on one screen, smart-case
search, highlights matches as you type. Man pages are colored.

**Git aliases** (in `git/config`, so they work without this shell)

| Alias | Does |
| ----- | ---- |
| `git lg` (`git-log`) | One line per commit: hash, date, relative date, author, subject, refs |
| `git lga` | `lg` as a graph of all branches |
| `git br [N\|all]` (`git-branch`) | 30 most recent local branches, newest just above the prompt, with ahead/behind |
| `git changed [BASE] [-- PATHSPEC]` | Files this branch touches since leaving origin's default branch, plus uncommitted and untracked |
| `git dn` (`git-diff-name`) | `diff --name-only` |
| `git st`, `sw`, `last`, `amend`, `unstage`, `undo` | Shortcuts |

Settings: `pull.ff=only`, `fetch.prune`, histogram diffs, `zdiff3` conflicts,
`rerere`, `rebase.autoSquash/autoStash/updateRefs`, branches sorted by date.
Needs git 2.38 or newer.

## Machine-specific settings

Put them in `~/.bashrc.d/<name>.bash`. Every `*.bash` file there loads after
the shared config. Set `DOTFILES_SSH_AGENT=0` above the source line in
`~/.bashrc` to turn off the shared ssh-agent.

## Requirements

Bash 4.4 or newer; bash 5 for command timing in the prompt. macOS ships bash
3.2, so run `brew install bash` there (`install.sh --tools` does it).

## Test

```sh
test/smoke.sh    # installs into a throwaway $HOME and drives an interactive shell
```

CI runs it with shellcheck on Ubuntu and macOS.
