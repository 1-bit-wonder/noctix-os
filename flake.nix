{
  description = "NixOS + Noctalia on Hyprland — work-ready desktop";

  # Tracks nixos-unstable. These caches serve prebuilt Noctalia (C++/Qt) and
  # Hyprland binaries — without them both compile from source on every rebuild.
  nixConfig = {
    extra-substituters = [
      "https://noctalia.cachix.org"
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      # no inputs.nixpkgs.follows — the binary cache requires this be absent
    };
  };

  outputs = { self, nixpkgs, home-manager, noctalia, ... }@inputs:
  let
    system = "x86_64-linux";
    lib    = nixpkgs.lib;
  in {
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/desktop/configuration.nix
        home-manager.nixosModules.home-manager
      ];
    };

    # STUB host for a future laptop — see hosts/laptop/. Evaluates today but is
    # not yet deployed to real hardware.
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/laptop/configuration.nix
        home-manager.nixosModules.home-manager
      ];
    };

    # Bootable live ISO for VM testing:
    #   nix build .#iso --accept-flake-config
    #   sudo dd if=result/iso/noctix-os.iso of=/dev/sdX bs=4M status=progress oflag=sync
    nixosConfigurations.desktop-iso = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
        ./hosts/desktop/configuration.nix
        home-manager.nixosModules.home-manager

        ({ ... }: {
          isoImage.squashfsCompression  = "zstd -Xcompression-level 6";
          isoImage.makeEfiBootable      = true;
          isoImage.makeUsbBootable      = true;
          image.fileName                = "noctix-os.iso";

          # iso-image.nix uses its own hybrid BIOS/EFI bootloader
          boot.loader.systemd-boot.enable      = lib.mkForce false;
          boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

          # Strip quiet/loglevel so boot errors are visible on live media
          boot.kernelParams = lib.mkForce [];

          # Force-load input drivers in initrd so udev enumerates devices before
          # greetd starts — fixes mouse not working and input delay at login screen.
          # availableKernelModules loads on-demand (too late); kernelModules forces early load.
          boot.initrd.kernelModules = [ "usbhid" "hid_generic" "atkbd" "i8042" ];

          # iso-image.nix overrides fileSystems."/" but not "/boot" or swapDevices.
          # Our hardware-configuration.nix placeholder has mkDefault values for both
          # that point to real disk labels which don't exist on live media — override them.
          fileSystems."/boot" = lib.mkForce { fsType = "tmpfs"; device = "tmpfs"; options = [ "mode=0755" ]; };
          swapDevices         = lib.mkForce [];
        })
      ];
    };

    packages.${system} = let
      pkgs   = nixpkgs.legacyPackages.${system};
      rawIso = self.nixosConfigurations.desktop-iso.config.system.build.isoImage;
    in {
      # Test in QEMU: nix build .#vm && QEMU_OPTS="-m 4096 -smp 4" ./result/bin/run-desktop-vm
      vm  = self.nixosConfigurations.desktop.config.system.build.vm;
      # Wrap the ISO so result/iso/noctix-os.iso is the visible filename.
      # nixpkgs computes the ISO filename internally; image.fileName has no effect.
      iso = pkgs.runCommand "noctix-os-iso" {} ''
        mkdir -p $out/iso
        ln -s ${rawIso}/iso/*.iso $out/iso/noctix-os.iso
      '';
    };
  };
}
