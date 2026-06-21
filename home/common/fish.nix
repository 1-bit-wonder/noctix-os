{ ... }: {
  # Fish — interactive shell, managed by home-manager. (modules/system.nix also sets
  # programs.fish.enable, which registers fish as a valid login shell system-wide;
  # both are required and live at different layers.)
  programs.fish.enable = true;

  # Show the system-info banner (fastfetch, configured in home/common/fastfetch.nix)
  # when an interactive shell opens. Guarded to the top-level shell only:
  # `status is-interactive` skips scripts/subshells, and `$SHLVL == 1` skips
  # nested shells (editor terminals, `fish` inside fish, fzf/zoxide subshells)
  # so it doesn't fire on every prompt-in-a-prompt.
  programs.fish.interactiveShellInit = ''
    if status is-interactive; and test "$SHLVL" -eq 1; and command -q fastfetch
      fastfetch
    end
  '';

  # NixOS-only `rebuild`/`update` abbrs and the `noctalia-reseed` function live in
  # home/linux/default.nix — they shell out to nixos-rebuild / systemctl, which don't
  # exist on macOS. This file stays cross-platform (fish + the fastfetch banner).
}
