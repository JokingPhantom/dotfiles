# Prompt:  [21:04:05.123 | Last cmd: 2.481s] user@host:~/repo (main) [exit 1]$
#
# Same prompt as bash/prompt.bash. preexec records when a command line starts,
# precmd times it with $EPOCHREALTIME; no subprocesses per prompt.

zmodload zsh/datetime
autoload -Uz add-zsh-hook
setopt PROMPT_SUBST

__prompt_git_branch() { # pure zsh, no git subprocess; handles worktrees
  __prompt_branch=
  local dir=$PWD gitdir head
  while :; do
    if [[ -f $dir/.git ]]; then
      read -r gitdir <"$dir/.git"
      gitdir=${gitdir#gitdir: }
      [[ $gitdir == /* ]] || gitdir=$dir/$gitdir
      break
    elif [[ -d $dir/.git ]]; then
      gitdir=$dir/.git
      break
    fi
    [[ -z $dir ]] && return
    dir=${dir%/*}
  done
  [[ -r $gitdir/HEAD ]] || return
  read -r head <"$gitdir/HEAD"
  case $head in
    ref:*) __prompt_branch=${head#ref: refs/heads/} ;;
    *) __prompt_branch=${head[1,10]} ;; # detached HEAD
  esac
  __prompt_branch=${__prompt_branch//\%/%%} # the prompt expands % escapes
}

__prompt_preexec() { __prompt_start=$EPOCHREALTIME; }

__prompt_precmd() {
  local st=$? now=$EPOCHREALTIME
  local -i ms # integer, so assigning milliseconds truncates the fraction
  strftime -s __prompt_time '%H:%M:%S' ${now%.*}
  __prompt_time+=.${${now#*.}[1,3]}

  __prompt_duration=
  if [[ -n ${__prompt_start:-} ]]; then
    ms=$(( (now - __prompt_start) * 1000 ))
    if (( ms >= 60000 )); then
      printf -v __prompt_duration 'Last cmd: %dm%02ds' $((ms / 60000)) $((ms % 60000 / 1000))
    elif (( ms >= 1000 )); then
      printf -v __prompt_duration 'Last cmd: %d.%03ds' $((ms / 1000)) $((ms % 1000))
    else
      printf -v __prompt_duration 'Last cmd: %03dms' $ms
    fi
  fi
  unset __prompt_start

  # Show the exit status only for a command that ran, not for an empty Enter.
  __prompt_status=
  if [[ -n $__prompt_duration ]] && (( st != 0 )); then __prompt_status=" [exit $st]"; fi

  __prompt_git_branch

  case $TERM in xterm* | rxvt* | screen* | tmux*) print -Pn '\e]0;%n@%m: %~\a' ;; esac
}

PROMPT='%F{cyan}[${__prompt_time}%f${__prompt_duration:+ | }%F{yellow}${__prompt_duration}%F{cyan}]%f '
PROMPT+='%F{magenta}%n@%m%f:%F{green}%~%f'
PROMPT+='${__prompt_branch:+ }%F{blue}${__prompt_branch:+(${__prompt_branch})}%f'
PROMPT+='%F{red}${__prompt_status}%f%(!.#.$) '

# First in line, so $? is still the command's status and timing excludes other hooks.
add-zsh-hook preexec __prompt_preexec
add-zsh-hook precmd __prompt_precmd
precmd_functions=(__prompt_precmd ${precmd_functions:#__prompt_precmd})
