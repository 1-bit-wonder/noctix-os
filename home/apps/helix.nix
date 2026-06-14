{ ... }: {
  # Helix — modal editor. The "noctalia" theme is generated at runtime by
  # Noctalia's built-in helix template (home/noctalia.nix) into
  # ~/.config/helix/themes/noctalia.toml, so colors track the wallpaper palette.
  # home-manager only manages helix/config.toml here, leaving that themes/ file
  # untouched. Its `ui.background = "none"` lets the kitty background show through.
  programs.helix = {
    enable = true;
    settings.theme = "noctalia";
  };
}
