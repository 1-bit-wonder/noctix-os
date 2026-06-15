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
      # Bar config lives under a *named* subtable; the app's default bar is named
      # "default" (and runtime GUI overrides are written back to [bar.default]),
      # so we override that one rather than spawn a second bar. Omitted fields —
      # including the start/center/end widget lists — keep their built-in defaults.
      bar.default = {
        position    = "left";  # dock the bar to the left screen edge
        radius      = 0;        # squared corners, no rounding
        margin_edge = 0;        # flush against the left edge, no gap (0 = not floating)
        margin_ends = 0;        # no inset; bar spans the full screen edge
        thickness = 40;
      };
      # Launcher bar widget: swap the default "search" magnifier for a
      # moon-with-stars glyph to match the Noctix night branding. (Plain
      # "moon" is the nightlight toggle's icon, so use "moon-stars" instead.)
      widget.launcher.glyph = "moon-stars";
      theme = {
        mode   = "auto";   # follow day/night; the hook below swaps the wallpaper to match
        source = "wallpaper";
        # Enable the built-in app templates so Noctalia regenerates their theme
        # files on every palette change:
        #   kitty -> ~/.config/kitty/themes/noctalia.conf (globincluded by kitty.conf;
        #            its post_hook live-reloads running terminals to match light/dark)
        #   helix -> ~/.config/helix/themes/noctalia.toml (selected via theme="noctalia"
        #            in home/apps.nix; no post_hook, so running Helix picks it up on the
        #            next launch or :config-reload)
        templates = {
          enable_builtin_templates = true;
          builtin_ids              = [ "kitty" "helix" ];
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
