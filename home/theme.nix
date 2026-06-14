{ config, pkgs, ... }: {
  # Desktop appearance — GTK, Qt and cursor theming kept together since they're
  # interrelated (the cursor below syncs with the GTK cursorTheme, and qt sets the
  # platform theme). App *configs* live in home/apps.nix; this file is purely look.

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
