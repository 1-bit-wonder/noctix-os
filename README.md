<div align="center">

<img src="assets/logo.svg" width="128" alt="noctix-os logo" />

# noctix-os

**A reproducible NixOS desktop — Hyprland + [Noctalia v5](https://github.com/noctalia-dev/noctalia), tuned for work.**

![NixOS](https://img.shields.io/badge/NixOS-unstable-5277C3?logo=nixos&logoColor=white)
![Wayland](https://img.shields.io/badge/Hyprland-Wayland-89b4fa)
![Noctalia](https://img.shields.io/badge/Noctalia-v5-cba6f7)
![home-manager](https://img.shields.io/badge/home--manager-managed-a6e3a1)

</div>

---

A single flake that builds a complete, themed Hyprland desktop: the [Noctalia](https://github.com/noctalia-dev/noctalia) shell (bar, launcher, control center, notifications), a GTK4 login greeter, a full dev toolchain, and YubiKey support — all declarative, all reproducible. Tracks `nixos-unstable`.

## Hosts

| Host | Hardware | Status |
|---|---|---|
| `desktop` | AMD Ryzen 7 7700X + RTX 2080 | The live machine |
| `laptop` | TBD | **Stub** for future hardware — evaluates, not yet deployed |

Both hosts share everything in `modules/` and `home/`; only `hosts/<name>/` differs.

## What's included

### Desktop environment
- **[Hyprland](https://hyprland.org/)** — Wayland compositor, configured via the native **Lua API** (`hl.*`), not the legacy keyword syntax. Dwindle/master/scrolling/monocle layouts, blur, shadows, animations, touchpad gestures.
- **[Noctalia v5](https://github.com/noctalia-dev/noctalia)** shell — bar, app launcher, control center (network/bluetooth/audio/display/calendar/notifications tabs), session menu, lock screen, OSDs. Wallpaper-driven theming.
- **ReGreet** — GTK4 Wayland login greeter running in cage, themed to match.
- **Plymouth** boot splash for a seamless boot → login transition.
- **PipeWire** (ALSA/Pulse/JACK), **Bluetooth** (blueman), **CUPS** printing with mDNS auto-discovery (Avahi), **XDG portals** (Hyprland + GTK), **polkit** agent, GNOME keyring.

### Theming
- Catppuccin Mocha palette (mauve/blue accents), **adw-gtk3-dark** + **Papirus-Dark**, Adwaita cursor.
- Consistent GTK3/GTK4/Qt (qt6ct) dark theming; Noctalia recolors Kitty to match the wallpaper at runtime.
- Fonts: JetBrains Mono Nerd Font, Fira Code, Inter, Noto (incl. CJK + color emoji).

### Applications
- **Terminal:** Kitty (+ foot for the cheatsheet popup) · **Browser:** Firefox · **Files:** Nautilus (+ gvfs, tumbler thumbnails)
- **Media:** VLC, mpv, EOG, Evince, Cheese · **Productivity:** LibreOffice, Thunderbird, GNOME text editor/calculator/calendar
- **Screenshots:** grim + slurp + swappy, OBS Studio · **Clipboard:** cliphist + fuzzel picker
- **System:** pavucontrol, btop, baobab, GNOME system monitor, nm-connection-editor, **1Password** (GUI + polkit integration)

### Dev toolchain (`home/dev.nix`)
- **[mise](https://mise.jdx.dev/)** — polyglot runtime/version manager (Node, Python, Go, …)
- **direnv** + **nix-direnv** — per-directory envs with cached dev shells
- **[starship](https://starship.rs/)** prompt · **fzf** · **zoxide** · **bat**
- **ripgrep**, **fd**, **jq**, **eza**, **tree**, **lazygit**
- **gh** (GitHub CLI), **git-delta** (syntax-highlighted diffs)
- Nix tooling: **nixd** (LSP), **alejandra** (formatter), **nix-output-monitor**
- Git configured for **SSH commit signing** via your YubiKey FIDO2 key

### Security & hardware
- **YubiKey / FIDO2** baseline — udev rules + `libfido2`, so `sk-ecdsa` SSH keys and SSH commit signing work out of the box.
- AMD + NVIDIA graphics enabled (`hardware.graphics`), 32-bit support for games/Steam.
- Weekly automatic GC, store auto-optimise, Noctalia + Hyprland binary caches.

## Install on a new machine

### 1. Install NixOS
Download the [NixOS graphical installer](https://nixos.org/download), flash it, and run through it. Use `desktop` as the hostname and `ni` as the username to match this config. The installer writes hardware config to `/etc/nixos/hardware-configuration.nix` — that's all you need from it.

### 2. Apply this config on first boot
```bash
sudo nixos-rebuild switch --impure --flake github:1-bit-wonder/noctix-os#desktop --accept-flake-config
```
- `--impure` — the config imports `/etc/nixos/hardware-configuration.nix` directly from the machine.
- `--accept-flake-config` — trusts the Noctalia and Hyprland binary caches; without it, everything rebuilds from source.

Default password is `nixos` — change it with `passwd ni` after logging in.

### 3. Lock in your hardware config for future reinstalls
```bash
git clone https://github.com/1-bit-wonder/noctix-os ~/noctix-os
cp /etc/nixos/hardware-configuration.nix ~/noctix-os/hosts/desktop/hardware-configuration.nix
```
Then change the import in `hosts/desktop/configuration.nix` from `/etc/nixos/hardware-configuration.nix` to `./hardware-configuration.nix`, commit, and push. After this you no longer need `--impure`.

### 4. Post-install setup
A few things are intentionally **not** baked into this public repo and need a one-time setup:

**Git identity** (kept out of the repo on purpose):
```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```

**YubiKey commit signing** — git is preconfigured to sign with your FIDO2 SSH key (`~/.ssh/id_ecdsa_sk_rk.pub`). Register that key on GitHub as a **Signing key** (Settings → SSH and GPG keys → New SSH key → type **Signing**) — it's separate from the authentication key you push with. Until then commits sign locally but show as *Unverified* on GitHub. If the key isn't present yet:
```bash
ssh-add ~/.ssh/id_ecdsa_sk_rk   # touch the YubiKey
```

**Dev runtimes** — none are preinstalled; pull what you need with mise:
```bash
mise use -g node@lts
mise use -g python@latest
```

## Day-to-day workflow
```bash
# Edit config locally, then apply:
sudo nixos-rebuild switch --flake ~/noctix-os#desktop

# Sync across machines:
git push
git pull && sudo nixos-rebuild switch --flake ~/noctix-os#desktop
```

## Adding a second machine
`hosts/laptop/` already exists as a **stub** for future hardware — it evaluates but hasn't been deployed. When the real machine exists, lock in its hardware config the same way as the desktop (step 3) and install with `--flake github:1-bit-wonder/noctix-os#laptop`.

To add a *different* machine from scratch:
1. Add a directory under `hosts/` (e.g. `hosts/my-box/`)
2. Copy `hosts/desktop/configuration.nix`, set its `networking.hostName`, add its `hardware-configuration.nix`
3. Add a `nixosConfigurations.my-box` entry in `flake.nix`
4. Install with `--flake github:1-bit-wonder/noctix-os#my-box`

## Keybindings

`Super` = Windows/Meta key. Press `Super + F1` for this cheatsheet on the live system.

| Applications | |
|---|---|
| `Super + Return` | Terminal (Kitty) |
| `Super + E` | Files (Nautilus) |
| `Super + R` | App launcher |
| `Super + Shift + V` | Clipboard history |
| `Super + F1` | Keybind cheatsheet |

| Noctalia panels | |
|---|---|
| `Super + N` | Network panel |
| `Super + B` | Bluetooth panel |
| `Super + A` | Quick settings (control center) |
| `Super + X` | Power / session menu |
| `Super + Delete` | Lock screen |

| Windows | |
|---|---|
| `Super + Q` | Close · `Super + F` fullscreen · `Super + M` maximize |
| `Super + V` | Toggle floating · `Super + C` center · `Super + P` pseudo-tile |
| `Super + Shift + P` | Pin · `Super + T` toggle split · `Alt + Tab` cycle |
| `Super + H/J/K/L` | Focus (or arrow keys) |
| `Super + Shift + H/J/K/L` | Move window |
| `Super + Ctrl + H/J/K/L` | Resize window |
| `Super + Left/Right drag` | Move / resize with mouse |

| Workspaces & layouts | |
|---|---|
| `Super + 1–0` | Switch to workspace · `Super + Shift + 1–0` move window |
| `Super + S` / `Super + Shift + S` | Scratchpad toggle / send |
| `Super + Scroll` | Cycle workspaces |
| `Super + Alt + D/M/W/O` | Dwindle / Master / Scrolling / Monocle layout |

| Screenshots & media | |
|---|---|
| `Print` / `Shift + Print` | Region / full screen → annotate (swappy) |
| `Ctrl + Print` | Region → clipboard |
| `XF86Audio*` / `XF86MonBrightness*` | Volume / media / brightness (via Noctalia) |
| `Super + Shift + E` | Exit Hyprland session |

## VM & ISO testing

> VM and ISO builds require `--impure` until you commit the hardware config and switch to the relative import path.

```bash
# QEMU VM:
nix build .#vm --impure --accept-flake-config
QEMU_OPTS="-m 4096 -smp 4" ./result/bin/run-desktop-vm   # login: ni / nixos

# Bootable live ISO:
nix build .#iso --impure --accept-flake-config
sudo dd if=result/iso/noctix-os.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## Validate changes
```bash
nix flake show --impure --accept-flake-config
nix eval --impure --accept-flake-config .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath
nix eval --impure --accept-flake-config .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
```

## Structure
```
flake.nix                         inputs, binary caches, nixosConfigurations + packages
flake.lock

hosts/desktop/                    Ryzen 7 7700X + RTX 2080 — the live host
  configuration.nix               hostname, user, home-manager wiring
  hardware-configuration.nix      PLACEHOLDER — replace with your machine's generated config
hosts/laptop/                     STUB for future hardware — evaluates, not yet deployed
  configuration.nix
  hardware-configuration.nix      PLACEHOLDER

modules/
  system.nix                      bootloader, nix settings, locale, networking, YubiKey
  desktop.nix                     Hyprland, greetd/regreet, PipeWire, Bluetooth, portals
  packages.nix                    system packages + keybind cheatsheet

home/
  default.nix                     home-manager entrypoint
  hyprland.nix                    Hyprland config (native Lua API via hl.*)
  noctalia.nix                    Noctalia shell settings + wallpapers
  apps.nix                        GTK/Qt theming, Kitty, Firefox
  services.nix                    user services (hypridle)
  dev.nix                         dev toolchain — mise, direnv, starship, git signing, CLI tools

assets/                           wallpaper images, logo
```

## Flake outputs

| Output | Description |
|---|---|
| `nixosConfigurations.desktop` | Main desktop configuration (the live host) |
| `nixosConfigurations.laptop` | Stub host for future hardware |
| `nixosConfigurations.desktop-iso` | Bootable live ISO |
| `packages.x86_64-linux.vm` | QEMU VM for quick testing |
| `packages.x86_64-linux.iso` | ISO image (`result/iso/noctix-os.iso`) |
