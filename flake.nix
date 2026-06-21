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
    # Pinned solely to source ReGreet 0.3.0. ReGreet 0.4.0 (current unstable)
    # loads its background through GTK4 GtkMediaFile -> GStreamer GstPlay, whose
    # GL pipeline fatally aborts on this machine's GPU (greeter never appears).
    # 0.3.0 renders the background with GdkPixbuf and has no GStreamer dependency.
    # This is the last nixpkgs rev before the 06-16 bump, which shipped 0.3.0.
    # Revisit when 0.4.x is fixed; see modules/desktop.nix programs.regreet.package.
    nixpkgs-regreet.url = "github:nixos/nixpkgs/a799d3e3886da994fa307f817a6bc705ae538eeb";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # macOS host management (luna-macbook-intel). Pinned to the same nixpkgs as
    # everything else so one lock drives all hosts.
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
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
    # The live AMD Ryzen 7 7700X + RTX 2080 desktop.
    nixosConfigurations.zenith-pc-ryzen-7 = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/zenith-pc-ryzen-7/configuration.nix
        # NVIDIA proprietary driver — live host only, NOT the ISO below (a VM
        # guest has no NVIDIA GPU). Enables CTM so hyprsunset's night light
        # actually tints the screen; nouveau can't. See modules/nvidia.nix.
        ./modules/nvidia.nix
        home-manager.nixosModules.home-manager
      ];
    };

    # macOS host, managed by nix-darwin. `system` is taken from the host's
    # nixpkgs.hostPlatform (x86_64-darwin), so it isn't passed here. Apply with
    # `darwin-rebuild switch --flake .#luna-macbook-intel` on the Mac.
    darwinConfigurations.luna-macbook-intel = inputs.nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/luna-macbook-intel/configuration.nix
        home-manager.darwinModules.home-manager
      ];
    };

    # Bootable live ISO for VM testing:
    #   nix build .#iso --accept-flake-config
    #   sudo dd if=result/iso/noctix-os.iso of=/dev/sdX bs=4M status=progress oflag=sync
    nixosConfigurations.zenith-pc-ryzen-7-iso = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
        ./hosts/zenith-pc-ryzen-7/configuration.nix
        home-manager.nixosModules.home-manager

        ({ ... }: {
          isoImage.squashfsCompression  = "zstd -Xcompression-level 6";
          isoImage.makeEfiBootable      = true;
          isoImage.makeUsbBootable      = true;
          image.fileName                = "noctix-os.iso";

          # iso-image.nix uses its own hybrid BIOS/EFI bootloader
          boot.loader.limine.enable            = lib.mkForce false;
          boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

          # Strip quiet/loglevel so boot errors are visible on live media
          boot.kernelParams = lib.mkForce [];

          # Force-load input drivers in initrd so udev enumerates devices before
          # greetd starts — fixes mouse not working and input delay at login screen.
          # availableKernelModules loads on-demand (too late); kernelModules forces early load.
          boot.initrd.kernelModules = [ "usbhid" "hid_generic" "atkbd" "i8042" ];

          # iso-image.nix overrides fileSystems."/" but not "/boot" or swapDevices.
          # The committed hardware-configuration.nix defines both with real disk UUIDs
          # that don't exist on live media — mkForce them for the ISO.
          fileSystems."/boot" = lib.mkForce { fsType = "tmpfs"; device = "tmpfs"; options = [ "mode=0755" ]; };
          swapDevices         = lib.mkForce [];
        })
      ];
    };

    packages.${system} = let
      pkgs   = nixpkgs.legacyPackages.${system};
      rawIso = self.nixosConfigurations.zenith-pc-ryzen-7-iso.config.system.build.isoImage;
    in {
      # Test in QEMU: nix build .#vm && QEMU_OPTS="-m 4096 -smp 4" ./result/bin/run-zenith-pc-ryzen-7-vm
      vm  = self.nixosConfigurations.zenith-pc-ryzen-7.config.system.build.vm;
      # Wrap the ISO so result/iso/noctix-os.iso is the visible filename.
      # nixpkgs computes the ISO filename internally; image.fileName has no effect.
      iso = pkgs.runCommand "noctix-os-iso" {} ''
        mkdir -p $out/iso
        ln -s ${rawIso}/iso/*.iso $out/iso/noctix-os.iso
      '';
    };
  };
}
