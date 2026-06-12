{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Terminal
    kitty
    foot                  # lightweight terminal, used for keybind cheatsheet popup

    # Browser (Firefox managed via home-manager programs.firefox; also here for root)
    firefox

    # File management
    nautilus
    gnome-disk-utility
    file-roller           # archive GUI
    p7zip

    # Productivity
    libreoffice-fresh
    thunderbird
    gnome-text-editor
    gnome-calculator
    gnome-calendar

    # Media
    vlc
    mpv
    eog                   # image viewer
    evince                # PDF / document viewer
    cheese                # webcam viewer

    # Screenshot & recording
    grim                  # Wayland screenshot
    slurp                 # region selection
    swappy                # annotation/edit after screenshot
    obs-studio
    wl-clipboard          # wl-copy / wl-paste

    # System utilities
    pavucontrol           # audio control
    networkmanagerapplet  # nm-connection-editor for VPNs / advanced config
                          # (WiFi picker is now the Noctalia control center — Super+N)
    btop                  # resource monitor
    baobab                # disk usage analyzer
    gnome-system-monitor
    system-config-printer

    # Wayland / desktop utilities
    wlr-randr             # display config
    nwg-look              # GTK theme configurator for Wayland
    qt5.qtwayland         # Qt5 Wayland platform plugin (required per Hyprland wiki)
    qt6.qtwayland         # Qt6 Wayland platform plugin (required per Hyprland wiki)
    qt6Packages.qt6ct     # Qt6 theme configurator
    qt6Packages.qtimageformats  # WebP/HEIF/AVIF support for Qt (Noctalia wallpapers)
    imagemagick           # `magick` binary — Noctalia uses it to resize/cache wallpapers
    polkit_gnome          # Polkit agent (started by Hyprland exec-once)
    xdg-utils
    shared-mime-info
    desktop-file-utils

    # Clipboard history (wl-paste pipes into cliphist; fuzzel is the picker)
    cliphist
    fuzzel

    # Idle management + animated wallpapers
    hypridle
    awww                  # animated wallpaper daemon (formerly swww)

    # Note: no separate notification daemon needed — Noctalia registers its own
    # D-Bus notification service.

    # Themes & icons
    adw-gtk3              # Adwaita-style theme for GTK3 apps
    papirus-icon-theme
    adwaita-icon-theme
  ];

  # Keybind cheatsheet — shown in a floating terminal via Super+F1
  environment.etc."keybinds.md".text = ''
    ╔══════════════════════════════════════════════════════════════╗
    ║                   KEYBIND CHEATSHEET                        ║
    ║              Super = Windows/Meta key  (q to close)         ║
    ╚══════════════════════════════════════════════════════════════╝

    APPLICATIONS
      Super + Return          Terminal (kitty)
      Super + E               Files (Nautilus)
      Super + R               App launcher (Noctalia)
      Super + Shift + V       Clipboard history picker (cliphist + fuzzel)
      Super + F1              This cheatsheet

    NOCTALIA PANELS
      Super + N               Network panel (control center)
      Super + B               Bluetooth panel (control center)
      Super + A               Quick settings (control center)
      Super + X               Power / session menu

    WINDOWS
      Super + Q               Close window
      Super + F               Fullscreen (toggle)
      Super + M               Maximize (toggle, keeps gaps/bars)
      Super + V               Toggle floating
      Super + C               Center floating window
      Super + P               Toggle pseudo-tile
      Super + Shift + P       Pin window (always on top)
      Super + T               Toggle split direction (dwindle)
      Alt   + Tab             Cycle windows

    FOCUS  (also works with arrow keys)
      Super + H / ←           Focus left
      Super + L / →           Focus right
      Super + K / ↑           Focus up
      Super + J / ↓           Focus down

    MOVE WINDOW  (Shift + direction)
      Super + Shift + H/L/K/J Move window in that direction

    RESIZE WINDOW  (Ctrl + direction)
      Super + Ctrl + H/L/K/J  Grow/shrink window

    WORKSPACES
      Super + 1–9, 0          Switch to workspace 1–10 (0 = 10)
      Super + Shift + 1–9, 0  Move window to workspace
      Super + S               Toggle scratchpad
      Super + Shift + S       Send to scratchpad
      Super + Scroll ↑/↓      Cycle workspaces

    LAYOUT SWITCHING
      Super + Alt + D         Dwindle layout (default)
      Super + Alt + M         Master layout
      Super + Alt + W         Scrolling layout (like Niri/PaperWM)
      Super + Alt + O         Monocle layout (one window at a time)

    MOUSE
      Super + Left drag       Move window
      Super + Right drag      Resize window

    SCREENSHOT
      Print                   Capture region → annotate (swappy)
      Shift + Print           Capture full screen → annotate
      Ctrl + Print            Capture region → clipboard

    MEDIA KEYS
      XF86AudioRaiseVolume    Volume up
      XF86AudioLowerVolume    Volume down
      XF86AudioMute           Toggle mute
      XF86AudioPlay/Prev/Next Media control (via Noctalia)
      XF86MonBrightnessUp/Dn  Screen brightness

    SYSTEM
      Super + Delete          Lock screen (Noctalia)
      Super + Shift + E       Exit Hyprland session
  '';
}
