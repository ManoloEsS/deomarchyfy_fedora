# Desktop Shell

## Decision

Use **Noctalia v5+** as the desktop shell for Niri.

Niri owns windows, outputs, input, layout, compositor animations, and global
keybindings. Noctalia owns the bar, launcher, notifications, lock screen, idle
actions, wallpaper, OSD, control center, and shell appearance.

## Session Ownership

```text
GDM -> Niri -> Noctalia
```

Niri starts Noctalia from its compositor configuration. Noctalia is not
launched from `.bashrc`, a user shell profile, or a second autostart mechanism.

## Noctalia Responsibilities

- Bar and workspace display
- Application launcher and calculator
- Notifications and Do Not Disturb
- Lock screen and idle lock/screen-off actions
- Wallpaper and optional overview backdrop
- Audio, microphone, brightness, media, network, Bluetooth, and power controls
- Screenshot UI and system OSDs

These controls still depend on the underlying Fedora services. Noctalia does
not replace PipeWire, NetworkManager, BlueZ, UPower, or the active Fedora
power-profile backend (`power-profiles-daemon` or `tuned-ppd`).

## Managed Profile

The Noctalia Stow package contains the reference machine's reviewed shell
configuration, monitor-specific bar and lock-screen layout, and wallpaper. The
configuration was promoted from the active GUI choices with:

```bash
noctalia config export merged
```

Noctalia writes later GUI changes to `~/.local/state/noctalia/settings.toml`.
That file is linked to the Noctalia Stow package, so GUI changes appear directly
in the repository for review. Only `settings.toml` is versioned from the state
directory; runtime history, encrypted clipboard data, downloaded catalogs,
plugin source caches, and internal state remain untracked.

## Avoid Duplicate Owners

Do not add Waybar, Mako, Walker, fuzzel, hyprlock, hypridle, hyprsunset, or a
second polkit agent for responsibilities already owned by Noctalia.

## Validation

Before styling the shell, validate and test:

1. `noctalia config validate`
2. One Noctalia process after a fresh Niri login
3. Notifications, launcher, bar, audio, brightness, network, Bluetooth,
   wallpaper, screenshots, lock, screen-off, and wake
4. Logout to GDM and a fallback GNOME login
5. TTY recovery with Noctalia stopped if the shell fails

## Sources

- [Noctalia](https://docs.noctalia.dev/noctalia/)
- [Noctalia installation](https://docs.noctalia.dev/noctalia/getting-started/installation/)
- [Noctalia Niri integration](https://docs.noctalia.dev/noctalia/compositor-settings/niri/)
- [Niri important software](https://niri-wm.github.io/niri/Important-Software.html)
