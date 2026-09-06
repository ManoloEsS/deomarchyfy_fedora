# deomarchyfy_fedora

A Fedora Workstation setup for a minimal Niri desktop with Noctalia, Ghostty,
and a focused Bash environment.

This is a separate project from the Arch/Hyprland setup in
`../deomarchyfy`. The two projects share portable dotfiles conceptually, but
the Fedora project has its own package and compositor configuration.

## Goals

- Start from Fedora Workstation with its normal GDM login path.
- Use Niri as the Wayland compositor and Noctalia as the desktop shell.
- Install the smallest useful desktop runtime before adding personal tools.
- Install Ghostty from a reviewed COPR, not from an unverified binary.
- Manage portable user configuration with GNU Stow.
- Preserve Fedora defaults for Secure Boot, SELinux, firewalld, PipeWire, and
  desktop portals.
- Keep Hyprland-specific behavior out of the Fedora configuration.

## Session Path

```text
GDM -> Niri -> Noctalia
```

GDM remains the login manager. Noctalia Greeter and greetd are deliberately not
part of this project. Noctalia Shell starts from Niri with
`spawn-at-startup "noctalia"`.

## Layout

```text
OS.md                         Fedora decisions and boundaries
shell.md                      Noctalia ownership and runtime model
packages.md                   Fedora package profiles and sources
instructions/installation.md  End-to-end setup
instructions/niri.md          Niri configuration and feature mapping
instructions/noctalia-runtime.md  Manual runtime and recovery checks
scripts/                      Package, service, Stow, and verification scripts
dotfiles/bash/                Bash, aliases, functions, and input configuration
dotfiles/niri/                Niri KDL configuration
dotfiles/noctalia/            Reviewed Noctalia configuration
dotfiles/ghostty/             Ghostty configuration
dotfiles/herdr/               Herdr configuration
dotfiles/starship/            Starship configuration
dotfiles/tmux/                tmux configuration
```

Run the scripts as the normal user from this directory:

```bash
./scripts/01-install-packages.sh
./scripts/02-enable-services.sh
./scripts/03-stow-configs.sh --replace-bash
./scripts/04-verify-setup.sh
```

The package script installs Fedora packages and enables the selected COPR
repositories. The service script does not change the display manager or login
path. The Stow script does not manage Noctalia GUI state, secrets, caches, or
generated files. The verification script is read-only.

## Safety Boundaries

- Test the stock Fedora GNOME session before selecting Niri in GDM.
- Keep a working GNOME session available until Niri and Noctalia have been
  tested.
- Review the Ghostty and Starship COPR metadata before enabling them.
- Do not disable SELinux, firewalld, Secure Boot, or Fedora portals to work
  around an application issue.
- Do not enable SSH or Tailscale just because their packages are installed. For
  remote access, authenticate Tailscale first and use `--ssh` to enable
  Tailscale SSH; tailnet policy controls access.
- Keep existing regular dotfiles unless `--replace-bash` is explicitly used.

## Status

The initial Fedora project includes the package profiles, service baseline,
portable dotfiles, a first Niri configuration, installation documentation, and
read-only validation. Hardware-specific output names and runtime behavior must
still be verified on the target machine with `niri msg outputs`, Noctalia's
configuration validator, and a real GDM login.
