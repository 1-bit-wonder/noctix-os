{ lib, ... }: {
  # Cross-platform home config — imported by EVERY host (NixOS + macOS).
  # Anything in this folder must build on both Linux and Darwin: shell, prompt,
  # editor, git, SSH, and the portable CLI toolchain. Platform-specific config
  # lives in home/linux/ (Hyprland/Noctalia/Wayland) and home/darwin.nix.
  #
  # Auto-import every *.nix in this folder (except this file). The directory
  # listing is the single source of truth: drop a cross-platform app's file in
  # here and it loads on every host — no manifest to maintain. Non-.nix files
  # (e.g. starship.toml, referenced by dev.nix) are skipped.
  imports = map (name: ./. + "/${name}") (builtins.attrNames (lib.filterAttrs
    (name: type:
      type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name)
    (builtins.readDir ./.)));

  home.username = "ni";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # xdg.configFile works on both platforms (writes ~/.config); the various app
  # modules rely on it. xdg.userDirs (Desktop/Downloads/…) is Linux-only and set
  # in home/linux/default.nix.
  xdg.enable = true;

  # Cross-platform session variables. The Wayland/Qt toolkit vars are Linux-only
  # and live in home/linux/default.nix.
  home.sessionVariables = {
    EDITOR = "hx";
  };
}
