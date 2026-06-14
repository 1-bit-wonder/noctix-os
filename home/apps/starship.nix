{ ... }: {
  # Starship prompt — config (custom theme) lives in home/dev.nix via xdg.configFile.
  programs.starship = {
    enable = true;
  };
}
