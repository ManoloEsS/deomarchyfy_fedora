#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

DRY_RUN=0
WITH_GHOSTTY=1
WITH_STARSHIP=0
WITH_SYNC_TOOLS=0
NO_UPGRADE=0

readonly NERD_FONT_VERSION='v3.5.1'
readonly NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/JetBrainsMono.tar.xz"
readonly NERD_FONT_SHA256='04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf'
readonly NERD_FONT_DIR="${HOME}/.local/share/fonts/JetBrainsMono Nerd Font"

usage() {
  cat <<'EOF'
Usage: 01-install-packages.sh [options]

Options:
  --dry-run        Print transactions without changing the system.
  --no-ghostty     Do not enable the Ghostty COPR or install Ghostty.
  --with-starship  Enable the Starship COPR and install Starship.
  --with-sync-tools Install rsync and inotify-tools for the optional rsw helper.
  --no-upgrade     Skip the initial dnf upgrade transaction.
  -h, --help       Show this help.
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --no-ghostty) WITH_GHOSTTY=0 ;;
    --with-starship) WITH_STARSHIP=1 ;;
    --with-sync-tools) WITH_SYNC_TOOLS=1 ;;
    --no-upgrade) NO_UPGRADE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ "${EUID}" -eq 0 ]]; then
  printf '%s\n' 'Run this script as the normal user, not root.' >&2
  exit 1
fi

if command -v dnf5 >/dev/null 2>&1; then
  DNF=dnf5
else
  DNF=dnf
fi

ADDITIONAL_PACKAGES=(
  niri noctalia stow
  git neovim tmux python3 fontconfig
  # Required by the Niri universal-clipboard helper.
  fzf bat eza zoxide wtype
)

run_dnf() {
  local -a args=("$@")
  if ((DRY_RUN)); then
    printf '+ sudo %q' "$DNF"
    printf ' %q' "${args[@]}"
    printf '\n'
  else
    sudo "$DNF" "${args[@]}"
  fi
}

install_jetbrains_nerd_font() {
  if ((DRY_RUN)); then
    printf '+ install JetBrainsMono Nerd Font %s into %q\n' "$NERD_FONT_VERSION" "$NERD_FONT_DIR"
    return
  fi

  if [[ "$(fc-match -f '%{family}' 'JetBrainsMono Nerd Font' 2>/dev/null)" == *'JetBrainsMono Nerd Font'* ]]; then
    printf '%s\n' 'JetBrainsMono Nerd Font is already installed.'
    return
  fi

  (
    temp_dir="$(mktemp -d)"
    trap 'rm -rf -- "$temp_dir"' EXIT
    archive="${temp_dir}/JetBrainsMono.tar.xz"

    curl --fail --location --retry 3 --silent --show-error "$NERD_FONT_URL" --output "$archive"
    printf '%s  %s\n' "$NERD_FONT_SHA256" "$archive" | sha256sum --check --status
    mkdir -p "$NERD_FONT_DIR"
    tar --extract --xz --file="$archive" --directory="$NERD_FONT_DIR"
  )

  fc-cache -f "$NERD_FONT_DIR"
  printf 'Installed JetBrainsMono Nerd Font %s.\n' "$NERD_FONT_VERSION"
}

enable_copr() {
  local repo="$1"
  if ! command -v dnf >/dev/null 2>&1 && ! command -v dnf5 >/dev/null 2>&1; then
    if ((DRY_RUN)); then
      printf '+ sudo dnf copr enable -y %q\n' "$repo"
      return
    fi
    printf 'Neither dnf nor dnf5 is available.\n' >&2
    exit 1
  fi

  if ! command -v copr >/dev/null 2>&1 && ! "$DNF" copr --help >/dev/null 2>&1; then
    if [[ "$DNF" == dnf5 ]]; then
      run_dnf install -y dnf5-plugins
    else
      run_dnf install -y dnf-plugins-core
    fi
  fi

  if ((DRY_RUN)); then
    printf '+ sudo %q copr enable -y %q\n' "$DNF" "$repo"
  else
    sudo "$DNF" copr enable -y "$repo"
  fi
}

if ((NO_UPGRADE == 0)); then
  run_dnf upgrade --refresh -y
fi

if ((WITH_GHOSTTY)); then
  enable_copr scottames/ghostty
  ADDITIONAL_PACKAGES+=(ghostty)
fi

if ((WITH_STARSHIP)); then
  enable_copr atim/starship
  ADDITIONAL_PACKAGES+=(starship)
fi

if ((WITH_SYNC_TOOLS)); then
  ADDITIONAL_PACKAGES+=(rsync inotify-tools)
fi

printf 'Installing Fedora packages from %s:\n' "$PROJECT_DIR"
run_dnf install -y "${ADDITIONAL_PACKAGES[@]}"
install_jetbrains_nerd_font
