# CLAUDE.md

NixOS flake for a Hyprland + Noctalia v5 desktop, tracking `nixos-unstable`.

## Hosts
- `desktop` — the live machine (AMD Ryzen 7 7700X + RTX 2080). The real host.
- `laptop` — a STUB for future hardware. Evaluates but is not deployed; don't treat it as a real machine.

Both hosts share everything in `modules/` and `home/`; only `hosts/<name>/` differs.

## Validate changes
Each host imports its hardware config with a plain relative `./hardware-configuration.nix` — `desktop`'s is the real generated config (committed); `laptop`'s is a committed placeholder. Evaluation is pure, so `--impure` is NOT needed. Run `nix flake show` plus a toplevel eval for each host you touched:

```bash
nix flake show --accept-flake-config
nix eval --accept-flake-config .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath
nix eval --accept-flake-config .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
```

## Conventions
- System config → `modules/` (`system.nix`, `desktop.nix`, `packages.nix`). User/home config → `home/`. Don't mix the two.
- `modules/desktop.nix` is the desktop *environment* (Hyprland, greeter, audio, portals) — shared by all hosts, unrelated to the host named `desktop`.
- New host: add `hosts/<name>/` with `configuration.nix` (set `networking.hostName`) and a `hardware-configuration.nix` (its real generated config, or a placeholder stub for an unbuilt host), plus a matching `nixosConfigurations.<name>` entry in `flake.nix`.
- Hyprland is configured via the native Lua API (`hl.*`) in `home/hyprland.nix`, not the legacy keyword syntax.

## Do not touch
- `hosts/desktop/hardware-configuration.nix` is the live machine's real generated config — committed and version-controlled. `hosts/laptop/hardware-configuration.nix` is still a placeholder stub (no real hardware yet); don't fill it with invented disk UUIDs. Regenerate from the target machine when one exists.
- The `noctalia` flake input has no `inputs.nixpkgs.follows` on purpose — adding one breaks its binary cache. Leave it.
- Don't drop `--accept-flake-config` from documented commands — it trusts the Noctalia/Hyprland caches; without it everything rebuilds from source.
- Repo is public: no secrets or personal tokens. (The `password = "nixos"` default is intentional and documented — not a secret to remove.)
