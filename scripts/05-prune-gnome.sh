#!/usr/bin/env bash
set -Eeuo pipefail

DRY_RUN=0
REMOVE_PACKAGES=0
ASSUME_YES=0

usage() {
  cat <<'EOF'
Usage: 05-prune-gnome.sh [options]

Stop unused GNOME background services while preserving GNOME applications,
polkit, the GNOME fallback, Noctalia, Nautilus, portals, and GVFS.

Options:
  --dry-run         Show the service and package plan without changing the system.
  --remove-packages Opt in to removing the unused GNOME packages as well.
  --yes             Accept the optional package-removal transaction without prompting.
  -h, --help        Show this help.
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --remove-packages) REMOVE_PACKAGES=1 ;;
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

readonly USER_SERVICE_PATTERNS=(
  evolution-source-registry.service
  evolution-calendar-factory.service
  evolution-addressbook-factory.service
  evolution-user-prompter.service
  evolution-alarm-notify.service
  tracker-miner-fs-3.service
  tracker-extract-3.service
)

for package in "${PROTECTED_PACKAGES[@]}"; do
  rpm -q "$package" >/dev/null 2>&1 || {
    printf 'Required protected package is missing: %s\n' "$package" >&2
    exit 1
  }
done

mapfile -t PRUNABLE_PACKAGES < <(
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

show_package_plan() {
  if ((${#PRUNABLE_PACKAGES[@]} == 0)); then
    printf '%s\n' 'No targeted GNOME packages are installed.'
    return
  fi

  printf 'Candidate packages: %s\n' "${PRUNABLE_PACKAGES[*]}"
  if package_plan=$("$DNF" remove --assumeno --setopt=clean_requirements_on_remove=False "${PRUNABLE_PACKAGES[@]}" 2>&1); then
    plan_status=0
  else
    plan_status=$?
  fi
  printf '%s\n' "$package_plan"
  if ((plan_status != 0)) && [[ "$package_plan" != *'Operation aborted'* ]]; then
    return "$plan_status"
  fi
}

if ((DRY_RUN)); then
  printf '%s\n' 'Protected packages:'
  printf '  %s\n' "${PROTECTED_PACKAGES[@]}"
  printf '%s\n' 'PackageKit will be stopped only if active and remains available for on-demand GNOME Software use.'
  printf '%s\n' 'EDS and Tracker user services will be masked when present.'
  if ((REMOVE_PACKAGES)); then
    show_package_plan
  else
    printf '%s\n' 'Package removal is disabled; applications remain installed.'
  fi
  exit 0
fi

sudo -v

if ((REMOVE_PACKAGES)); then
  if ((${#PRUNABLE_PACKAGES[@]})); then
    dnf_args=(remove --setopt=clean_requirements_on_remove=False)
    ((ASSUME_YES)) && dnf_args+=(-y)
    sudo "$DNF" "${dnf_args[@]}" "${PRUNABLE_PACKAGES[@]}"
  else
    printf '%s\n' 'No targeted GNOME packages are installed.'
  fi
elif ((ASSUME_YES)); then
  printf '%s\n' '--yes only applies with --remove-packages.' >&2
  exit 2
fi

if systemctl is-active --quiet packagekit.service; then
  sudo systemctl stop packagekit.service
  printf '%s\n' 'Stopped active PackageKit; it remains available for on-demand GNOME Software use.'
else
  printf '%s\n' 'PackageKit is inactive; left available for on-demand GNOME Software use.'
fi

if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" && -S "/run/user/$(id -u)/bus" ]]; then
  export XDG_RUNTIME_DIR="/run/user/$(id -u)"
  export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
fi

if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
  for unit in "${USER_SERVICE_PATTERNS[@]}"; do
    if systemctl --user cat "$unit" >/dev/null 2>&1; then
      systemctl --user mask --now "$unit"
      printf 'Masked user service: %s\n' "$unit"
    fi
  done

  if pgrep -x goa-daemon >/dev/null 2>&1; then
    pkill -x goa-daemon
    printf '%s\n' 'Stopped active GNOME Online Accounts daemon; it remains available for on-demand use.'
  fi
else
  printf '%s\n' 'No user D-Bus session detected; run this script again from the graphical session to mask user services.'
fi

for package in "${PROTECTED_PACKAGES[@]}"; do
  rpm -q "$package" >/dev/null 2>&1 || {
    printf 'Protected package disappeared unexpectedly: %s\n' "$package" >&2
    exit 1
  }
done

printf '%s\n' 'GNOME service cleanup complete; applications and polkit were preserved.'
