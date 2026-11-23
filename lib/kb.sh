# Helpers sourced by bin/kb-* scripts. Keep compatible with bash 3.2 (macOS /bin/bash).

# kb_have NAME: is NAME on PATH? Skips Windows directories on WSL (/mnt/c/...),
# where every miss costs milliseconds. For Windows .exe tools use `command -v`.
kb_have() {
  local IFS=: dir
  for dir in $PATH; do
    case $dir in /mnt/[a-z]/*) continue ;; esac
    if [ -x "$dir/$1" ] && [ ! -d "$dir/$1" ]; then return 0; fi
  done
  return 1
}

# kb_first NAME...: print the first NAME that is installed (e.g. bat batcat).
kb_first() {
  local name
  for name in "$@"; do
    if kb_have "$name"; then printf '%s\n' "$name"; return 0; fi
  done
  return 1
}

# kb_os: macos, wsl, linux, or other.
kb_os() {
  case $(uname -s) in
    Darwin) echo macos ;;
    Linux) if grep -qi microsoft /proc/version 2>/dev/null; then echo wsl; else echo linux; fi ;;
    *) echo other ;;
  esac
}

# kb_gnu CMD: is CMD the GNU version (vs BSD/macOS)?
kb_gnu() { "$1" --version 2>/dev/null | grep -q GNU; }

kb_die() { printf '%s: %s\n' "${0##*/}" "$*" >&2; exit 1; }

# kb_package_runner: how to run a node package's binary in this project.
kb_package_runner() {
  if [ -f pnpm-lock.yaml ]; then echo "pnpm exec"
  elif [ -f yarn.lock ]; then echo "yarn"
  else echo "npx"
  fi
}
