# dotfiles

zsh, bash, git, readline, and vim settings that set up any Linux, WSL, or macOS
machine the same way, plus `kb-` commands: the standard Unix utilities with my
preferred defaults.

## Install

```sh
git clone https://github.com/JokingPhantom/dotfiles ~/dotfiles
~/dotfiles/install.sh            # add --tools to also install the optional CLI tools
exec zsh                         # or: exec bash
```

zsh and bash get the same prompt, history, completion, key bindings, tool
integrations, and kb- commands; use whichever is your login shell (zsh is the
macOS default). `install.sh` sets up both and is safe to re-run. It moves anything it replaces to
`<file>.pre-dotfiles.<timestamp>`. `--dry-run` shows what it would change.

## kb- commands

Every custom command is named `kb-<the command it improves>` and works like that
command with my defaults: `kb-ls`, `kb-less`, `kb-grep`, `kb-git-log`. Stock names
keep stock behavior, so `less` is still plain less. Type `kb-` and press Tab to
see them all, or run `kb-help` for a summary and `kb-help kb-tar` for one
command's usage.

Each one uses a modern tool when installed (eza, bat, rg, fd, delta, btop) and
falls back to the standard utility, handling the GNU/BSD differences between
Linux and macOS. They're scripts in `bin/`, on `PATH` in every zsh and bash
shell, including non-interactive ones, so they also work from scripts, other
shells, and AI agents. The few that must change the current shell (`kb-cd`,
`kb-mkdir`, `kb-history`, `kb-alert`, `kb-zsh`/`kb-bash`) are functions in
`zsh/functions.zsh` and `bash/functions.bash`; change both when editing one.

| Files and text | |
| --- | --- |
| `kb-ls` | Long listing: hidden files, human sizes, directories first, ISO dates, git status |
| `kb-tree [DEPTH]` | Tree, 2 levels, skipping .git and ignored files |
| `kb-cat` | Syntax highlighting, line numbers, git changes |
| `kb-less` | Keeps colors, exits if it fits on screen, smart-case search. Also `$PAGER` for git and man |
| `kb-tail FILE` | Follow a growing file in less: Ctrl-C to scroll and search, F to resume |
| `kb-grep PATTERN` | Recursive, smart-case, line numbers, skips .git, binaries, ignored files |
| `kb-find [PATTERN]` | Files whose name contains PATTERN, hidden included |
| `kb-diff OLD NEW` | Unified, colored diff of files or directories |
| `kb-cp`, `kb-mv` | Recursive, ask before overwriting, list what moved |
| `kb-rm` | Move to the trash instead of deleting |
| `kb-du`, `kb-df` | Directory sizes largest last; real filesystems only |
| `kb-tar ARCHIVE` | Extract any archive type (`-l` lists) |
| `kb-uniq` | Count identical lines, most frequent first |
| `kb-tsv2csv` | Tab-separated (e.g. `mysql -B`) to CSV |
| `kb-pbcopy`, `kb-pbpaste` | Clipboard on macOS, WSL, Wayland, X11, and over ssh (OSC 52) |
| `kb-open [PATH]` | Open in the desktop's default app |

| System and network | |
| --- | --- |
| `kb-ps [PATTERN]` | Processes by CPU; top 25 or all matching |
| `kb-top` | btop, htop, or top sorted by CPU |
| `kb-free` | Memory use (macOS too) |
| `kb-netstat [PORT]` | Listening ports and their processes |
| `kb-ip` | Interfaces and addresses, one line each (`--public` for your public IP) |
| `kb-ping [HOST]` | 5 pings, default 1.1.1.1 |
| `kb-dig NAME [TYPE]` | Just the answer records |
| `kb-curl URL` | Follows redirects; status, size, and time on stderr |
| `kb-watch CMD` | Rerun every 2s highlighting changes (works on macOS without watch) |
| `kb-date [EPOCH]` | Local, UTC, epoch; converts epoch seconds or milliseconds |
| `kb-printenv [NAME]` | Sorted, secrets masked; PATH-like values one per line |
| `kb-tmux [NAME]` | Attach or create a session |
| `kb-mysql` | Pages wide results, vertical when rows don't fit, shows warnings |

| Shell | |
| --- | --- |
| `kb-cd [DIR]` | cd; with no argument, pick a directory with fzf |
| `kb-mkdir DIR` | Create and cd into it |
| `kb-history [PATTERN]` | Search history |
| `kb-alert` | `long-command; kb-alert` notifies when done |
| `kb-zsh`, `kb-bash` | Restart the shell to reload config |
| `kb-help [CMD]` | List commands or show one's usage |

| Git and dev | |
| --- | --- |
| `kb-git-log` | One line per commit: hash, date, relative date, author, subject, refs |
| `kb-git-branch [N\|all]` | 30 most recent branches, newest just above the prompt, with ahead/behind |
| `kb-git-switch [BRANCH]` | With no argument, pick a recent branch with fzf |
| `kb-git-changed [BASE]` | Files this branch touches since it left origin's default branch, plus uncommitted and untracked |
| `kb-git-status` | Short status with branch |
| `kb-git-commit` | Commit showing the diff; `--amend` keeps the message; `--undo` undoes the last commit, keeping changes |
| `kb-rubocop`, `kb-prettier` | Lint/format only the files this branch changed |
| `kb-rspec`, `kb-jest`, `kb-test` | Run the tests for what this branch changed |

Typing a command's old name (`ll`, `git-log`, `c-less`, ...) prints its new
name. That hint goes away when the blocks at the end of `zsh/functions.zsh` and
`bash/functions.bash` are deleted.

### Adding one

Add `bin/kb-<command>` with line 2 `# kb-<command>: summary` and a usage comment
below it; `test/smoke.sh` checks the format. Use `lib/kb.sh` for `kb_have`,
`kb_first`, and `kb_os`, and keep scripts bash 3.2 compatible (macOS
`/bin/bash`). Machine-only commands go in `~/.zshrc.d/*.zsh` (or
`~/.bashrc.d/*.bash`) as functions with the same comment format, and `kb-help`
lists them too.

## Shell and git settings

- Prompt: `[21:04:05.123 | Last cmd: 2.481s] user@host:~/repo (branch) [exit 1]$`.
  It times the whole command line, shows the exit status when a command fails,
  and reads the git branch without running git.
- History: 100k entries, timestamps, no duplicates, saved after every command.
- Completion and keys: case-insensitive Tab completion; Up/Down search history
  for what's typed. bash reads `inputrc`; zsh's equivalents are in
  `zsh/completion.zsh` and `zsh/keys.zsh` (emacs keys, even with `EDITOR=vim`).
- fzf: Ctrl-R history, Ctrl-T files, Alt-C directories.
- Startup is about 0.3s in bash and well under 0.1s in zsh, even with nvm, rbenv, and mise; slow init scripts are
  cached and Windows PATH entries are skipped on WSL.
- git: `pull.ff=only`, `fetch.prune`, histogram diffs, `zdiff3` conflicts,
  `rerere`, `rebase.autoSquash/autoStash/updateRefs`. Needs git 2.38+.

## How it fits together

| File in `$HOME`        | What it is |
| ---------------------- | ---------- |
| `~/.zshenv`            | Local stub that sources `zsh/zshenv.zsh` (kb- commands on PATH in every zsh) |
| `~/.zshrc`             | Local stub that sources `zsh/init.zsh`; lines it had before install are kept below |
| `~/.zshrc.d/*.zsh`     | Machine-only zsh settings and commands (work aliases). Not in the repo |
| `~/.bashrc`            | Local stub that sources `bash/init.bash` |
| `~/.bashrc.d/*.bash`   | Machine-only bash settings and commands. Not in the repo |
| `~/.gitconfig`         | Local file that includes `git/config` first, then identity and credentials |
| `~/.config/git/ignore` | Symlink to `git/ignore` |
| `~/.inputrc`           | Symlink to `inputrc` |
| `~/.vimrc`             | Symlink to `vim/vimrc` |

`~/.zshrc`, `~/.bashrc`, and `~/.gitconfig` are real files, not symlinks, so
installers that append to them and `git config --global` write to this machine
only.

## Requirements

zsh 5.3+ for the zsh config. Bash 4.4+ for the bash interactive config (bash 5 for prompt timing); the `kb-`
scripts also run on macOS's bash 3.2. `install.sh --tools` installs bash 5 on
macOS.

## Test

```sh
test/smoke.sh    # installs into a throwaway $HOME, runs the kb- commands, drives interactive zsh and bash
```

CI runs it with shellcheck on Ubuntu and macOS. shellcheck doesn't read zsh, so
the smoke test checks `zsh/*.zsh` with `zsh -n` instead.
