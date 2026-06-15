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
}
