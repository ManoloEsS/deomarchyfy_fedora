# Noctalia Runtime

This is a manual test runbook. Run it after applying the Stow package and
logging into Niri through GDM.

## Configuration

```bash
noctalia config validate
pgrep -af noctalia
```

There should be one shell process. GUI-managed settings live under
`~/.local/state/noctalia/` and are intentionally outside this repository.

## Shell and IPC

Test the core surfaces from Niri:

```bash
noctalia msg panel-toggle launcher
noctalia msg panel-toggle control-center
noctalia msg window-switcher
noctalia msg session lock
```

Test audio and brightness with the media keys and verify the underlying
services:

```bash
wpctl status
systemctl --user --no-pager status pipewire wireplumber
```

## Power Profiles

Noctalia reads the standard UPower power-profile interface. Fedora may provide
it through `power-profiles-daemon` or TuneD's `tuned-ppd` compatibility daemon:

```bash
busctl --system introspect org.freedesktop.UPower.PowerProfiles \
  /org/freedesktop/UPower/PowerProfiles
noctalia msg power-cycle
```

If the D-Bus service is unavailable, Noctalia continues to run but its
power-profile control is unavailable. The Fedora power-management defaults
should not be replaced solely to provide this optional control.

## Lock and Idle

1. Press `Super+Ctrl+L` and authenticate.
2. Wait past the five-minute lock timeout, then authenticate.
3. Wait past the screen-off timeout and wake the display.
4. Test suspend and resume from the Noctalia session controls.
5. Confirm that the screen is locked after suspend.

## Monitor and Recovery

```bash
niri msg outputs
niri msg layers
journalctl --user -b --unit=noctalia.service --no-pager
```

Noctalia may be launched by the Niri config rather than a dedicated user unit;
in that case inspect `journalctl --user -b` and the GDM/Niri session logs.

If the shell fails, use a TTY, stop the process, and log into GNOME from GDM:

```bash
pkill -x noctalia || true
```

Do not add a second bar, notification daemon, lock screen, or idle daemon as a
first response to a Noctalia failure. Find the failed service or configuration
entry first.
