{ lib, pkgs, ... }: let
  wallpaper = ../assets/lone_tree_day.webp;
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
  };

  # Display manager — ReGreet: GTK4 Wayland greeter running inside cage.
  # programs.regreet sets up the greetd session automatically.
  services.greetd.enable = true;
  programs.regreet = {
    enable = true;
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
