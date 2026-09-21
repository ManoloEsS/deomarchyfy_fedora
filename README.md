# deomarchyfy_fedora

Fresh Fedora Workstation → Niri + Noctalia reference desktop. Run the commands
in order as the normal user (never as root). Start from a working stock GNOME
session with Secure Boot and SELinux enabled.

Session path: `GDM -> Niri -> Noctalia`

## 1. Get the project

```bash
git clone git@github.com:ManoloEsS/deomarchyfy_fedora.git
cd deomarchyfy_fedora
```

Expected: a `deomarchyfy_fedora` directory with `scripts/`, `dotfiles/`, and
`instructions/`.

## 2. Install packages

```bash
sudo dnf upgrade --refresh
./scripts/01-install-packages.sh --dry-run
./scripts/01-install-packages.sh
```

Expected (dry-run):

```text
+ sudo dnf5 upgrade --refresh -y
+ sudo dnf5 copr enable -y scottames/ghostty
+ sudo dnf5 copr enable -y sneexy/zen-browser
Installing Fedora packages from .../deomarchyfy_fedora:
+ sudo dnf5 install -y niri noctalia stow git neovim tmux python3 fontconfig fzf bat eza zoxide wtype curl-minimal tar xz ghostty zen-browser
+ install JetBrainsMono Nerd Font v3.5.1 into .../.local/share/fonts/JetBrainsMono\ Nerd\ Font
```

Options: `--no-ghostty`, `--no-zen-browser`, `--no-font`, `--with-starship`,
`--with-sync-tools`, `--no-upgrade`. Requires Niri 26.04 or newer from the
target Fedora release.

## 3. Enable services

```bash
./scripts/02-enable-services.sh --dry-run
./scripts/02-enable-services.sh
```

Expected on stock Workstation (everything already active, nothing changed):

```text
Already enabled and active, skipping: NetworkManager.service
Already enabled and active, skipping: firewalld.service
Already enabled and active, skipping: tuned-ppd.service
Already enabled and active, skipping: fstrim.timer
Service configuration complete.
```

## 4. Link the configuration

```bash
./scripts/03-stow-configs.sh --dry-run
./scripts/03-stow-configs.sh --replace-all
```

Expected (dry-run excerpt, one `LINK:` per file):

```text
Stowing: bash ghostty herdr niri noctalia starship tmux
LINK: .config/niri/config.kdl => .../dotfiles/niri/.config/niri/config.kdl
LINK: .config/noctalia/config.toml => .../dotfiles/noctalia/.config/noctalia/config.toml
LINK: .config/noctalia/wallpapers/shaded.png => .../dotfiles/noctalia/.config/noctalia/wallpapers/shaded.png
LINK: .local/state/noctalia/settings.toml => .../dotfiles/noctalia/.local/state/noctalia/settings.toml
...
Configuration links applied.
```

`--replace-all` backs up conflicting regular files under
`~/.local/state/deomarchyfy-fedora/backups/` first.

## 5. Validate before the first Niri login

```bash
niri validate
noctalia config validate
./scripts/04-verify-setup.sh
```

Expected:

```text
config is valid
✓ Config is valid
...
All required checks passed; 2 warning(s).
```

The 2 warnings are expected pre-login: monitor state and effective wallpaper
need the live session. Everything else must pass.

## 6. Log into Niri and verify

Log out → GDM gear menu → Niri → log in, then:

```bash
./scripts/04-verify-setup.sh
```

Expected:

```text
PASS Niri session detected
PASS Acer monitor reference mode
PASS Samsung monitor reference mode
PASS wallpaper effective .../.config/noctalia/wallpapers/shaded.png

All required checks passed; 0 warning(s).
```

Then confirm: `Super+Space` opens the launcher, `Super+Return` opens Ghostty,
`Super+Shift+Return` opens Zen, `Super+Alt+L` locks, media keys work.

## Safety boundaries

- Keep GNOME available until Niri + Noctalia are verified; recover via TTY
  (`Ctrl+Alt+F3`, `pkill -x noctalia`) if the shell fails.
- Review the Ghostty, Zen Browser, and Starship COPR metadata before enabling.
- Do not disable SELinux, firewalld, Secure Boot, or Fedora portals.
- Do not enable SSH/Tailscale just because the packages exist; authenticate
  Tailscale first, then use `--ssh`.

## Reference

- `instructions/installation.md` — full annotated install
- `instructions/niri.md` — Niri config and keybindings
- `instructions/noctalia-runtime.md` — runtime and recovery checks
- `packages.md` — package sources and baselines
- `shell.md` — Noctalia ownership model

Reference hardware: Acer `3440x1440@119.998` + portrait Samsung
`1920x1080@74.973`, both scale `1`. On different displays, update the Niri
output blocks and Noctalia monitor-specific settings.
