{ config, pkgs, ... }: {
  # Desktop appearance — GTK, Qt and cursor theming kept together since they're
  # interrelated (the cursor below syncs with the GTK cursorTheme, and qt sets the
  # platform theme). App *configs* live in home/common/ and home/linux/; this
  # file is purely look.

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
    # Pull in Noctalia's wallpaper-matched palette. Noctalia's gtk3/gtk4 templates
    # (enabled in noctalia.nix) write ~/.config/gtk-{3,4}.0/noctalia.css on every
    # palette change; this @import wires it into the gtk.css that home-manager owns.
    # Letting HM write the import is deliberate: Noctalia's apply.sh would otherwise
    # delete HM's read-only gtk.css symlink to inject the line itself and then fight
    # HM on every rebuild. With the import already present, apply.sh detects it and
    # leaves gtk.css alone — it only (re)writes noctalia.css (which HM doesn't manage)
    # and pushes the color-scheme preference to the portal.
    gtk3.extraCss = ''@import url("noctalia.css");'';
    gtk4.extraCss = ''@import url("noctalia.css");'';
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
