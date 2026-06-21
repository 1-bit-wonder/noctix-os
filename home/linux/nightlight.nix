{ pkgs, ... }: let
  nightTemp = 4000;  # evening warmth, in Kelvin

  # Manual override for the running hyprsunset daemon. hyprsunset has no
  # "get temperature" request, so we track the current warmth + on/off marker in
  # runtime files rather than query it. The scheduled profiles below reassert
  # themselves at the next 06:00 / 19:00 transition, so this is just a nudge.
  nightlightctl = pkgs.writeShellScriptBin "nightlightctl" ''
    set -eu
    state="''${XDG_RUNTIME_DIR:-/tmp}/nightlight.temp"
    on="$state.on"
    temp=$(cat "$state" 2>/dev/null || echo ${toString nightTemp})
    clamp() { if [ "$1" -lt 2500 ]; then echo 2500; elif [ "$1" -gt 6500 ]; then echo 6500; else echo "$1"; fi; }
    apply() { hyprctl hyprsunset temperature "$1" >/dev/null; echo "$1" >"$state"; touch "$on"; }
    case "''${1:-toggle}" in
      toggle)
        if [ -f "$on" ]; then hyprctl hyprsunset identity >/dev/null; rm -f "$on";
        else apply "$temp"; fi ;;
      warmer) apply "$(clamp $((temp - 250)))" ;;   # lower K = redder
      cooler) apply "$(clamp $((temp + 250)))" ;;   # higher K = bluer
      *) echo "usage: nightlightctl {toggle|warmer|cooler}" >&2; exit 1 ;;
    esac
  '';
in {
  # Night light via hyprsunset, NOT Noctalia's built-in toggle. Noctalia shifts
  # color through the wlr-gamma-control protocol, which this host's NVIDIA RTX
  # 2080 rejects ("[gamma] gamma control failed for an output" in its log).
  # hyprsunset instead uses Hyprland's hyprland-ctm-control-v1 (a color
  # transform matrix), which the proprietary driver DOES honor. Leave Noctalia's
  # night light toggle off — it's a no-op on this GPU.
  services.hyprsunset = {
    enable = true;
    settings = {
      # Fixed clock-time profiles (hyprsunset doesn't compute real solar times).
      # The most recently passed profile wins, cycling daily. Only temperature is
      # set — gamma is left at its default (1.0 = full); note hyprsunset's profile
      # gamma is a 0–1 fraction, NOT a percent, so `gamma = 100` means 10000% and
      # makes the daemon exit 1 ("Gamma invalid: 10000%").
      profile = [
        { time = "6:00";  identity = true; }              # daytime: no tint
        { time = "19:00"; temperature = nightTemp; }      # evening: warm
      ];
    };
  };

  home.packages = [ nightlightctl ];
}
