{ pkgs, ... }:
let
  # Full-screen 4K Limine menu background: the noctix-os crescent in the upper
  # third (clear of the vertically-centered menu) on the Catppuccin base, rendered
  # from assets/logo.svg at 8-bit (Limine's decoder mishandles 16-bit PNGs).
  bootWallpaper = pkgs.runCommand "boot-wallpaper.png" { } ''
    ${pkgs.resvg}/bin/resvg --width 560 --height 560 ${../assets/logo.svg} logo.png
    ${pkgs.imagemagick}/bin/magick -size 3840x2160 canvas:'#1e1e2e' \
      logo.png -gravity North -geometry +0+280 -composite \
      -depth 8 -strip PNG24:$out
  '';
in
{
  # Bootloader
  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # No "quiet": there's no boot splash (Plymouth wouldn't render on this GPU), so
  # show the console text during the bootloader → greeter handoff. loglevel=3
  # trims kernel noise while leaving systemd's progress visible.
  boot.kernelParams = [ "loglevel=3" ];

  # Keep the menu uncluttered — only the 3 newest generations are listed as boot
  # entries (older ones still exist on disk; `nix-collect-garbage` removes them).
  boot.loader.limine.maxGenerations = 3;

  # Dual-boot: Limine doesn't auto-detect other OSes, so chainload the Windows
  # Boot Manager from its own EFI System Partition. guid() is the GPT partition
  # UUID of nvme2n1p2 (the Windows ESP) — stable across reboots, unlike /dev names.
  boot.loader.limine.extraEntries = ''
    /Windows
    comment: Windows Boot Manager
    protocol: efi_chainload
    path: guid(420d4b1c-ad8b-4897-a173-e50a61d1ceb3):/EFI/Microsoft/Boot/bootmgfw.efi
  '';

  # Themed boot menu — Catppuccin Mocha palette, matching the desktop/terminal.
  boot.loader.limine.style = {
    # Full-screen 4K wallpaper (logo up top); stretched is a 1:1 no-op at 4K.
    wallpapers = [ bootWallpaper ];
    wallpaperStyle = "stretched";

    interface = {
      resolution = "3840x2160"; # match the panel so the wallpaper isn't scaled
      branding = ""; # the logo is the brand — no text title
      helpColor = "6c7086"; # overlay0 — dim the keybind hints
      helpColorBright = "cba6f7"; # mauve — the auto-boot countdown digit
    };

    graphicalTerminal = {
      foreground = "cdd6f4"; # text
      # TTRRGGBB — TT is transparency: 00 = OPAQUE, ff = TRANSPARENT. Must be ff,
      # else Limine paints an opaque terminal layer over the wallpaper and the
      # logo vanishes (only the text, drawn on top, shows). RGB is moot when fully
      # transparent; keep base as a harmless fallback.
      background = "ff1e1e2e";
      brightForeground = "ffffff";
      # 8-color palette: black red green brown blue magenta cyan gray
      palette = "45475a;f38ba8;a6e3a1;f9e2af;89b4fa;cba6f7;94e2d5;bac2de";
      # bright: dark-gray bright-red bright-green yellow bright-blue magenta cyan white
      brightPalette = "585b70;f38ba8;a6e3a1;f9e2af;89b4fa;cba6f7;94e2d5;a6adc8";
    };
  };

  # Pause briefly so the themed menu is actually visible before auto-booting.
  boot.loader.timeout = 5;

  # Nix
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    # Noctalia binary cache (mirrors flake.nix nixConfig for non-flake invocations)
    substituters = [
      "https://noctalia.cachix.org"
      "https://hyprland.cachix.org"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Locale — change to your timezone, e.g. "Europe/London" or "America/Los_Angeles"
  time.timeZone = "America/Winnipeg";
  # Windows dual-boot writes the RTC in local time; match it so the clock reads
  # correctly under both OSes instead of being offset by the UTC difference.
  time.hardwareClockInLocalTime = true;
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Networking
  networking.networkmanager.enable = true;

  # Security
  security.rtkit.enable = true;
  security.polkit.enable = true;

  # YubiKey / FIDO2 baseline — udev rules so the key is accessible without root,
  # for FIDO2 SSH keys (sk-ecdsa) and SSH commit signing. No PAM changes here;
  # touch-to-sudo / GPG smartcard were intentionally left out.
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # Shells
  programs.fish.enable = true;

  # Base CLI tools
  environment.systemPackages = with pkgs; [
    wget curl git vim htop unzip zip
    pciutils usbutils lshw
    libfido2              # fido2-token etc. — manage the YubiKey FIDO2 SSH key
  ];
}
