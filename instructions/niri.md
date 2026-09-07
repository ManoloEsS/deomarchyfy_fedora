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

The Niri binds provide Omarchy-style universal clipboard shortcuts through
`wtype`. Browser windows receive the browser-standard `Ctrl+C/V/X`; terminals
and other applications receive Omarchy's `Ctrl+Insert`, `Shift+Insert`, and
`Ctrl+X` sequences. Noctalia owns clipboard history, including images, and
opens it with `Super+Ctrl+V` or its bar widget.

## Hyprland Mapping

| Existing behavior | Niri implementation |
| --- | --- |
| Hyprland scrolling layout | Niri's native scrolling columns |
| Gaps and active gradient border | Niri layout gaps and amber focus ring |
| Workspace monitor rules | Niri dynamically manages workspaces across outputs |
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

The target hardware mapping is:

- Acer ED340CU at `0x0`, using native `3440x1440@119.998` with scale `1`
- Samsung LF24T35 at `-1080x0`, rotated 90 degrees, using native
  `1920x1080@74.973` with scale `1`

The higher refresh rates were tested live and retained because both displays
accepted them without changing their native pixel mapping. Scale `1` avoids
fractional scaling and keeps text at one logical pixel per display pixel. VRR is
left disabled because the desktop uses mixed fixed refresh rates and the setting
does not improve static text or image clarity.

The output names and modes are hardware-specific defaults, not universal
identifiers. If this configuration is reused on different hardware, inspect
identifiers and available modes with `niri msg outputs` before copying these
blocks.

## Visual Defaults

- Niri compositor blur is disabled with `blur { passes 0 }` to avoid softening
  window edges and text.
- Niri uses native output resolutions, scale `1`, and no output transform on the
  Acer; the Samsung uses only the required 90-degree rotation.
- Niri window borders are disabled; the active focus ring uses amber and the
  inactive ring uses gray.
- Ghostty uses JetBrainsMono Nerd Font at 12 px, 95% background opacity, and
  its own background blur setting. This is terminal styling and does not alter
  monitor resolution or compositor scaling.
- Noctalia shell animations are disabled in the reviewed baseline.

## Useful Commands

```bash
niri msg outputs
niri msg workspaces
niri msg windows
niri msg layers
niri msg action load-config-file
niri msg action toggle-overview
niri msg action quit
```

The Niri configuration reference is at
`https://niri-wm.github.io/niri/Configuration%3A-Introduction.html`.
