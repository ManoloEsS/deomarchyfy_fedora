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
not replace PipeWire, NetworkManager, BlueZ, UPower, or
`power-profiles-daemon`.

## Minimal Profile

The initial configuration intentionally contains only the reviewed lock and
idle behavior:

```toml
[shell.animation]
enabled = false

[lockscreen]
enabled = true

[idle.behavior.lock]
enabled = true
timeout = 300
action = "lock"

[idle.behavior.screen-off]
enabled = true
timeout = 330
action = "screen_off"
```

Use Noctalia's GUI to explore widgets, themes, wallpaper, and optional
integrations after the default runtime is working. GUI-managed state under
`~/.local/state/noctalia/` is intentionally not managed by Stow.

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
