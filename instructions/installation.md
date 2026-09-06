# Installation

Run these steps from the Fedora project directory as the normal user. Do not
run the scripts as root.

## 1. Fedora Installation

Use Fedora Workstation with the normal installer defaults unless there is a
specific storage, encryption, firmware, or GPU requirement. Keep Secure Boot
and SELinux enabled. Create a normal user and confirm that the stock GNOME
session works before changing the daily session.

## 2. Get the Project

```bash
git clone https://github.com/ManoloEsS/deomarchyfy_fedora.git
cd deomarchyfy_fedora
```

If the repository is not published yet, use the local project directory and
configure a remote after reviewing the initial files.

## 3. Install Packages

Update Fedora and install the core profile:

```bash
sudo dnf upgrade --refresh
./scripts/01-install-packages.sh
```

Use `--dry-run` first to inspect the transaction. The default enables the
Ghostty COPR because Ghostty is the selected terminal. Skip it with
`--no-ghostty`, or add Starship's COPR explicitly with `--with-starship`.

Optional developer tools are separate from the desktop core:

```bash
./scripts/01-install-packages.sh --with-starship
sudo dnf install mise jj
```

The optional `rsw` live-directory synchronization helper requires extra tools:

```bash
./scripts/01-install-packages.sh --with-sync-tools
```

Install Herdr and OpenCode using their current upstream instructions. Do not
pipe an unreviewed installer into a root shell.

## 4. Enable Services

Enable the system baseline:

```bash
./scripts/02-enable-services.sh
```

Fedora Workstation normally provides zram swap through its own defaults. Verify
it with `swapon --show` and `zramctl`; do not add a custom zram configuration
unless the target installation is missing Fedora's default.

The script can also enable explicitly selected services:

```bash
./scripts/02-enable-services.sh --tailscale
./scripts/02-enable-services.sh --docker
```

Tailscale authentication remains manual:

```bash
sudo tailscale up
tailscale status
```

After `tailscale status` confirms that this machine is connected, enable Tailscale
SSH:

```bash
./scripts/02-enable-services.sh --ssh
```

`--ssh` only advertises Tailscale SSH. It does not install `openssh-server`,
modify `authorized_keys`, or change firewalld. Tailscale authenticates the
connecting tailnet identity, while the SSH policy determines which users and
devices may connect. If the tailnet policy has been customized, ensure it
contains both a network access rule and an `ssh` rule; see the [Tailscale SSH
policy documentation](https://tailscale.com/kb/1193/tailscale-ssh).

From another permitted device on the same tailnet, connect using the Fedora
machine's Tailscale hostname or address:

```bash
ssh your-user@fedora-machine
```

## 5. Apply User Configuration

Inspect the Stow plan first:

```bash
./scripts/03-stow-configs.sh --dry-run
```

On a clean user account, apply all reviewed packages:

```bash
./scripts/03-stow-configs.sh --replace-bash
```

`--replace-bash` moves existing regular Bash files into a timestamped backup
directory under `~/.local/state/deomarchyfy-fedora/backups/`. Other conflicts
stop the script rather than overwriting user files.

## 6. Validate Before Login Selection

```bash
./scripts/04-verify-setup.sh
niri validate
noctalia config validate
```

Fix configuration errors before selecting Niri in GDM. The verification script
does not enable a display manager and does not start Noctalia.

## 7. Test Niri from GDM

Log out of GNOME, select the Niri session from the GDM gear menu, and log in.
Confirm that:

- Noctalia starts exactly once.
- Ghostty opens with `Super+Enter`.
- `Super+H/J/K/L` moves focus.
- `Super+1..9` selects workspaces.
- `Super+Space` opens the Noctalia launcher.
- `Super+Q` closes a window.
- `Super+F` maximizes a column and `Super+Shift+F` fullscreen a window.
- Volume, brightness, media, lock, and screenshot keys work.
- Both monitors and the assigned workspaces behave as expected.

## 8. Recovery

If Niri or Noctalia fails, use `Ctrl+Alt+F3` to reach a TTY, log in, and stop
the user shell if necessary:

```bash
pkill -x noctalia || true
niri msg action quit || true
```

Log back into GNOME through GDM, inspect the user journal, and correct the Niri
configuration. GDM and GNOME are intentionally retained as the recovery path.
