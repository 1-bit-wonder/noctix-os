{ inputs, lib, ... }: {
  # Linux-only home config — imported by NixOS hosts (via home/default.nix) only.
  # The Hyprland/Noctalia/Wayland desktop and anything that can't build on macOS
  # lives in this folder. Cross-platform tools are in home/common/.
  #
  # Auto-import every *.nix in this folder (except this file), then add the
  # Noctalia home module (an external input, not a local file). Drop a Linux-only
  # app's file in here and it loads on the NixOS hosts — no manifest to maintain.
  imports = [ inputs.noctalia.homeModules.default ]
    ++ map (name: ./. + "/${name}") (builtins.attrNames (lib.filterAttrs
      (name: type:
        type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name)
      (builtins.readDir ./.)));

  home.homeDirectory = "/home/ni";

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;  # keep XDG_* vars in the session (pre-26.05 default)
  };

  # Helix theme generated at runtime by Noctalia (home/linux/noctalia.nix) into
  # ~/.config/helix/themes/noctalia.toml, so colors track the wallpaper palette.
  # Kept out of home/common/helix.nix because the theme only exists on the
  # Noctalia desktop — on macOS Helix uses its built-in default.
  programs.helix.settings.theme = "noctalia";

  # nixos-rebuild abbrs — Linux-only (no nixos-rebuild on Darwin; macOS uses
  # darwin-rebuild). The flake attribute is omitted on purpose: nixos-rebuild
  # defaults to nixosConfigurations.$(hostname), and host configs are named to
  # match their hostName (zenith-pc-ryzen-7), so the same abbr works per host.
  # An abbr (not an alias) expands inline before you hit enter, so the full
  # command is visible and editable (e.g. to add --show-trace).
  programs.fish.shellAbbrs = {
    rebuild = "sudo nixos-rebuild switch --flake /home/ni/Code/Systems/noctix-os --accept-flake-config";
    update  = "nix flake update --flake /home/ni/Code/Systems/noctix-os --accept-flake-config; and sudo nixos-rebuild switch --flake /home/ni/Code/Systems/noctix-os --accept-flake-config";
  };

  # `noctalia-reseed` — force Noctalia to re-seed from the flake-managed
  # ~/.config/noctalia/config.toml. Noctalia's writable runtime state in
  # ~/.local/state/noctalia/settings.toml OVERRIDES config.toml, so a declarative
  # change in home/linux/noctalia.nix won't take effect for any key already
  # persisted there. Run this after such a change isn't showing up: it stops
  # noctalia, drops the runtime file (home-manager never touches it), and restarts.
  programs.fish.functions.noctalia-reseed = ''
    systemctl --user stop noctalia
    rm -f ~/.local/state/noctalia/settings.toml
    systemctl --user start noctalia
  '';

  # Wayland / toolkit environment (also set in Hyprland exec-once env, but
  # setting here ensures they're present in systemd user units and portals).
  # QT_QPA_PLATFORMTHEME is intentionally omitted here — the qt module in theme.nix
  # writes it to avoid conflicting definitions.
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND  = "1";
    QT_QPA_PLATFORM     = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    SDL_VIDEODRIVER     = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    NIXOS_OZONE_WL      = "1";
  };
}
