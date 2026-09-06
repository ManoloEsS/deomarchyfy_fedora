#!/usr/bin/env bash
set -Eeuo pipefail

DRY_RUN=0
ASSUME_YES=0

usage() {
  cat <<'EOF'
Usage: 05-prune-gnome.sh [options]

Remove unused GNOME software-management, indexing, and GUI components while
preserving the GNOME fallback, polkit, Noctalia, Nautilus, portals, and GVFS.

Options:
  --dry-run        Show the package transaction without changing the system.
  --yes            Accept the package transaction without prompting.
  -h, --help       Show this help.
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --yes) ASSUME_YES=1 ;;
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
elif command -v dnf >/dev/null 2>&1; then
  DNF=dnf
else
  printf '%s\n' 'Neither dnf5 nor dnf is installed.' >&2
  exit 1
fi

readonly PROTECTED_PACKAGES=(
  polkit polkit-libs gnome-keyring nautilus
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome
  gdm gnome-shell gnome-control-center
)

for package in "${PROTECTED_PACKAGES[@]}"; do
  rpm -q "$package" >/dev/null 2>&1 || {
    printf 'Required protected package is missing: %s\n' "$package" >&2
    exit 1
  }
done

mapfile -t REMOVE_PACKAGES < <(
  rpm -qa --qf '%{NAME}\n' |
    while IFS= read -r package; do
      case "$package" in
        PackageKit*|gnome-software*|gnome-calendar|gnome-contacts|\
        evolution|evolution-ews-*|tracker|tracker-*|tracker3*)
          printf '%s\n' "$package"
          ;;
      esac
    done |
    sort -u
)

if ((DRY_RUN)); then
  printf '%s\n' 'Protected packages:'
  printf '  %s\n' "${PROTECTED_PACKAGES[@]}"
  if ((${#REMOVE_PACKAGES[@]})); then
    printf 'Candidate packages: %s\n' "${REMOVE_PACKAGES[*]}"
    "$DNF" remove --assumeno --setopt=clean_requirements_on_remove=False "${REMOVE_PACKAGES[@]}"
  else
    printf '%s\n' 'No targeted GNOME packages are installed.'
  fi
  printf '%s\n' 'PackageKit will be masked only if it remains installed after removal.'
  printf '%s\n' 'Evolution Data Server services will be masked while their GNOME fallback libraries remain installed.'
  exit 0
fi

sudo -v

if ((${#REMOVE_PACKAGES[@]})); then
  dnf_args=(remove --setopt=clean_requirements_on_remove=False)
  ((ASSUME_YES)) && dnf_args+=(-y)
  sudo "$DNF" "${dnf_args[@]}" "${REMOVE_PACKAGES[@]}"
else
  printf '%s\n' 'No targeted GNOME packages are installed.'
fi

if rpm -q PackageKit >/dev/null 2>&1; then
  sudo systemctl mask --now packagekit.service
  printf '%s\n' 'PackageKit remains installed and is now masked.'
else
  printf '%s\n' 'PackageKit is not installed; no PackageKit service remains to mask.'
fi

if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" && -S "/run/user/$(id -u)/bus" ]]; then
  export XDG_RUNTIME_DIR="/run/user/$(id -u)"
  export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
fi

if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
  for unit in \
    evolution-source-registry.service \
    evolution-calendar-factory.service \
    evolution-addressbook-factory.service \
    evolution-user-prompter.service \
    evolution-alarm-notify.service; do
    if systemctl --user cat "$unit" >/dev/null 2>&1; then
      systemctl --user mask --now "$unit"
    fi
  done
else
  printf '%s\n' 'No user D-Bus session detected; run the script again from the graphical session to mask EDS services.'
fi

for package in "${PROTECTED_PACKAGES[@]}"; do
  rpm -q "$package" >/dev/null 2>&1 || {
    printf 'Protected package disappeared unexpectedly: %s\n' "$package" >&2
    exit 1
  }
done

printf '%s\n' 'GNOME cleanup complete; polkit, GNOME fallback dependencies, Noctalia dependencies, Nautilus, portals, and GVFS were preserved.'
