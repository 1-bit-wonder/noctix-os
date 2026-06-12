{ ... }: {
  # networkmanager_dmenu — use fuzzel as the dmenu picker
  xdg.configFile."networkmanager-dmenu/config.ini".text = ''
    [dmenu]
    dmenu_command = fuzzel --dmenu

    [dmenu_passphrase]
    obscure = true
  '';

  # hypridle — lock screen after 5 min idle, display off after 5m30s
  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
      lock_cmd        = noctalia-shell ipc call lockScreen lock
      before_sleep_cmd = noctalia-shell ipc call lockScreen lock
      after_sleep_cmd  = hyprctl dispatch dpms on
    }

    listener {
      timeout  = 300
      on-timeout = noctalia-shell ipc call lockScreen lock
    }

    listener {
      timeout  = 330
      on-timeout = hyprctl dispatch dpms off
      on-resume  = hyprctl dispatch dpms on
    }
  '';

}
