# Packages

## Policy

Prefer Fedora repositories. Use a COPR only for software explicitly selected
for this project and verify the repository owner and package metadata before
enabling it. Use upstream installers only for tools that are not available in
Fedora or a reviewed COPR.

Package names and availability must be checked again on the target Fedora
release. The package script intentionally does not reinstall the Fedora
Workstation desktop baseline.

## Installed By The Script

| Package | Purpose |
| --- | --- |
| `niri` | Wayland compositor and window manager |
| `noctalia` | Desktop shell, lock screen, idle behavior, and controls |
| `stow` | User configuration symlink management |
| `ghostty` | Default terminal, from the selected Ghostty COPR |
| `bat` | File and man-page previews |
| `eza` | Directory listings |
| `fzf` | Interactive selection |
| `git` | Source control |
| `neovim` | Default editor |
| `tmux` | Persistent terminal sessions |
| `zoxide` | Directory navigation |

Fedora's `niri` package already requires `xwayland-satellite`, ships
`niri-portals.conf`, and provides the GDM-visible Wayland session entry. Those
items are not duplicated in the script.

## Fedora Workstation Baseline

These packages are expected from a normal Fedora Workstation installation and
are deliberately not listed in the script:

| Package | Why it is not installed by the script |
| --- | --- |
| `xdg-desktop-portal-gnome` | Fedora GNOME desktop baseline; required portal backend |
| `xdg-desktop-portal-gtk` | Fedora GNOME desktop baseline; fallback portal backend |
| `gnome-keyring` | Fedora GNOME desktop baseline; Secret portal backend |
| `nautilus` | Fedora GNOME desktop baseline; file manager and file chooser support |
| `bash-completion` | Fedora Workstation shell baseline; `.bashrc` loads it when present |
| `ca-certificates` | Fedora base trust store |
| `curl-minimal` | Fedora base provides the `curl` command; not used by the scripts |
| `openssh-clients` | Fedora Workstation normally provides `ssh` and `scp` |
| `firewalld` | Fedora Workstation security baseline |
| `NetworkManager` | Fedora Workstation network baseline |
| `pipewire`, `wireplumber` | Fedora Workstation audio baseline |
| `power-profiles-daemon` | Fedora Workstation power-management baseline |

If a custom or stripped Fedora installation is used, check the baseline before
starting Niri:

```bash
rpm -q xdg-desktop-portal-gnome xdg-desktop-portal-gtk gnome-keyring nautilus
```

Niri's Fedora package requires `xwayland-satellite` and includes
`niri-portals.conf`, so neither is duplicated in the script.

## Optional File Synchronization

The `rsw` shell helper copies a directory to a remote destination and keeps it
updated. It uses `rsync` for the copy and `inotifywait` from `inotify-tools` to
watch the source for modify, create, delete, and move events. This is unrelated
to the desktop session and is not installed by default:

```bash
./scripts/01-install-packages.sh --with-sync-tools
```

The helper also uses the Fedora Workstation OpenSSH client for transport. The
`sff` helper only needs the existing `scp` client.

## Optional Services

| Package | Purpose | Default |
| --- | --- | --- |
| `tailscale` | Private mesh networking and Tailscale SSH | `--tailscale` / `--ssh` |
| `docker` | Container runtime | `--docker` |

Docker adds the user to a root-equivalent group and requires a new login. It is
not enabled by default.

The service script enables Fedora's existing `NetworkManager`, `firewalld`,
`power-profiles-daemon`, and `fstrim.timer` units when requested. It does not
install duplicate copies of those baseline packages.

The `--ssh` option enables Tailscale SSH with `sudo tailscale set --ssh`. It does
not install or enable `openssh-server`, modify `authorized_keys`, or change
firewalld zones. Tailscale claims port 22 only on the Tailscale address, while
tailnet SSH policy controls which users and devices can connect.

Fedora Workstation normally manages compressed zram swap through its own
`zram-generator-defaults` package. This project does not configure zram during
the standard installation. Verify the Fedora default with:

```bash
swapon --show
zramctl
rpm -q zram-generator-defaults
```

The service script retains an explicit `--zram` option only for nonstandard
Fedora installations where the distribution default is absent.

## Third-Party and Upstream Tools

| Tool | Source | Notes |
| --- | --- | --- |
| Ghostty | COPR `scottames/ghostty` | Enabled by the package script unless `--no-ghostty` is used |
| Starship | COPR `atim/starship` | Optional; use `--with-starship` |
| mise | Fedora package or upstream | Optional and not required by the base setup |
| Jujutsu | Fedora package or upstream | Optional developer tool |
| Herdr | Upstream installer/release | Configuration is included, installation is separate |
| OpenCode | Current upstream source | Distribution channel may change |

The COPR names are configuration inputs, not a claim that a repository is
official Fedora infrastructure. Review them before installation:

```bash
dnf copr list
dnf copr info scottames/ghostty
dnf copr info atim/starship
```

The script installs `dnf5-plugins` when Fedora uses DNF5, or
`dnf-plugins-core` with the older DNF command, before enabling a COPR.

## Not Included

This project does not add Waybar, Mako, Walker, fuzzel, hyprlock, hypridle,
hyprsunset, greetd, Noctalia Greeter, or Hyprland. Noctalia and Niri already
own the corresponding responsibilities.
