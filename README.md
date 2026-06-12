# noctix-os

NixOS flake for a Hyprland desktop using the [Noctalia v5](https://github.com/noctalia-dev/noctalia) shell. Targets `nixos-unstable`.

## Install on a new machine

### 1. Install NixOS

Download the NixOS graphical installer from [nixos.org/download](https://nixos.org/download), flash it, and run through it. Use `desktop` as the hostname and `ni` as the username to match this config.

The installer writes hardware config to `/etc/nixos/hardware-configuration.nix` — that's all you need from it.

### 2. Apply this config on first boot

```bash
sudo nixos-rebuild switch --impure --flake github:1-bit-wonder/noctix-os#desktop --accept-flake-config
```

`--impure` is required because the config imports `/etc/nixos/hardware-configuration.nix` directly from the local machine.
`--accept-flake-config` trusts the Noctalia and Hyprland binary caches — without it, everything rebuilds from source.

Default password is `nixos` — change it with `passwd ni` after logging in.

### 3. Lock in your hardware config for future reinstalls

```bash
git clone https://github.com/1-bit-wonder/noctix-os ~/noctix-os
cp /etc/nixos/hardware-configuration.nix ~/noctix-os/hosts/desktop/hardware-configuration.nix
```

Then update `hosts/desktop/configuration.nix` to use the relative path instead:

```nix
# Change this:
/etc/nixos/hardware-configuration.nix
# To this:
./hardware-configuration.nix
```

Commit and push:

```bash
cd ~/noctix-os
git add -A && git commit -m "add hardware config" && git push
```

After this, you no longer need `--impure`.

## Day-to-day workflow

```bash
# Edit config locally, then apply:
sudo nixos-rebuild switch --flake ~/noctix-os#desktop

# Push and pull on other machines:
git push
# (on the other machine)
git pull && sudo nixos-rebuild switch --flake ~/noctix-os#desktop
```

## Adding a second machine

`hosts/laptop/` already exists as a **stub** for future hardware — it evaluates but
hasn't been deployed. When the real machine exists, lock in its hardware config the
same way as the desktop (see step 3 above) and install with
`--flake github:1-bit-wonder/noctix-os#laptop`.

To add a *different* machine from scratch:

1. Add a new directory under `hosts/` (e.g. `hosts/my-box/`)
2. Copy `hosts/desktop/configuration.nix`, set its `networking.hostName`, and add its `hardware-configuration.nix`
3. Add a `nixosConfigurations.my-box` entry in `flake.nix` mirroring the existing ones
4. Install with `--flake github:1-bit-wonder/noctix-os#my-box`

## VM testing

> **Note**: VM and ISO builds require `--impure` until you commit the hardware config and switch to the relative import path.

```bash
nix build .#vm --impure --accept-flake-config
QEMU_OPTS="-m 4096 -smp 4" ./result/bin/run-desktop-vm
```

Login: `ni` / `nixos`.

For a bootable ISO:

```bash
nix build .#iso --impure --accept-flake-config
sudo dd if=result/iso/noctix-os.iso of=/dev/sdX bs=4M status=progress oflag=sync
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
  system.nix                      bootloader, nix settings, locale, networking
  desktop.nix                     Hyprland, greetd/regreet, PipeWire, Bluetooth, portals
  packages.nix                    system packages

home/
  default.nix                     home-manager entrypoint
  hyprland.nix                    Hyprland config (native Lua API via hl.*)
  noctalia.nix                    Noctalia shell settings
  apps.nix                        GTK/Qt theming, Kitty, Firefox
  services.nix                    user systemd services

assets/                           wallpaper images
```

## Flake outputs

| Output | Description |
|---|---|
| `nixosConfigurations.desktop` | Main desktop configuration (the live host) |
| `nixosConfigurations.laptop` | Stub host for future hardware |
| `nixosConfigurations.desktop-iso` | Bootable live ISO |
| `packages.x86_64-linux.vm` | QEMU VM for quick testing |
| `packages.x86_64-linux.iso` | ISO image (same as desktop-iso, renamed) |
