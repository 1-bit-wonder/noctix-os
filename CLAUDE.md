# CLAUDE.md

Cross-platform Nix flake: a Hyprland + Noctalia v5 NixOS desktop plus two
nix-darwin Macs, tracking `nixos-unstable`. NixOS hosts use `nixos-rebuild`;
macOS hosts use `darwin-rebuild switch --flake .#<host>` (NOT `nixos-rebuild`).

## Hosts
- `zenith-pc-ryzen-7` — the live NixOS desktop (AMD Ryzen 7 7700X + RTX 2080).
- `luna-macbook-intel` — live nix-darwin Mac, `x86_64-darwin` (Intel).

All hosts share `home/common/` (cross-platform tools). NixOS hosts add
`home/linux/` (Hyprland/Noctalia/Wayland + `modules/`); Macs add
`home/darwin.nix` (Homebrew PATH). Only `hosts/<name>/` differs per machine.

## Validate changes
The NixOS host imports its real generated `./hardware-configuration.nix` (committed). Evaluation is pure, so `--impure` is NOT needed. Darwin configs evaluate on Linux too (only building needs a Mac). Run `nix flake show` plus a toplevel eval for each host you touched:

```bash
nix flake show --accept-flake-config
nix eval --accept-flake-config .#nixosConfigurations.zenith-pc-ryzen-7.config.system.build.toplevel.drvPath
nix eval --accept-flake-config .#darwinConfigurations.luna-macbook-intel.config.system.build.toplevel.drvPath
```

## Conventions
- System config → `modules/` (`system.nix`, `desktop.nix`, `packages.nix`), NixOS-only. User/home config → `home/`. Don't mix the two.
- `home/` is split by platform into directories: `common/` (cross-platform — fish, starship, helix, git, the CLI toolchain — imported by every host), `linux/` (Hyprland/Noctalia/Wayland, NixOS only), and the single file `darwin.nix` (macOS only). Each of `common/` and `linux/` has a `default.nix` that auto-imports every other `*.nix` in its folder *and* holds that layer's own option settings (username, session vars, etc.) — so **location encodes the platform layer**: drop a cross-platform tool in `home/common/`, a Linux-only one in `home/linux/`, and it loads automatically, no import list to edit. `home/default.nix` is the NixOS entrypoint (imports `./common` + `./linux`); Mac hosts import `[ ../../home/common ../../home/darwin.nix ]` directly from their `configuration.nix`. Put anything that must build on macOS in `home/common/`.
- `modules/desktop.nix` is the desktop *environment* (Hyprland, greeter, audio, portals) — shared by the NixOS hosts, unrelated to any host name.
- New NixOS host: add `hosts/<name>/` with `configuration.nix` (set `networking.hostName`) and a `hardware-configuration.nix` (its real generated config), plus a matching `nixosConfigurations.<name>` entry in `flake.nix`.
- New Mac host: add `hosts/<name>/configuration.nix` (set `nixpkgs.hostPlatform`, `networking.hostName`, home-manager wiring) and a `darwinConfigurations.<name>` entry in `flake.nix`.
- Hyprland is configured via the native Lua API (`hl.*`) in `home/linux/hyprland.nix`, not the legacy keyword syntax.

## Do not touch
- `hosts/zenith-pc-ryzen-7/hardware-configuration.nix` is the live machine's real generated config — committed and version-controlled. Regenerate from the target machine when reinstalling on new hardware.
- The `noctalia` flake input has no `inputs.nixpkgs.follows` on purpose — adding one breaks its binary cache. Leave it.
- Don't drop `--accept-flake-config` from documented commands — it trusts the Noctalia/Hyprland caches; without it everything rebuilds from source.
- Repo is public: no secrets or personal tokens. (The `password = "nixos"` default is intentional and documented — not a secret to remove.)
