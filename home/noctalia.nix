{ pkgs, lib, config, ... }: let
  wallpaperDir   = "/home/ni/Pictures/Wallpapers";
  dayWallpaper   = "${wallpaperDir}/lone_tree_day.webp";
  nightWallpaper = "${wallpaperDir}/lone_tree_night.webp";

  noctaliaBin = lib.getExe config.programs.noctalia.package;

  # Noctalia does NOT swap the wallpaper when the theme mode flips — it only
  # recomputes the palette and fires `theme_mode_changed` (with $NOCTALIA_THEME_MODE).
  # So we react to that hook and set the matching wallpaper ourselves. Hook commands
  # are exec'd directly (no shell), hence a script rather than an inline `case`.
  wallpaperForMode = pkgs.writeShellScript "noctalia-wallpaper-for-mode" ''
    case "$NOCTALIA_THEME_MODE" in
      light) exec ${noctaliaBin} msg wallpaper-set ${dayWallpaper} ;;
      *)     exec ${noctaliaBin} msg wallpaper-set ${nightWallpaper} ;;
    esac
  '';
in {
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      theme = {
        mode   = "auto";   # follow day/night; the hook below swaps the wallpaper to match
        source = "wallpaper";
        # Enable the built-in Kitty template so Noctalia regenerates
        # ~/.config/kitty/themes/noctalia.conf (globincluded by kitty.conf) on every
        # palette change and live-reloads running terminals to match light/dark.
        templates = {
          enable_builtin_templates = true;
          builtin_ids              = [ "kitty" ];
        };
      };
      wallpaper = {
        enabled             = true;
        directory           = wallpaperDir;
        fill_mode           = "crop";
        transition_duration = 1500;
        default.path        = dayWallpaper;
      };
      hooks.theme_mode_changed = "${wallpaperForMode}";
    };
  };

  # Single flat wallpaper dir — the theme_mode_changed hook switches between the
  # day/night images, so no light/dark subfolders (or automation) are needed.
  home.file."Pictures/Wallpapers/lone_tree_day.webp".source   = ../assets/lone_tree_day.webp;
  home.file."Pictures/Wallpapers/lone_tree_night.webp".source = ../assets/lone_tree_night.webp;
  home.file."Pictures/Wallpapers/waves_violet.webp".source    = ../assets/waves_violet.webp;
}
