{ ... }: {
  # Logitech MX Keys S (keyboard) + MX Master 4 (mouse).
  #
  # On Linux there is no Logitech Options+. Two tools cover it:
  #   - Solaar  — pairing, battery, DPI, per-key/per-button settings (GUI + CLI).
  #               Talks to devices over the Bolt/Unifying USB receiver or USB
  #               cable ONLY — it cannot manage a device connected via Bluetooth.
  #   - logiops — userspace HID++ daemon for smartshift, hi-res scroll and
  #               thumb-button gestures on the MX Master.
  # They coexist fine; logiops owns gestures/smartshift, Solaar owns pairing/battery.

  # Solaar. enableGraphical pulls in the GUI; both paths install
  # logitech-udev-rules so the devices are accessible without root (uaccess).
  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };

  # logiops (logid daemon). The `name` MUST match the device's HID++ name exactly
  # or none of this applies (the mouse still works as a plain pointer — nothing
  # breaks). The MX Master 4 is new; "MX Master 4" is a best guess. Verify with:
  #
  #     sudo systemctl stop logid
  #     sudo logid -v        # prints the connected device's exact name, then Ctrl-C
  #     sudo systemctl start logid
  #
  # then correct `name` below if it differs.
  services.logiops = {
    enable = true;
    config.devices = [
      {
        name = "MX Master 4";

        # Free-spinning wheel that ratchets at low speed / unlocks when flicked.
        # This is the SAME setting as Solaar's "Smart Shift" slider — both write
        # the same HID++ register, so let logiops own it and DON'T also set it in
        # Solaar (logid re-applies this on wake/reconnect and would clobber it).
        smartshift = {
          on = true;
          threshold = 10;   # lower = lighter flick frees the wheel (tuned to taste)
        };

        # Smooth (hi-res) scrolling.
        hiresscroll = {
          hires = true;
          invert = false;
          target = false;
        };

        dpi = 1500;

        # Thumb-gesture button (the big button under the thumb rest, cid 0xC3 =
        # 195). Left as a template — uncomment after confirming the name above,
        # then map directions to keybinds you actually use. KEY_* names come from
        # <linux/input-event-codes.h>. These examples drive the Hyprland focus
        # binds already in home/hyprland.nix (Super+H/J/K/L).
        #
        # buttons = [
        #   {
        #     cid = 195;   # 0xC3 — gesture button
        #     action = {
        #       type = "Gestures";
        #       gestures = [
        #         { direction = "Up";    mode = "OnRelease"; action = { type = "Keypress"; keys = [ "KEY_LEFTMETA" "KEY_K" ]; }; }
        #         { direction = "Down";  mode = "OnRelease"; action = { type = "Keypress"; keys = [ "KEY_LEFTMETA" "KEY_J" ]; }; }
        #         { direction = "Left";  mode = "OnRelease"; action = { type = "Keypress"; keys = [ "KEY_LEFTMETA" "KEY_H" ]; }; }
        #         { direction = "Right"; mode = "OnRelease"; action = { type = "Keypress"; keys = [ "KEY_LEFTMETA" "KEY_L" ]; }; }
        #       ];
        #     };
        #   }
        # ];
      }
    ];
  };
}
