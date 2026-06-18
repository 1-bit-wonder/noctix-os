{ lib, pkgs, inputs, ... }: let
  # ReGreet renders the background via GdkPixbuf, and its bundled
  # GDK_PIXBUF_MODULE_FILE has no webp loader — a .webp path silently fails to
  # decode and the greeter shows a blank grey background. Convert our source
  # webp to PNG at build time (PNG is a gdk-pixbuf built-in loader) so it renders.
  wallpaper = pkgs.runCommand "greeter-wallpaper.png" { } ''
    ${pkgs.imagemagick}/bin/magick ${../assets/noctix_logo_light.webp} -strip $out
  '';
in {
  # GPU drivers — required for Hyprland to start on real hardware.
  # programs.hyprland does NOT enable this automatically.
  hardware.graphics = {
    enable      = true;
    enable32Bit = true;
  };

  # Hyprland (system-level: installs binary, registers Wayland session)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # Links uwsm's systemd user units onto the user unit path and enables
    # programs.uwsm, so the greeter's "Hyprland (uwsm-managed)" session starts
    # cleanly instead of crashing on a missing wayland-session-bindpid@.service.
    withUWSM = true;
  };

  # Display manager — ReGreet: GTK4 Wayland greeter running inside cage.
  # programs.regreet sets up the greetd session automatically.
  services.greetd.enable = true;
  programs.regreet = {
    enable = true;
    # Pinned to 0.3.0 from nixpkgs-regreet — 0.4.0's GStreamer-backed background
    # crashes the greeter on this GPU. See the nixpkgs-regreet input in flake.nix.
    package = inputs.nixpkgs-regreet.legacyPackages.${pkgs.system}.regreet;
    settings = {
      background = {
        path = "${wallpaper}";
        fit  = "Cover";
      };
      GTK = lib.mkForce {
        application_prefer_dark_theme = true;
        theme_name        = "adw-gtk3-dark";
        icon_theme_name   = "Papirus-Dark";
        font_name         = "Inter 11";
        cursor_theme_name = "Adwaita";
        cursor_size       = 24;
      };
    };
  };
  # Suppress getty login noise on tty1 behind greetd
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # XDG portals — hyprland portal handles screen share/capture;
  # gtk portal provides file dialogs for non-KDE apps
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    configPackages = [ pkgs.hyprland ];
  };

  # Audio (PipeWire replaces PulseAudio)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.Policy.AutoEnable = "true";
  };
  services.blueman.enable = true;

  # Power management
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Printing (CUPS) — supports auto-discovery of network printers via Avahi
  services.printing = {
    enable = true;
    drivers = with pkgs; [ gutenprint gutenprintBin hplip ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # GNOME virtual filesystem (needed by Nautilus for remote/trash/MTP)
  services.gvfs.enable = true;

  # Thumbnail service (Nautilus, Thunar previews)
  services.tumbler.enable = true;

  # Keyring (stores saved passwords for apps like Thunderbird, Chrome)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # 1Password — polkitPolicyOwners grants the GUI elevated auth without a password prompt
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "ni" ];
  };

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      inter
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.symbols-only
    ];
    fontconfig.defaultFonts = {
      serif      = [ "Noto Serif" "Liberation Serif" ];
      sansSerif  = [ "Inter" "Noto Sans" ];
      monospace  = [ "JetBrainsMono Nerd Font" "FiraCode Nerd Font" ];
      emoji      = [ "Noto Color Emoji" ];
    };
  };
}
