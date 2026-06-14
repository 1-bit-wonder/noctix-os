{ ... }: {
  # Fish — interactive shell, managed by home-manager. (modules/system.nix also sets
  # programs.fish.enable, which registers fish as a valid login shell system-wide;
  # both are required and live at different layers.)
  programs.fish.enable = true;
}
