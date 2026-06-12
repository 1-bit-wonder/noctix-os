{ inputs, pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  imports = [
    # Use the machine's installer-generated hardware config when it exists (first boot
    # and the live machine); otherwise fall back to the committed placeholder so the
    # flake still evaluates and ISO/VM builds work off-host. No more swapping paths by
    # hand — just keep --impure (needed to probe the absolute path). Once you've
    # installed and copied your real hardware-configuration.nix into this directory,
    # you can replace this whole expression with `./hardware-configuration.nix` and
    # drop --impure for good.
    (if builtins.pathExists /etc/nixos/hardware-configuration.nix
     then /etc/nixos/hardware-configuration.nix
     else ./hardware-configuration.nix)
    ../../modules/system.nix
    ../../modules/desktop.nix
    ../../modules/packages.nix
  ];

  networking.hostName = "desktop";

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
