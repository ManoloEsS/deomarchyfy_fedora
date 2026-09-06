#!/usr/bin/env bash
set -Eeuo pipefail

DRY_RUN=0
ENABLE_ZRAM=0
ENABLE_TAILSCALE=0
ENABLE_DOCKER=0
ENABLE_SSH=0
ENABLE_ACCOUNTS=0

usage() {
  cat <<'EOF'
Usage: 02-enable-services.sh [options]

Options:
  --dry-run                 Print actions without changing the system.
  --zram                    Install the reviewed zram-generator configuration.
  --tailscale               Enable tailscaled; authentication remains manual.
  --docker                  Enable Docker and add the user to its group.
  --ssh                     Enable Tailscale SSH; requires authenticated Tailscale.
  --accountsservice         Enable AccountsService if installed.
  -h, --help                Show this help.
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --zram) ENABLE_ZRAM=1 ;;
    --tailscale) ENABLE_TAILSCALE=1 ;;
    --docker) ENABLE_DOCKER=1 ;;
    --ssh) ENABLE_SSH=1 ;;
    --accountsservice) ENABLE_ACCOUNTS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ "${EUID}" -eq 0 ]]; then
  printf '%s\n' 'Run this script as the normal user, not root.' >&2
  exit 1
fi

if command -v dnf5 >/dev/null 2>&1; then DNF=dnf5; else DNF=dnf; fi

sudo_run() {
  if ((DRY_RUN)); then
    printf '+ sudo'
    printf ' %q' "$@"
    printf '\n'
  else
    sudo "$@"
  fi
}

enable_unit() {
  local unit="$1"
  sudo_run systemctl enable --now "$unit"
}

enable_power_profile_backend() {
  local unit
  for unit in power-profiles-daemon.service tuned-ppd.service; do
    if systemctl cat "$unit" >/dev/null 2>&1; then
      enable_unit "$unit"
      return
    fi
  done
  printf '%s\n' 'No power-profile backend found; leaving Fedora power management unchanged.'
}

if ((ENABLE_ZRAM)); then
  tmp_file="$(mktemp)"
  trap 'rm -f -- "$tmp_file"' EXIT
  printf '%s\n' '[zram0]' 'zram-size = ram / 2' 'compression-algorithm = zstd' >"$tmp_file"
  if [[ -e /etc/systemd/zram-generator.conf ]] && ! cmp -s "$tmp_file" /etc/systemd/zram-generator.conf; then
    printf '%s\n' '/etc/systemd/zram-generator.conf already exists and differs; refusing to replace it.' >&2
    exit 1
  fi
  sudo_run "$DNF" install -y zram-generator
  if [[ ! -e /etc/systemd/zram-generator.conf ]]; then
    sudo_run install -m 0644 "$tmp_file" /etc/systemd/zram-generator.conf
  fi
fi

enable_unit NetworkManager.service
enable_unit firewalld.service
sudo_run firewall-cmd --set-default-zone=home
enable_power_profile_backend
enable_unit fstrim.timer

if ((ENABLE_TAILSCALE)); then
  sudo_run "$DNF" install -y tailscale
  enable_unit tailscaled.service
  printf '%s\n' 'Run "sudo tailscale up --timeout=60s" separately to authenticate this machine.'
fi

if ((ENABLE_DOCKER)); then
  sudo_run "$DNF" install -y docker
  enable_unit docker.service
  sudo_run usermod -aG docker "$USER"
  printf '%s\n' 'Log out and back in before using Docker without sudo.'
fi

if ((ENABLE_ACCOUNTS)); then
  sudo_run "$DNF" install -y accountsservice
  enable_unit accounts-daemon.service
fi

if ((ENABLE_SSH)); then
  if ((DRY_RUN)); then
    sudo_run tailscale set --ssh
  else
    command -v tailscale >/dev/null 2>&1 || {
      printf '%s\n' 'Tailscale is not installed. Run --tailscale first.' >&2
      exit 1
    }
    if ! sudo tailscale status >/dev/null 2>&1; then
      printf '%s\n' 'Tailscale is not authenticated. Run "sudo tailscale up --timeout=60s", then rerun with --ssh.' >&2
      exit 1
    fi
    sudo_run tailscale set --ssh
  fi
fi

printf '%s\n' 'Service configuration complete.'
