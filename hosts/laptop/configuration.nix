{ inputs, pkgs, ... }: {
  # STUB — placeholder host for a future laptop. Not yet running on real hardware.
  # It mirrors hosts/desktop/configuration.nix so the flake evaluates and the
  # "Adding a second machine" steps in the README work. Adjust modules/hardware
  # once the actual laptop exists (e.g. Intel graphics may need different drivers
  # than the desktop's AMD/NVIDIA setup in modules/desktop.nix).
  nixpkgs.config.allowUnfree = true;

  imports = [
    # Committed placeholder hardware config — this host is a stub with no real
    # hardware yet. On first install, replace it with the machine's generated config
    # (cp /etc/nixos/hardware-configuration.nix here). Pure relative import — no --impure.
    ./hardware-configuration.nix
    ../../modules/system.nix
    ../../modules/desktop.nix
    ../../modules/packages.nix
  ];

  networking.hostName = "laptop";

  users.users.ni = {
    isNormalUser = true;
    description = "ni";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" "render" ];
    shell = pkgs.fish;
    # Default password — intentional, change with `passwd ni` after first boot
    password = "nixos";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.ni = import ../../home/default.nix;
  };

  # Initial value — do not change after first deploy (controls stateful defaults)
  system.stateVersion = "25.05";
}
