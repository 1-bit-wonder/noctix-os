{ config, ... }: {
  # NVIDIA proprietary driver for the RTX 2080 (TU104, Turing).
  #
  # Why this exists: without it, NixOS falls back to nouveau, which on Turing
  # binds the Wayland color-management protocols (wlr-gamma-control, hyprland-ctm)
  # but never applies them to the scanout — so every night-light path (Noctalia's
  # gamma toggle AND hyprsunset's CTM in home/linux/nightlight.nix) was a silent
  # no-op. The proprietary driver applies CTM, so hyprsunset's night light works.
  # It's also the expected driver for a Turing card (nouveau has no reclocking →
  # poor performance).
  #
  # Imported from flake.nix for the live host ONLY, not the VM ISO variant — a
  # QEMU guest has no NVIDIA GPU and "nvidia" videoDrivers would fail to start a
  # session there.
  #
  # Setting videoDrivers to nvidia also auto-blacklists nouveau.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # KMS — mandatory for Wayland/Hyprland (sets nvidia-drm.modeset=1).
    modesetting.enable = true;

    # Suspend/resume VRAM save-restore is the usual cause of black screens on
    # wake. Off by default on an always-on desktop; enable only if you hit
    # corruption after resume.
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Closed kernel module, not the open one. Turing IS supported by the open
    # modules, but the closed module is the most battle-tested on this generation
    # — the conservative pick for a live machine. Flip to `open = true` later to
    # move to the open stack (NVIDIA's recommended direction for Turing+).
    open = false;

    # nvidia-settings GUI on PATH.
    nvidiaSettings = true;

    # Stable driver branch for the running kernel.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Hyprland-on-NVIDIA session hints. modeset is handled above; GBM_BACKEND is
  # intentionally omitted (it breaks GBM in some Electron/Chromium apps).
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };
}
