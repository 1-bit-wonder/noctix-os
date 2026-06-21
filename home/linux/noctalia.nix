{ pkgs, lib, config, ... }: let
  wallpaperDir     = "/home/ni/Pictures/Wallpapers";
  defaultWallpaper = "${wallpaperDir}/noctix_logo_dark.webp";
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
      # Global UI corner roundness. 0.0 squares every rounded surface (panels,
      # popups, menus) to match our squared windows and bar; 1.0 is the default
      # rounding. The GUI's "Interface > UI corner roundness" slider writes here.
      shell.corner_radius_scale = 0.0;
      # Launcher bar widget: swap the default "search" magnifier for a
      # moon-with-stars glyph to match the Noctix night branding. (Plain
      # "moon" is the nightlight toggle's icon, so use "moon-stars" instead.)
      widget.launcher.glyph = "moon-stars";
      # Workspaces widget: square the per-workspace capsule pills (0 = no
      # rounding) so they match the squared corners everywhere else.
      widget.workspaces.capsule_radius = 0;
      theme = {
        mode   = "dark";   # stay dark; no day/night switching (avoids clashing with the wallpaper switcher)
        source = "wallpaper";
        # Palette generation scheme. "dysfunctional" is Noctalia's "Disfunctional"
        # scheme (replaces the built-in default "M3 Tonal Spot").
        wallpaper_scheme = "dysfunctional";
        # Enable the built-in app templates so Noctalia regenerates their theme
        # files on every palette change:
        #   kitty -> ~/.config/kitty/themes/noctalia.conf (globincluded by kitty.conf;
        #            its post_hook live-reloads running terminals to match light/dark)
        #   helix -> ~/.config/helix/themes/noctalia.toml (selected via theme="noctalia"
        #            set via theme="noctalia" in home/linux/default.nix; no post_hook, so running
        #            Helix picks it up on the
        #            next launch or :config-reload)
        #   gtk3/gtk4 -> ~/.config/gtk-{3,4}.0/noctalia.css (the wallpaper-matched
        #            palette, @import-ed from gtk.css — see the extraCss in theme.nix).
        #            Their post_hook (the package's gtk/apply.sh) also runs
        #            `dconf write .../color-scheme 'prefer-<mode>'`, which is the signal
        #            xdg-desktop-portal exports as org.freedesktop.appearance color-scheme.
        #            That is what makes apps set to "follow system" (Firefox, GTK4 apps)
        #            track Noctalia's `mode` above — without it the portal reports
        #            "no preference" and they fall back to light despite the dark theme.
        templates = {
          enable_builtin_templates = true;
          builtin_ids              = [ "kitty" "helix" "gtk3" "gtk4" ];
        };
      };
      wallpaper = {
        enabled             = true;
        directory           = wallpaperDir;
        fill_mode           = "crop";
        transition_duration = 1500;
        default.path        = defaultWallpaper;
      };
    };
  };

  # Single flat wallpaper dir. The other images stay available in the
  # switcher, but noctix_logo_dark is the fixed default.
  home.file."Pictures/Wallpapers/lone_tree_day.webp".source   = ../../assets/lone_tree_day.webp;
  home.file."Pictures/Wallpapers/lone_tree_night.webp".source = ../../assets/lone_tree_night.webp;
  home.file."Pictures/Wallpapers/waves_violet.webp".source    = ../../assets/waves_violet.webp;
  home.file."Pictures/Wallpapers/smoke_teal.webp".source      = ../../assets/smoke_teal.webp;
  home.file."Pictures/Wallpapers/marble_blue.webp".source     = ../../assets/marble_blue.webp;
  home.file."Pictures/Wallpapers/noctix_logo_dark.webp".source  = ../../assets/noctix_logo_dark.webp;
  home.file."Pictures/Wallpapers/noctix_logo_light.webp".source = ../../assets/noctix_logo_light.webp;
}
