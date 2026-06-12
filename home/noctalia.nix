{ ... }: let
  wallpaperDir = "/home/ni/Pictures/Wallpaper";
in {
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      theme = {
        mode   = "dark";
        source = "wallpaper";
      };
      wallpaper = {
        enabled      = true;
        default.path = "${wallpaperDir}/lone_tree_day.webp";
      };
    };
  };

  home.file."Pictures/Wallpaper/lone_tree_day.webp".source   = ../assets/lone_tree_day.webp;
  home.file."Pictures/Wallpaper/lone_tree_night.webp".source = ../assets/lone_tree_night.webp;
  home.file."Pictures/Wallpaper/waves_violet.webp".source    = ../assets/waves_violet.webp;
}
