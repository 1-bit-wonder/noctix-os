{ inputs, pkgs, ... }: {
  imports = [
    inputs.noctalia.homeModules.default
    ./hyprland.nix
    ./screenshots.nix
    ./noctalia.nix
    ./apps
    ./theme.nix
    ./services.nix
    ./dev.nix
    ./ssh.nix
  ];

  home.username = "ni";
  home.homeDirectory = "/home/ni";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;  # keep XDG_* vars in the session (pre-26.05 default)
  };

  # Wayland / toolkit environment (also set in Hyprland exec-once env, but
  # setting here ensures they're present in systemd user units and portals).
  # QT_QPA_PLATFORMTHEME is intentionally omitted here — the qt module in theme.nix
  # writes it to avoid conflicting definitions.
  home.sessionVariables = {
    EDITOR              = "nano";
    MOZ_ENABLE_WAYLAND  = "1";
    QT_QPA_PLATFORM     = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    SDL_VIDEODRIVER     = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    NIXOS_OZONE_WL      = "1";
  };
}
