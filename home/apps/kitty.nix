{ pkgs, ... }: {
  # Kitty terminal
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 13;
    };
    settings = {
      window_padding_width     = 0;
      background_opacity       = "0.95";
      cursor_blink_interval    = 0;
      confirm_os_window_close  = 0;
      enable_audio_bell        = false;
      shell                    = "${pkgs.fish}/bin/fish";
    };
    # Noctalia generates ~/.config/kitty/themes/noctalia.conf with wallpaper-matched
    # colors at runtime. globinclude silently skips the file if it doesn't exist yet.
    extraConfig = "globinclude themes/noctalia.conf";
  };
}
