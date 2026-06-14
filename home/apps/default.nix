{ lib, ... }:
let
  # Auto-import every *.nix in this folder (except this file). The directory
  # listing is the single source of truth: drop an app's file in here and it
  # loads — no manifest to maintain.
  appFiles = builtins.attrNames (lib.filterAttrs
    (name: type:
      type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name)
    (builtins.readDir ./.));
in {
  imports = map (name: ./. + "/${name}") appFiles;
}
