{ pkgs, config, lib, ... }:
let
  # Screenshot chooser bound to the MX Keys S "Screen Capture" key (see the Solaar
  # rule below). One key opens a fuzzel menu; grim captures, swappy annotates, or
  # wl-copy sends straight to the clipboard. Mirrors the modes the old Print /
  # Shift+Print / Ctrl+Print / Super+Print binds used to provide.
  screenshot-menu = pkgs.writeShellApplication {
    name = "screenshot-menu";
    runtimeInputs = with pkgs; [ grim slurp swappy fuzzel wl-clipboard jq hyprland coreutils ];
    text = ''
      mode=$(printf '%s\n' 'Region' 'Full screen' 'Window' 'Region → clipboard' \
        | fuzzel --dmenu --prompt 'Screenshot: ') || exit 0
      [ -z "''${mode:-}" ] && exit 0
      case "$mode" in
        'Region')
          geom=$(slurp) || exit 0          # Esc in slurp cancels the whole capture
          grim -g "$geom" - | swappy -f -
          ;;
        'Full screen')
          sleep 0.5                         # let the menu surface clear before capturing
          grim - | swappy -f -
          ;;
        'Window')
          sleep 0.5                         # ditto — grim fires with no slurp gap here
          # Grab the focused window's geometry straight from Hyprland (the fuzzel
          # overlay isn't the active window, so this is the real underlying one).
          geom=$(hyprctl activewindow -j \
            | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
          grim -g "$geom" - | swappy -f -
          ;;
        'Region → clipboard')
          geom=$(slurp) || exit 0
          grim -g "$geom" - | wl-copy
          ;;
      esac
    '';
  };
in
{
  home.packages = [ screenshot-menu ];

  # swappy's "Save" writes to save_dir, which defaults to ~/Desktop — easy to miss.
  # Point it at a dedicated, discoverable folder (and ensure that folder exists, as
  # swappy won't save if the directory is absent).
  xdg.configFile."swappy/config".text = ''
    [Default]
    save_dir = $HOME/Pictures/Screenshots
    save_filename_format = screenshot-%Y%m%d-%H%M%S.png
  '';

  home.activation.screenshotsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/Pictures/Screenshots"
  '';

  # The MX Keys S "Screen Capture" key (top row, camera glyph) has no usable Linux
  # keysym: in the keyboard's Mac mode it emits a bare Super+Shift (the 'S' never
  # arrives), which Hyprland can't bind — modifiers alone are never a bind trigger.
  # So the key is *diverted* through Solaar: instead of those keystrokes it sends a
  # private HID++ event, and this rule turns that event into the chooser above.
  #
  # The divert itself is mutable Solaar state in ~/.config/solaar/config.yaml, a
  # file Solaar owns and rewrites (battery, etc.) — so it can't be a read-only
  # home-manager symlink. Set it ONCE per machine, after pairing the keyboard
  # (it then persists across reboots and reconnects):
  #
  #     solaar config "MX Keys S" divert-keys "Screen Capture" Diverted
  #
  # The CLI prints a harmless D-Bus marshalling traceback but the value sticks;
  # verify with:  solaar config "MX Keys S" divert-keys | grep "Screen Capture"
  #
  # rules.yaml IS managed here (declarative). Editing rules via the Solaar GUI
  # would fail to save against this read-only symlink — change them in this file.
  xdg.configFile."solaar/rules.yaml".text = ''
    %YAML 1.1
    ---
    - Rule:
      - Key: [Screen Capture, pressed]
      - Execute: [${screenshot-menu}/bin/screenshot-menu]
    ...
  '';

  # Run Solaar as a user service. It owns two things we depend on: the tray applet
  # and the rule engine that processes the diverted Screen Capture key above. Solaar
  # only reads rules.yaml at startup, so previously every rebuild that changed the
  # rule needed a manual restart (it's otherwise launched by hand). As a service it
  # starts at login and, via X-Restart-Triggers below, restarts automatically when
  # the rule/script changes — so a `nixos-rebuild switch` just works.
  systemd.user.services.solaar = {
    Unit = {
      Description = "Solaar — Logitech device manager (tray + key-diversion rules)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      # Restart when the diverted-key rule (or the script it runs) changes.
      X-Restart-Triggers = [ "${config.xdg.configFile."solaar/rules.yaml".source}" ];
    };
    Service = {
      # pkgs.solaar is the overlay-wrapped binary (peripherals.nix) that already
      # bakes in --battery-icons solaar; just hide the window so it starts to tray.
      ExecStart = "${pkgs.solaar}/bin/solaar --window=hide";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
