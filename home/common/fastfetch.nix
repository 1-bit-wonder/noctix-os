{ ... }: {
  # fastfetch — system info / specs banner. The home-manager module installs the
  # package and writes ~/.config/fastfetch/config.jsonc from `settings`. It's run
  # on interactive shell start by home/common/fish.nix.
  programs.fastfetch = {
    enable = true;

    # A compact, square-ish layout that matches the desktop's aesthetic. Colors
    # are left to fastfetch's auto-detection so they track the terminal palette
    # (which Noctalia themes per-wallpaper).
    settings = {
      logo = {
        source = "nixos_small";
        padding = { top = 1; right = 3; };
      };

      display = {
        separator = "  ";
      };

      modules = [
        { type = "title"; format = "{user-name}@{host-name}"; }
        "separator"
        { type = "os";        key = "  os";    }
        { type = "kernel";    key = "  kernel"; }
        { type = "uptime";    key = "  uptime"; }
        { type = "packages";  key = "  pkgs";  }
        { type = "shell";     key = "  shell"; }
        { type = "wm";        key = "  wm";    }
        { type = "terminal";  key = "  term";  }
        "break"
        { type = "cpu";       key = "  cpu";   }
        { type = "gpu";       key = "  gpu";   }
        { type = "memory";    key = "  mem";   }
        { type = "disk";      key = "  disk";  format = "{size-used} / {size-total}"; }
        "break"
        { type = "colors"; symbol = "square"; }
      ];
    };
  };
}
