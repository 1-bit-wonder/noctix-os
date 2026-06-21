{ inputs, ... }: {
  # luna-macbook-intel — Intel (x86_64) MacBook, managed by nix-darwin.
  # Shares the cross-platform home config (home/common/) with every host and
  # layers the macOS-specific bits from home/darwin.nix on top.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "x86_64-darwin";

  networking.hostName = "luna-macbook-intel";

  # The login user. nix-darwin manages home-manager for this account; macOS owns
  # the account itself (created at OS install), so we only point at its home dir.
  users.users.ni = {
    name = "ni";
    home = "/Users/ni";
  };
  # Required by nix-darwin for user-scoped settings (home-manager, defaults, etc.).
  system.primaryUser = "ni";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs; };
    users.ni = { imports = [ ../../home/common ../../home/darwin.nix ]; };
  };

  # Let `darwin-rebuild` manage the Nix installation it was bootstrapped with.
  nix.enable = true;

  # Initial value — do not change after first deploy (nix-darwin state version).
  system.stateVersion = 5;
}
