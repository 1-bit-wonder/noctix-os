{ ... }: {
  # hypridle — lock screen after 5 min idle, display off after 5m30s.
  # Lock via the Noctalia v5 IPC (`noctalia msg session lock`). The old
  # `noctalia-shell ipc call lockScreen lock` was legacy v4 syntax for a binary
  # that doesn't exist in this build, so idle-lock was silently broken.
  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
      lock_cmd        = noctalia msg session lock
      before_sleep_cmd = noctalia msg session lock
      after_sleep_cmd  = hyprctl dispatch dpms on
    }

    listener {
      timeout  = 300
      on-timeout = noctalia msg session lock
    }

    listener {
      timeout  = 330
      on-timeout = hyprctl dispatch dpms off
      on-resume  = hyprctl dispatch dpms on
    }
  '';

}
