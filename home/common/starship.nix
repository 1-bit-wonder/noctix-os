{ ... }: {
  # Starship prompt — config (custom theme) lives in home/common/dev.nix via xdg.configFile.
  programs.starship = {
    enable = true;
  };
}
