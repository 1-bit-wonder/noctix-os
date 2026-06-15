{ pkgs, ... }:
let
  # Boot logo: render assets/logo.svg (the noctix-os crescent) to a PNG at build
  # time with resvg, so the bootloader image stays in sync with the source SVG and
  # no binary blob lives in the repo. Limine centers this on the backdrop below.
  bootLogo = pkgs.runCommand "boot-logo.png" { } ''
    ${pkgs.resvg}/bin/resvg --width 384 --height 384 ${../assets/logo.svg} $out
  '';
in
{
  # Bootloader
  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Quiet boot — remove "quiet" here if you want to see kernel messages
  boot.kernelParams = [ "quiet" "loglevel=3" ];

  # Keep the menu uncluttered — only the 3 newest generations are listed as boot
  # entries (older ones still exist on disk; `nix-collect-garbage` removes them).
  boot.loader.limine.maxGenerations = 3;

  # Themed boot menu — Catppuccin Mocha palette, matching the desktop/terminal.
  boot.loader.limine.style = {
    # Centered crescent logo over a solid Mocha-base backdrop (no full wallpaper).
    wallpapers = [ bootLogo ];
    wallpaperStyle = "centered";
    backdrop = "1e1e2e"; # Catppuccin base — fills the screen around the logo

    interface = {
      branding = "noctix-os"; # title at the top of the menu
      brandingColor = "cba6f7"; # mauve
      helpColor = "6c7086"; # overlay0 — dim the keybind hints
      helpColorBright = "cba6f7"; # mauve — the auto-boot countdown digit
    };

    graphicalTerminal = {
      foreground = "cdd6f4"; # text
      background = "001e1e2e"; # base, fully transparent (TT=00) so the logo shows
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
