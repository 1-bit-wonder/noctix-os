{ ... }: {
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      theme = {
        mode   = "dark";
        source = "wallpaper";
      };
      wallpaper = {
        enabled             = true;
        directory_light     = "/home/ni/Pictures/Wallpapers/light";
        directory_dark      = "/home/ni/Pictures/Wallpapers/dark";
        fill_mode           = "crop";
        transition_duration = 1500;
        default.path        = "/home/ni/Pictures/Wallpapers/dark/lone_tree_night.webp";
      };
    };
  };

  # Wallpapers installed into light/dark subdirs so Noctalia can switch sets by theme mode.
  home.file."Pictures/Wallpapers/light/lone_tree_day.webp".source   = ../assets/light/lone_tree_day.webp;
  home.file."Pictures/Wallpapers/dark/lone_tree_night.webp".source  = ../assets/dark/lone_tree_night.webp;
  home.file."Pictures/Wallpapers/dark/waves_violet.webp".source     = ../assets/dark/waves_violet.webp;
}
