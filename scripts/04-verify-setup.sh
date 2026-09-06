#!/usr/bin/env bash
set -Eeuo pipefail

readonly PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0
warnings=0

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Usage: 04-verify-setup.sh

Read-only checks for the Fedora package, configuration, service, and session
baseline. Run it from the target graphical session after Stow is applied.
EOF
  exit 0
fi

check_command() {
  local command_name="$1"
  if command -v "$command_name" >/dev/null 2>&1; then
    printf 'PASS command %-24s %s\n' "$command_name" "$(command -v "$command_name")"
  else
    printf 'FAIL command %-24s missing\n' "$command_name"
    ((failures+=1))
  fi
}

warn_command() {
  local command_name="$1"
  if command -v "$command_name" >/dev/null 2>&1; then
    printf 'PASS optional %-22s %s\n' "$command_name" "$(command -v "$command_name")"
  else
    printf 'WARN optional %-22s missing\n' "$command_name"
    ((warnings+=1))
  fi
}

check_link() {
  local target="$1" expected="$2"
  if [[ -L "$target" ]] && [[ "$(readlink -f "$target")" == "$expected" ]]; then
    printf 'PASS link %-29s\n' "$target"
  else
    printf 'FAIL link %-29s expected %s\n' "$target" "$expected"
    ((failures+=1))
  fi
}

printf 'Project: %s\n' "$PROJECT_DIR"
for command_name in niri noctalia ghostty stow git nvim tmux python3 fc-match xwayland-satellite; do check_command "$command_name"; done
for command_name in starship mise jj herdr opencode; do warn_command "$command_name"; done

printf '\nConfiguration\n'
check_link "$HOME/.config/niri/config.kdl" "$PROJECT_DIR/dotfiles/niri/.config/niri/config.kdl"
check_link "$HOME/.config/niri/auto-column-width.py" "$PROJECT_DIR/dotfiles/niri/.config/niri/auto-column-width.py"
check_link "$HOME/.config/noctalia/config.toml" "$PROJECT_DIR/dotfiles/noctalia/.config/noctalia/config.toml"
check_link "$HOME/.config/ghostty/config" "$PROJECT_DIR/dotfiles/ghostty/.config/ghostty/config"
check_link "$HOME/.config/tmux/tmux.conf" "$PROJECT_DIR/dotfiles/tmux/.config/tmux/tmux.conf"
check_link "$HOME/.bashrc" "$PROJECT_DIR/dotfiles/bash/.bashrc"
if [[ "$(fc-match -f '%{family}' 'JetBrainsMono Nerd Font' 2>/dev/null)" == *'JetBrainsMono Nerd Font'* ]]; then
  printf '%s\n' 'PASS JetBrainsMono Nerd Font available'
else
  printf '%s\n' 'FAIL JetBrainsMono Nerd Font missing'
  ((failures+=1))
fi

printf '\nSystem\n'
if rpm -q polkit >/dev/null 2>&1; then printf '%s\n' 'PASS polkit installed'; else printf '%s\n' 'FAIL polkit missing'; ((failures+=1)); fi
if systemctl is-active --quiet firewalld.service; then printf '%s\n' 'PASS firewalld active'; else printf '%s\n' 'WARN firewalld inactive'; ((warnings+=1)); fi
if systemctl is-active --quiet NetworkManager.service; then printf '%s\n' 'PASS NetworkManager active'; else printf '%s\n' 'WARN NetworkManager inactive'; ((warnings+=1)); fi
if systemctl is-active --quiet power-profiles-daemon.service || systemctl is-active --quiet tuned-ppd.service; then
  printf '%s\n' 'PASS power-profile backend active'
else
  printf '%s\n' 'WARN no active power-profile backend (Noctalia power profiles unavailable)'
  ((warnings+=1))
fi
if systemctl is-enabled --quiet fstrim.timer; then printf '%s\n' 'PASS fstrim timer enabled'; else printf '%s\n' 'WARN fstrim timer not enabled'; ((warnings+=1)); fi

printf '\nSession\n'
if [[ "${XDG_CURRENT_DESKTOP:-}" == *niri* || -n "${NIRI_SOCKET:-}" ]] ||
   systemctl --user is-active --quiet niri.service 2>/dev/null; then
  printf '%s\n' 'PASS Niri session detected'
else
  printf '%s\n' 'WARN Niri session not detected; run this from the graphical session'
  ((warnings+=1))
fi

if ((failures)); then
  printf '\n%d required check(s) failed; %d warning(s).\n' "$failures" "$warnings"
  exit 1
fi
printf '\nAll required checks passed; %d warning(s).\n' "$warnings"
