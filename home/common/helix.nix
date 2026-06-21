{ ... }: {
  # Helix — modal editor. Cross-platform, so only `enable` lives here. The Linux
  # desktop sets `settings.theme = "noctalia"` in home/linux/default.nix: that theme is
  # generated at runtime by Noctalia (home/linux/noctalia.nix) into
  # ~/.config/helix/themes/noctalia.toml so colors track the wallpaper palette.
  # On macOS (no Noctalia) Helix falls back to its built-in default theme.
  programs.helix.enable = true;
}
