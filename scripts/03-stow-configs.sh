#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
readonly DOTFILES_DIR="${PROJECT_DIR}/dotfiles"

DRY_RUN=0
RESTOW=0
REPLACE_BASH=0
REPLACE_NIRI=0
PACKAGES=(bash ghostty herdr niri noctalia starship tmux)

usage() {
  cat <<'EOF'
Usage: 03-stow-configs.sh [options]

Options:
  --dry-run        Show the Stow plan without changing the home directory.
  --restow         Rebuild links for the selected packages.
  --replace-bash   Back up regular Bash files before Stowing the Bash package.
  --replace-niri   Back up an existing regular Niri config before Stowing Niri.
  --packages LIST  Comma-separated package list.
  -h, --help       Show this help.
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --restow) RESTOW=1 ;;
    --replace-bash) REPLACE_BASH=1 ;;
    --replace-niri) REPLACE_NIRI=1 ;;
    --packages) shift; [[ $# -gt 0 ]] || { usage >&2; exit 2; }; IFS=',' read -r -a PACKAGES <<<"$1" ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ "${EUID}" -eq 0 ]]; then
  printf '%s\n' 'Run this script as the normal user, not root.' >&2
  exit 1
fi

command -v stow >/dev/null 2>&1 || {
  printf '%s\n' 'stow is not installed. Run scripts/01-install-packages.sh first.' >&2
  exit 1
}

for package in "${PACKAGES[@]}"; do
  [[ -d "${DOTFILES_DIR}/${package}" ]] || {
    printf 'Unknown Stow package: %s\n' "$package" >&2
    exit 1
  }
done

backup_dir="${HOME}/.local/state/deomarchyfy-fedora/backups/$(date +%Y%m%d-%H%M%S)"
backup_regular_file() {
  local file="$1"
  local target="${HOME}/${file}"
  local destination="${backup_dir}/${file}"

  if [[ -f "$target" && ! -L "$target" ]]; then
    if ((DRY_RUN)); then
      printf '+ backup %s -> %s\n' "$target" "$destination"
    else
      mkdir -p "$(dirname -- "$destination")"
      mv -- "$target" "$destination"
    fi
  fi
}

if ((REPLACE_BASH)); then
  for file in .bashrc .bash_profile .profile .bash_aliases .bash_functions .inputrc; do
    backup_regular_file "$file"
  done
fi

if ((REPLACE_NIRI)); then
  backup_regular_file .config/niri/config.kdl
fi

stow_args=(--dir="$DOTFILES_DIR" --target="$HOME" --no-folding)
((RESTOW)) && stow_args+=(--restow)
((DRY_RUN)) && stow_args+=(--simulate --verbose=1)

printf 'Stowing: %s\n' "${PACKAGES[*]}"
stow "${stow_args[@]}" "${PACKAGES[@]}"

printf '%s\n' 'Configuration links applied.'
