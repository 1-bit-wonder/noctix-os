{ pkgs, ... }: {
  # Solaar's tray icon defaults to a battery-level glyph, which at bar size reads
  # like a clipboard. `--battery-icons solaar` makes it use Solaar's own logo
  # instead, but that flag is launch-time only and nothing persists it. Overriding
  # the .desktop Exec is fragile here — Noctalia's launcher caches the package's
  # system .desktop by absolute path, bypassing any user-level override. So bake
  # the flag into the binary: every caller (launcher, autostart, CLI) inherits it,
  # regardless of which .desktop launches `solaar`. symlinkJoin wraps the existing
  # build — no rebuild from source. The module below installs this via pkgs.solaar.
  nixpkgs.overlays = [
    (final: prev: {
      solaar = prev.symlinkJoin {
        name = "solaar-logo-tray";
        paths = [ prev.solaar ];
        nativeBuildInputs = [ prev.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/solaar --add-flags "--battery-icons solaar"
        '';
        # Preserve the passthru the wrap would otherwise drop — the logitech
        # NixOS module reads `solaar.udev` for its udev rules package.
        passthru = (prev.solaar.passthru or { }) // { inherit (prev.solaar) udev; };
      };
    })
  ];

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
          # SPEED — wheel speed needed to break into free-spin (0..50; 50 = never
          # frees). logiops `threshold` == Solaar's "Scroll Wheel Ratchet Speed"
          # (smart-shift). Higher = stays ratcheted (clicky) longer; 10 felt
          # almost always-free, which read as a jump. Raise toward 50 for a
          # mostly-ratcheted wheel, drop toward 10 for an eager free-spin.
          threshold = 30;
          # TORQUE — resistance of the detents (the MX Master 4 has a haptic
          # ratchet). logiops `torque` == Solaar's "Scroll Wheel Ratchet Torque"
          # (scroll-ratchet-torque), a 0..100 %. Pinned to the default 50 so it's
          # explicit in-config rather than implied; the Solaar 10 you may see is
          # `ignore`d/inactive. Raise for stiffer, more pronounced clicks.
          torque = 50;
        };

        # Smooth (hi-res) scrolling — handled NATIVELY by the kernel
        # hid-logitech-hidpp driver + libinput, which we let own it.
        #
        # Do NOT set `hires = true` here. That makes logid intercept the wheel's
        # raw v120 events and re-emit them itself; logid 0.3.x's hi-res
        # accumulator mishandles the fast event bursts smartshift's free-spin
        # produces, causing scroll REVERSALS and OVER-SCROLL. Since we don't
        # invert or retarget the wheel, logid has no reason to touch it at all.
        # Leaving hires=false hands tick→scroll translation to libinput (robust),
        # while smartshift (a separate HID++ register, above) keeps the free-spin.
        hiresscroll = {
          hires = false;
          invert = false;
          target = false;
        };

        dpi = 1500;

        # Thumb-gesture button (the big button under the thumb rest, cid 0xC3 =
        # 195). Left as a template — uncomment after confirming the name above,
        # then map directions to keybinds you actually use. KEY_* names come from
        # <linux/input-event-codes.h>. These examples drive the Hyprland focus
        # binds already in home/linux/hyprland.nix (Super+H/J/K/L).
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

  # logiops boot race. At boot, logid starts as soon as multi-user.target is up
  # — before the MX Master is awake over HID++. The Bolt receiver enumerates
  # almost immediately, but the wireless mouse only answers ~8s later (watch
  # `journalctl -u logid -b`: "Detected receiver" then, seconds on, "Device
  # found: MX Master 4"). logid applies smartshift/scroll config to that
  # half-ready device, it doesn't take, and the wheel scrolls erratically —
  # random jumps and backward kicks. A manual `systemctl restart logid` once the
  # device is settled re-applies cleanly and fixes it. (This is the actual cause
  # of the "smooth yesterday, jumpy again after reboot" regression — NOT Solaar
  # and NOT the logiops/Solaar register conflict; see the scroll-jump note.)
  #
  # Automate the re-apply: when the receiver (046d:c548) enumerates, pull in a
  # oneshot that waits for the mouse to wake, then restarts logid. The receiver
  # exposes several hidraw interfaces so the rule fires a few times — systemd
  # coalesces the start jobs while the unit is still in its ExecStartPre sleep,
  # so the delay also debounces down to a single clean restart. Fires on boot,
  # resume-from-suspend, and receiver replug; idle HID++ sleep/wake does NOT
  # re-enumerate USB, so it does not fire on every wheel wake. Restarting logid
  # reopens hidraw in userspace (no USB re-enumeration), so there is no loop.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c548", TAG+="systemd", ENV{SYSTEMD_WANTS}+="logid-reapply.service"
  '';

  systemd.services.logid-reapply = {
    description = "Re-apply logiops config after the MX Master settles (logid boot-race workaround)";
    serviceConfig = {
      Type = "oneshot";
      # Cover the receiver-up -> mouse-awake gap (~8s observed); generous margin.
      # Bump if a cold boot still comes up jumpy. The wheel may be briefly
      # erratic until this fires, then settles for the rest of the session.
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
      ExecStart = "${pkgs.systemd}/bin/systemctl restart logid.service";
    };
  };
}
