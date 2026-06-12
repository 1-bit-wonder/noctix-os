{ pkgs, ... }: {
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Quiet boot — remove "quiet" here if you want to see kernel messages
  boot.kernelParams = [ "quiet" "loglevel=3" ];

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
  time.timeZone = "America/New_York";
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

  # Shells
  programs.fish.enable = true;

  # Base CLI tools
  environment.systemPackages = with pkgs; [
    wget curl git vim htop unzip zip
    pciutils usbutils lshw
  ];
}
