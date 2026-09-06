# Operating System

## Decision

Use **Fedora Workstation** as the base operating system, retaining GNOME and
GDM as the supported system defaults while selecting Niri as the daily Wayland
session.

## Why Fedora Workstation

- Fedora provides a current, supported mutable Linux workstation with a strong
  default security and desktop integration baseline.
- GDM already discovers and launches packaged Wayland sessions, so the login
  path stays simple while Niri is evaluated.
- Fedora packages Niri, Noctalia, GNU Stow, portals, and the system services
  required by Noctalia.
- SELinux enforcing, firewalld, PipeWire, NetworkManager, and GNOME portals are
  useful defaults rather than integration that should be replaced.
- A regular Fedora installation makes recovery through GNOME, a TTY, and the
  rescue environment straightforward.

## What This Replaces

This project does not attempt to reproduce Omarchy or the Arch/Hyprland setup
wholesale.

- Niri replaces Hyprland as the compositor and window manager.
- Noctalia provides the bar, launcher, notifications, lock screen, idle
  behavior, wallpaper, OSD, and control center.
- GDM remains the display manager; greetd is not added.
- Bash contains only the portable shell workflow.
- GNU Stow manages reviewed user configuration.
- Hyprland APIs, `hyprctl`, Hyprland Lua modules, and Hyprland-only helpers are
  not runtime dependencies.

## Security and System Boundaries

- Keep Secure Boot enabled where the hardware supports it.
- Keep SELinux enforcing and investigate denials rather than disabling it.
- Use firewalld's default zone and allow-list services explicitly.
- Use PipeWire and WirePlumber as Fedora's user-session audio stack.
- Use NetworkManager and BlueZ for Noctalia's network and Bluetooth controls.
- Use GDM's normal authentication and session selection.
- Use one polkit authentication agent. Do not run duplicate agents without a
  demonstrated need.

## Tradeoffs

Fedora's stable release cadence is less current than a rolling Arch system for
some desktop software. Third-party COPRs add software availability but also
add trust and update surface. The package script therefore keeps COPR use
explicit and limited to Ghostty and the optional Starship package.

Niri's scrolling-column model is not a drop-in replacement for every Hyprland
layout feature. The migration keeps the useful focus, move, workspace, resize,
fullscreen, floating, and screenshot behavior and documents unsupported
Hyprland-specific features instead of adding fragile emulation.
