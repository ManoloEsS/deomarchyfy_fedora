# Niri

## Configuration

The Stow package installs `~/.config/niri/config.kdl`. Niri live-reloads this
file, and it can parse it without starting a session:

```bash
niri validate
```

Use `niri msg outputs` inside Niri to confirm connector names, modes, scale,
and logical positions. The checked-in monitor rules use the manufacturer/model
names from the current Hyprland setup and should be treated as hardware
defaults, not universal identifiers.

The configuration starts a small IPC watcher that expands a lone tiling column
to the available width and sets two tiling columns to `50%` each. It ignores
floating windows and leaves layouts with three or more columns unchanged. This
behavior is automated because Niri's built-in width settings do not resize
existing columns when the column count changes.

## Hyprland Mapping

| Existing behavior | Niri implementation |
| --- | --- |
| Hyprland scrolling layout | Niri's native scrolling columns |
| Gaps and active gradient border | Niri layout gaps and cyan/green focus ring |
| Workspace monitor rules | Named workspaces with `open-on-output` |
| Hyprland startup hook | `spawn-at-startup "noctalia"` |
| `hyprctl` terminal helper | Direct Ghostty/foot launcher |
| Focus and move directions | Niri focus/move column/window actions |
| Window resize | Niri column and window width/height actions |
| Floating toggle | Niri floating-layout toggle |
| Master layout | Niri column sizing and overview; no master emulation |
| Scratchpad | No direct equivalent; use a named workspace or floating window |
| Window groups | Niri tabbed columns |
| Pinning | No direct equivalent; use a named workspace or floating window |
| Synthetic Ctrl+C/V/X | Removed; applications receive normal key events |
| Single-window square aspect | Removed; use application or window-specific sizing |

Niri does not need a separate layout mode toggle for the selected workflow.
`Super+R` cycles the reviewed column-width presets, while overview provides a
quick view of all workspaces and windows.

## Monitor Defaults

The current hardware mapping is:

- Acer ED340CU at `0x0`
- Samsung LF24T35 at `-1080x0`, rotated 90 degrees
- Workspace 1 opens on Samsung
- Workspace 2 opens on Acer

If a monitor does not match, comment out the corresponding `output` block and
use Niri's automatic placement until the exact identifier is confirmed.

## Useful Commands

```bash
niri msg outputs
niri msg workspaces
niri msg windows
niri msg layers
niri msg action reload-config
niri msg action toggle-overview
niri msg action quit
```

The Niri configuration reference is at
`https://niri-wm.github.io/niri/Configuration%3A-Introduction.html`.
