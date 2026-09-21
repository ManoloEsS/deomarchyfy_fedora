#!/usr/bin/env bash
set -Eeuo pipefail

readonly PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0
warnings=0

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Usage: 04-verify-setup.sh

Read-only checks for the Fedora package, configuration, service, monitor, and
session baseline. Run it before the first Niri login to validate links and
config parsers, then re-run it inside the Niri session for the monitor and
effective-wallpaper checks.
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

check_niri_version() {
  local version major minor
  if ! version="$(niri --version 2>/dev/null)"; then
    printf '%s\n' 'FAIL Niri version unavailable'
    ((failures+=1))
    return
  fi

  version="${version#niri }"
  if [[ ! "$version" =~ ^([0-9]+)\.([0-9]+) ]]; then
    printf 'FAIL Niri version unrecognized: %s\n' "$version"
    ((failures+=1))
    return
  fi

  major=$((10#${BASH_REMATCH[1]}))
  minor=$((10#${BASH_REMATCH[2]}))
  if ((major > 26 || (major == 26 && minor >= 4))); then
    printf 'PASS Niri version %-20s\n' "$version"
  else
    printf 'FAIL Niri version %-20s requires 26.04 or newer\n' "$version"
    ((failures+=1))
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

check_readable_file() {
  local file="$1" label="$2"
  if [[ -r "$file" ]]; then
    printf 'PASS file %-29s\n' "$label"
  else
    printf 'FAIL file %-29s unreadable or missing: %s\n' "$label" "$file"
    ((failures+=1))
  fi
}

check_noctalia_config() {
  if noctalia config validate; then
    printf '%s\n' 'PASS Noctalia configuration valid'
  else
    printf '%s\n' 'FAIL Noctalia configuration invalid'
    ((failures+=1))
  fi
}

check_effective_wallpaper() {
  local wallpaper
  if wallpaper="$(noctalia msg wallpaper-get 2>/dev/null)" && [[ -r "$wallpaper" ]]; then
    printf 'PASS wallpaper %-24s %s\n' 'effective' "$wallpaper"
  else
    printf '%s\n' 'FAIL wallpaper effective value is unreadable or unavailable'
    ((failures+=1))
  fi
}

output_block() {
  local connector="$1" line block='' in_block=0
  while IFS= read -r line; do
    if [[ "$line" == *"(${connector})" ]]; then
      in_block=1
      block="$line"
      continue
    fi
    if ((in_block)) && [[ "$line" == Output\ * ]]; then
      break
    fi
    if ((in_block)); then
      block+=$'\n'"$line"
    fi
  done <<<"$outputs"
  printf '%s' "$block"
}

check_reference_outputs() {
  local acer samsung
  if ! outputs="$(niri msg outputs 2>/dev/null)"; then
    printf '%s\n' 'WARN monitor state unavailable from niri msg outputs'
    ((warnings+=1))
    return
  fi

  acer="$(output_block DP-1)"
  samsung="$(output_block HDMI-A-1)"

  if [[ "$acer" == *'Acer Technologies ED340CU'* &&
        "$acer" == *'Current mode: 3440x1440 @ 119.998 Hz'* &&
        "$acer" == *'Logical position: 0, 0'* &&
        "$acer" == *'Scale: 1'* ]]; then
    printf '%s\n' 'PASS Acer monitor reference mode'
  else
    printf '%s\n' 'WARN Acer reference mode differs; review niri msg outputs'
    ((warnings+=1))
  fi

  if [[ "$samsung" == *'Samsung Electric Company'* &&
        "$samsung" == *'Current mode: 1920x1080 @ 74.973 Hz'* &&
        "$samsung" == *'Logical position: -1080, 0'* &&
        "$samsung" == *'Scale: 1'* &&
        "$samsung" == *'Transform: 90'* ]]; then
    printf '%s\n' 'PASS Samsung monitor reference mode'
  else
    printf '%s\n' 'WARN Samsung reference mode differs; review niri msg outputs'
    ((warnings+=1))
  fi
}

printf 'Project: %s\n' "$PROJECT_DIR"
for command_name in niri noctalia ghostty zen-browser stow git nvim tmux python3 fc-match xwayland-satellite wtype; do check_command "$command_name"; done
for command_name in starship mise jj herdr opencode; do warn_command "$command_name"; done
check_niri_version

printf '\nConfiguration\n'
check_link "$HOME/.config/niri/config.kdl" "$PROJECT_DIR/dotfiles/niri/.config/niri/config.kdl"
check_link "$HOME/.config/niri/auto-column-width.py" "$PROJECT_DIR/dotfiles/niri/.config/niri/auto-column-width.py"
check_link "$HOME/.config/noctalia/config.toml" "$PROJECT_DIR/dotfiles/noctalia/.config/noctalia/config.toml"
check_link "$HOME/.config/noctalia/wallpapers/shaded.png" "$PROJECT_DIR/dotfiles/noctalia/.config/noctalia/wallpapers/shaded.png"
check_link "$HOME/.local/state/noctalia/settings.toml" "$PROJECT_DIR/dotfiles/noctalia/.local/state/noctalia/settings.toml"
check_readable_file "$HOME/.config/noctalia/wallpapers/shaded.png" 'Noctalia wallpaper'
check_noctalia_config
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
niri_session=0
if [[ "${XDG_CURRENT_DESKTOP:-}" == *niri* || -n "${NIRI_SOCKET:-}" ]] ||
   systemctl --user is-active --quiet niri.service 2>/dev/null; then
  printf '%s\n' 'PASS Niri session detected'
  niri_session=1
else
  printf '%s\n' 'WARN Niri session not detected; run this from the graphical session'
  ((warnings+=1))
fi

if ((niri_session)); then
  check_reference_outputs
  check_effective_wallpaper
else
  printf '%s\n' 'WARN effective Noctalia wallpaper unavailable outside a Niri session'
  ((warnings+=1))
fi

if ((failures)); then
  printf '\n%d required check(s) failed; %d warning(s).\n' "$failures" "$warnings"
  exit 1
fi
printf '\nAll required checks passed; %d warning(s).\n' "$warnings"
