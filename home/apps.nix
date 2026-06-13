{ config, pkgs, ... }: {
  # Fish — interactive shell, managed by home-manager. (modules/system.nix also sets
  # programs.fish.enable, which registers fish as a valid login shell system-wide;
  # both are required and live at different layers.)
  programs.fish.enable = true;

  # Starship prompt — config (custom theme) lives in home/dev.nix via xdg.configFile.
  programs.starship = {
    enable = true;
  };

  # Helix — modal editor
  programs.helix = {
    enable = true;
  };

  # Firefox — managed by home-manager so extensions / policies can be added later
  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";  # keep legacy path (pre-26.05 default)
  };

  # Kitty terminal
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 13;
    };
    settings = {
      window_padding_width     = 12;
      background_opacity       = "0.95";
      cursor_blink_interval    = 0;
      confirm_os_window_close  = 0;
      enable_audio_bell        = false;
      shell                    = "${pkgs.fish}/bin/fish";
    };
    # Noctalia generates ~/.config/kitty/themes/noctalia.conf with wallpaper-matched
    # colors at runtime. globinclude silently skips the file if it doesn't exist yet.
    extraConfig = "globinclude themes/noctalia.conf";
  };

  # GTK theming — Adwaita dark keeps everything consistent with GNOME apps
  gtk = {
    enable = true;
    theme = {
      name    = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name    = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name    = "Adwaita";
      size    = 24;
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4 = {
      # Explicitly carry the GTK3 theme into GTK4 (new home-manager default is null)
      theme = config.gtk.theme;
      extraConfig.gtk-application-prefer-dark-theme = true;
    };
  };

  # Qt theming — qtct means qt6ct handles theming (sets QT_QPA_PLATFORMTHEME=qt6ct)
  qt = {
    enable = true;
    platformTheme.name = "qtct";
  };

  # Cursor for Wayland (syncs with GTK cursorTheme above)
  home.pointerCursor = {
    gtk.enable = true;
    name       = "Adwaita";
    size       = 24;
    package    = pkgs.adwaita-icon-theme;
  };
}
