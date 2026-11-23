# Prompt:  [21:04:05.123 | Last cmd: 2.481s] user@host:~/repo (main) [exit 1]$
#
# Timing uses PS0, which bash expands once per command line just before running
# it, and EPOCHREALTIME, so no DEBUG trap and no `date` subprocess per command.
# A DEBUG trap fires for every simple command, so `a; b` used to time only b.
# Needs bash 5; older bash shows the prompt without timing.

__prompt_git_branch() { # pure bash, no git subprocess; handles worktrees
  __prompt_branch=
  local dir=$PWD gitdir head
  while :; do
    if [ -f "$dir/.git" ]; then
      read -r gitdir <"$dir/.git"
      gitdir=${gitdir#gitdir: }
      case $gitdir in /*) ;; *) gitdir=$dir/$gitdir ;; esac
      break
    elif [ -d "$dir/.git" ]; then
      gitdir=$dir/.git
      break
    fi
    [ -z "$dir" ] && return
    dir=${dir%/*}
  done
  read -r head <"$gitdir/HEAD" 2>/dev/null || return
  case $head in
    ref:*) __prompt_branch=${head#ref: refs/heads/} ;;
    *) __prompt_branch=${head:0:10} ;; # detached HEAD
  esac
}

__prompt_command() {
  local status=$?
  history -a

  __prompt_time= __prompt_duration=
  if [ -n "${EPOCHREALTIME:-}" ]; then
    local now_us=${EPOCHREALTIME//[!0-9]/}
    printf -v __prompt_time '%(%H:%M:%S)T.%s' -1 "${now_us: -6:3}"
    if [ -n "${__prompt_start_us:-}" ]; then
      local ms=$(((now_us - __prompt_start_us) / 1000))
      if [ "$ms" -ge 60000 ]; then
        printf -v __prompt_duration 'Last cmd: %dm%02ds' $((ms / 60000)) $((ms % 60000 / 1000))
      elif [ "$ms" -ge 1000 ]; then
        printf -v __prompt_duration 'Last cmd: %d.%03ds' $((ms / 1000)) $((ms % 1000))
      else
        printf -v __prompt_duration 'Last cmd: %03dms' "$ms"
      fi
    fi
  else
    printf -v __prompt_time '%(%H:%M:%S)T' -1 2>/dev/null || __prompt_time=$(date +%H:%M:%S)
  fi
  unset __prompt_start_us

  # Show the exit status only for a command that ran, not for an empty Enter.
  __prompt_status=
  if [ -n "$__prompt_duration" ] && [ "$status" -ne 0 ]; then __prompt_status=" [exit $status]"; fi

  __prompt_git_branch
}

__prompt_setup() {
  local reset='\[\e[0m\]' red='\[\e[31m\]' green='\[\e[32m\]' yellow='\[\e[33m\]'
  local magenta='\[\e[35m\]' cyan='\[\e[36m\]' blue='\[\e[34m\]'
  local title='\[\e]0;\u@\h: \w\a\]'
  case $TERM in xterm* | rxvt* | screen* | tmux*) ;; *) title= ;; esac

  PS1="$title$cyan[\${__prompt_time}$reset\${__prompt_duration:+ | }$yellow\${__prompt_duration}$cyan]$reset "
  PS1+="$magenta\u@\h$reset:$green\w$reset"
  PS1+="\${__prompt_branch:+ $blue(\${__prompt_branch})$reset}"
  PS1+="$red\${__prompt_status}$reset\\$ "

  if [ -n "${EPOCHREALTIME:-}" ]; then
    # An array subscript is always evaluated, so this arithmetic assigns in the
    # current shell and the expansion prints nothing. (A substring offset is
    # skipped when the variable is unset, so ${x:0:$((...))} doesn't work.)
    # shellcheck disable=SC2016
    PS0='${__prompt_noop[$((__prompt_start_us = ${EPOCHREALTIME//[!0-9]/}, 0))]}'
  fi

  case ";${PROMPT_COMMAND:-};" in
    *";__prompt_command;"*) ;;
    *) PROMPT_COMMAND="__prompt_command${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
  esac
}
__prompt_setup
unset -f __prompt_setup
