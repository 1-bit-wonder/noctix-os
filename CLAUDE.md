# CLAUDE.md

NixOS flake for a Hyprland + Noctalia-shell desktop, tracking `nixos-unstable`.

## Hosts
- `desktop` — the live machine (AMD Ryzen 7 7700X + RTX 2080). The real host.
- `laptop` — a STUB for future hardware. Evaluates but is not deployed; don't treat it as a real machine.

Both hosts share everything in `modules/` and `home/`; only `hosts/<name>/` differs.

## Validate changes
Host configs import `/etc/nixos/hardware-configuration.nix` (absolute path, for first boot), so evaluation needs `--impure` and that file present on the machine. Run `nix flake show` plus a toplevel eval for each host you touched:

```bash
nix flake show --impure --accept-flake-config
nix eval --impure --accept-flake-config .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath
nix eval --impure --accept-flake-config .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
```

If `/etc/nixos/hardware-configuration.nix` is missing (e.g. validating off-host), temporarily switch the host's import to `./hardware-configuration.nix`, eval, then revert.

## Conventions
- System config → `modules/` (`system.nix`, `desktop.nix`, `packages.nix`). User/home config → `home/`. Don't mix the two.
- `modules/desktop.nix` is the desktop *environment* (Hyprland, greeter, audio, portals) — shared by all hosts, unrelated to the host named `desktop`.
- New host: add `hosts/<name>/` with `configuration.nix` (set `networking.hostName`) and a `hardware-configuration.nix` stub, plus a matching `nixosConfigurations.<name>` entry in `flake.nix`.
- Hyprland is configured via the native Lua API (`hl.*`) in `home/hyprland.nix`, not the legacy keyword syntax.

## Do not touch
- `hosts/*/hardware-configuration.nix` — placeholders, replaced per-machine by the installer. Don't fill them with real disk UUIDs.
- The `noctalia` flake input has no `inputs.nixpkgs.follows` on purpose — adding one breaks its binary cache. Leave it.
- Don't drop `--accept-flake-config` from documented commands — it trusts the Noctalia/Hyprland caches; without it everything rebuilds from source.
- Repo is public: no secrets or personal tokens. (The `password = "nixos"` default is intentional and documented — not a secret to remove.)
