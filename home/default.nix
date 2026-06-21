{ ... }: {
  # NixOS (Linux) home entrypoint. The cross-platform base (home/common/) plus
  # the Linux desktop layer (home/linux/). macOS hosts import
  # [ ../../home/common ../../home/darwin.nix ] directly from their host
  # configuration.nix instead of this file.
  imports = [
    ./common
    ./linux
  ];
}
