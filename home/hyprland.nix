{ pkgs, ... }: let
  polkitAgent = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
in {
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    # settings = {} is intentionally empty — everything is in extraConfig using the
    # native Lua API (hl.monitor, hl.env, hl.config, hl.bind, hl.window_rule, etc.)
    # which is the correct format for Hyprland 0.55+.

    extraConfig = ''
      -- ── Monitor ──────────────────────────────────────────────────────────────
      hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 2 })

      -- ── Autostart ────────────────────────────────────────────────────────────
      hl.on("hyprland.start", function()
        hl.exec_cmd("${polkitAgent}")
        -- nm-applet omitted: networkmanager_dmenu (Super+N) handles WiFi, no tray icon needed
        hl.exec_cmd("blueman-applet")
        hl.exec_cmd("hypridle")
        -- clipboard history (stores text + images via wl-paste → cliphist)
        hl.exec_cmd("wl-paste --type text  --watch cliphist store")
        hl.exec_cmd("wl-paste --type image --watch cliphist store")
      end)

      -- ── Environment ──────────────────────────────────────────────────────────
      -- XDG session identity (fixes portal malfunctions)
      hl.env("XDG_CURRENT_DESKTOP",                 "Hyprland")
      hl.env("XDG_SESSION_TYPE",                    "wayland")
      hl.env("XDG_SESSION_DESKTOP",                 "Hyprland")

      -- Toolkit backends
      hl.env("GDK_BACKEND",                         "wayland,x11,*")
      hl.env("QT_QPA_PLATFORM",                     "wayland;xcb")
      hl.env("QT_QPA_PLATFORMTHEME",                "qt6ct")
      hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
      hl.env("SDL_VIDEODRIVER",                     "wayland")
      hl.env("CLUTTER_BACKEND",                     "wayland")

      -- Cursor / HiDPI
      hl.env("XCURSOR_SIZE",                        "24")
      hl.env("HYPRCURSOR_SIZE",                     "24")

      -- App-specific
      hl.env("MOZ_ENABLE_WAYLAND",                  "1")
      hl.env("_JAVA_AWT_WM_NONREPARENTING",         "1")
      hl.env("NIXOS_OZONE_WL",                      "1")
      hl.env("WLR_NO_HARDWARE_CURSORS",             "1")

      -- ── Config ───────────────────────────────────────────────────────────────
      hl.config({
        general = {
          gaps_in          = 5,
          gaps_out         = 10,
          border_size      = 2,
          col = {
            active_border   = { colors = {"rgba(cba6f7ff)", "rgba(89b4faff)"}, angle = 45 },
            inactive_border = "rgba(313244aa)",
          },
          layout           = "dwindle",
          resize_on_border = true,
        },

        decoration = {
          rounding = 8,
          blur = {
            enabled = true,
            size    = 5,
            passes  = 2,
          },
          shadow = {
            enabled      = true,
            range        = 10,
            render_power = 3,
            color        = "rgba(1a1a2ecc)",
          },
        },

        animations = {
          enabled = true,
        },

        dwindle = {
          preserve_split = true,
        },

        master = {
          new_status = "master",
        },

        scrolling = {
          follow_focus = true,
          wrap_focus   = true,
        },

        input = {
          kb_layout    = "us",
          follow_mouse = 1,
          sensitivity  = 0,
          touchpad = {
            natural_scroll = true,
            tap_to_click   = true,
            drag_lock      = true,
          },
        },

        misc = {
          force_default_wallpaper  = 0,
          disable_hyprland_logo    = true,
          disable_splash_rendering = true,
          enable_swallow           = true,
          swallow_regex            = "^(kitty|foot)$",
          mouse_move_enables_dpms  = true,
          key_press_enables_dpms   = true,
        },
      })

      -- ── Curves ───────────────────────────────────────────────────────────────
      hl.curve("ease",     { type = "bezier", points = { {0.4, 0},    {0.2, 1}    } })
      hl.curve("overshot", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

      -- ── Animations ───────────────────────────────────────────────────────────
      hl.animation({ leaf = "windows",    enabled = true, speed = 4, bezier = "overshot" })
      hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "ease",     style = "popin 80%" })
      hl.animation({ leaf = "border",     enabled = true, speed = 8, bezier = "ease" })
      hl.animation({ leaf = "fade",       enabled = true, speed = 4, bezier = "ease" })
      hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "overshot", style = "slide" })

      -- ── Gestures ─────────────────────────────────────────────────────────────
      hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

      -- ── Keybindings ──────────────────────────────────────────────────────────
      local mod = "SUPER"

      -- Core
      hl.bind(mod .. " + Return",    hl.dsp.exec_cmd("kitty"))
      hl.bind(mod .. " + Q",         hl.dsp.window.close())
      hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())
      hl.bind(mod .. " + F",         hl.dsp.window.fullscreen())
      hl.bind(mod .. " + M",         hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
      hl.bind(mod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mod .. " + C",         hl.dsp.window.center())
      hl.bind(mod .. " + P",         hl.dsp.window.pseudo())
      hl.bind(mod .. " + SHIFT + P", hl.dsp.window.pin())
      hl.bind(mod .. " + T",         hl.dsp.layout("togglesplit"))

      -- Window cycling
      hl.bind("ALT + Tab", function()
        hl.dispatch(hl.dsp.window.cycle_next())
        hl.dispatch(hl.dsp.window.bring_to_top())
      end)

      -- Applications
      hl.bind(mod .. " + R",         hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
      hl.bind(mod .. " + E",         hl.dsp.exec_cmd("nautilus"))
      hl.bind(mod .. " + Delete",    hl.dsp.exec_cmd("noctalia msg session lock"))
      hl.bind(mod .. " + F1",        hl.dsp.exec_cmd("foot --title Cheatsheet --override font_size=13 -e less /etc/keybinds.md"))
      hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"))

      -- Noctalia control-center panels (network/bluetooth are tabs of the control
      -- center; panel-toggle accepts a tab key to open it directly on that tab)
      hl.bind(mod .. " + N", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center network"))
      hl.bind(mod .. " + B", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center bluetooth"))
      hl.bind(mod .. " + A", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
      hl.bind(mod .. " + X", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))

      -- Layout switching (hyprctl keyword updates general.layout at runtime)
      hl.bind(mod .. " + ALT + D", hl.dsp.exec_cmd("hyprctl keyword general:layout dwindle"))
      hl.bind(mod .. " + ALT + M", hl.dsp.exec_cmd("hyprctl keyword general:layout master"))
      hl.bind(mod .. " + ALT + W", hl.dsp.exec_cmd("hyprctl keyword general:layout scrolling"))
      hl.bind(mod .. " + ALT + O", hl.dsp.exec_cmd("hyprctl keyword general:layout monocle"))

      -- Focus (vim + arrows)
      hl.bind(mod .. " + H",     hl.dsp.focus({ direction = "left" }))
      hl.bind(mod .. " + L",     hl.dsp.focus({ direction = "right" }))
      hl.bind(mod .. " + K",     hl.dsp.focus({ direction = "up" }))
      hl.bind(mod .. " + J",     hl.dsp.focus({ direction = "down" }))
      hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
      hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
      hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
      hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

      -- Move windows (directions: l/r/u/d per dispatcher docs)
      hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
      hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
      hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
      hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))

      -- Resize (relative = true for pixel-delta mode)
      hl.bind(mod .. " + CTRL + H", hl.dsp.window.resize({ x = -60, y =   0, relative = true }))
      hl.bind(mod .. " + CTRL + L", hl.dsp.window.resize({ x =  60, y =   0, relative = true }))
      hl.bind(mod .. " + CTRL + K", hl.dsp.window.resize({ x =   0, y = -60, relative = true }))
      hl.bind(mod .. " + CTRL + J", hl.dsp.window.resize({ x =   0, y =  60, relative = true }))

      -- Workspaces 1–10 (key 0 = workspace 10)
      for i = 1, 10 do
        local key = i % 10
        hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
        hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
      end

      -- Special workspace (scratchpad)
      hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
      hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

      -- Scroll through workspaces
      hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
      hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

      -- Mouse drag / resize
      hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
      hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

      -- Screenshots
      hl.bind("Print",         hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | swappy -f -"))
      hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grim - | swappy -f -"))
      hl.bind("CTRL + Print",  hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))

      -- Media / brightness (locked = works on lock screen)
      hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("noctalia msg volume-up"),       { locked = true })
      hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("noctalia msg volume-down"),     { locked = true })
      hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("noctalia msg volume-mute"),     { locked = true })
      hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("noctalia msg media toggle"),    { locked = true })
      hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("noctalia msg media previous"),  { locked = true })
      hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("noctalia msg media next"),      { locked = true })
      hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("noctalia msg brightness-up"),   { locked = true })
      hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), { locked = true })

      -- ── Noctalia Integration ─────────────────────────────────────────────────
      -- Blur the Noctalia bar and panel layer surfaces
      hl.layer_rule({
        name  = "noctalia-blur",
        match = { namespace = "noctalia-background-.*" },
        blur         = true,
        blur_popups  = true,
        ignore_alpha = 0.5,
      })

      -- ── Window Rules ─────────────────────────────────────────────────────────
      hl.window_rule({
        name  = "cheatsheet",
        match = { title = "^(Cheatsheet)$" },
        float = true, size = "920 560", center = true, stay_focused = true,
      })

      hl.window_rule({ name = "float-pavucontrol", match = { class = "^(pavucontrol)$" },           float = true })
      hl.window_rule({ name = "float-blueman",      match = { class = "^(blueman-manager)$" },       float = true })
      hl.window_rule({ name = "float-nm",           match = { class = "^(nm-connection-editor)$" },  float = true })
      hl.window_rule({ name = "float-calculator",   match = { class = "^(gnome-calculator)$" },      float = true })
      hl.window_rule({ name = "float-printer",      match = { class = "^(system-config-printer)$" }, float = true })

      hl.window_rule({ name = "pip",       match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true })
      hl.window_rule({ name = "1password", match = { class = "^(1Password)$" },          float = true, center = true })
      hl.window_rule({ name = "steam",     match = { class = "^(steam_app_)(.*)$" },     fullscreen = true })
    '';
  };
}
