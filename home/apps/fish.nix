{ ... }: {
  # Fish — interactive shell, managed by home-manager. (modules/system.nix also sets
  # programs.fish.enable, which registers fish as a valid login shell system-wide;
  # both are required and live at different layers.)
  programs.fish.enable = true;

  # Show the system-info banner (fastfetch, configured in home/apps/fastfetch.nix)
  # when an interactive shell opens. Guarded to the top-level shell only:
  # `status is-interactive` skips scripts/subshells, and `$SHLVL == 1` skips
  # nested shells (editor terminals, `fish` inside fish, fzf/zoxide subshells)
  # so it doesn't fire on every prompt-in-a-prompt.
  programs.fish.interactiveShellInit = ''
    if status is-interactive; and test "$SHLVL" -eq 1; and command -q fastfetch
      fastfetch
    end
  '';

  # `rebuild` — apply this flake to the current machine. The flake attribute is
  # omitted on purpose: nixos-rebuild defaults to nixosConfigurations.$(hostname),
  # and our host configs are named to match their hostName ("desktop"/"laptop"),
  # so the same abbr does the right thing on every host. Absolute flake path so it
  # works from any directory. An abbr (not an alias) expands inline before you hit
  # enter, so the full command is visible and editable (e.g. to add --show-trace).
  # `update` — bump flake.lock to the latest inputs (nixpkgs/home-manager/
  # noctalia), then rebuild. `; and` chains so the rebuild only runs if the lock
  # update succeeded. Plain `rebuild` (above) applies the *current* lock without
  # bumping versions; this one upgrades. Same absolute flake path + cache flag.
  programs.fish.shellAbbrs = {
    rebuild = "sudo nixos-rebuild switch --flake /home/ni/Code/Systems/noctix-os --accept-flake-config";
    update  = "nix flake update --flake /home/ni/Code/Systems/noctix-os --accept-flake-config; and sudo nixos-rebuild switch --flake /home/ni/Code/Systems/noctix-os --accept-flake-config";
  };

  # `noctalia-reseed` — force Noctalia to re-seed from the flake-managed
  # ~/.config/noctalia/config.toml. Noctalia's writable runtime state in
  # ~/.local/state/noctalia/settings.toml OVERRIDES config.toml, so a declarative
  # change in home/noctalia.nix won't take effect for any key already persisted
  # there. Run this after such a change isn't showing up: it stops noctalia, drops
  # the runtime file (home-manager never touches it), and restarts to re-seed.
  # Kept as an explicit, opt-in function — it discards GUI-side tweaks — rather
  # than wiring it into `rebuild`.
  programs.fish.functions.noctalia-reseed = ''
    systemctl --user stop noctalia
    rm -f ~/.local/state/noctalia/settings.toml
    systemctl --user start noctalia
  '';
}
