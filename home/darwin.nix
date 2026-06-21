{ pkgs, ... }:
let
  # Homebrew installs to a different prefix per architecture: Intel (x86_64,
  # luna-macbook-intel) uses /usr/local; Apple Silicon (aarch64) uses
  # /opt/homebrew. Detected from the build platform so this file is ready for an
  # Apple Silicon Mac too, even though luna (Intel) is the only Darwin host today.
  brewPrefix = if pkgs.stdenv.hostPlatform.isAarch64 then "/opt/homebrew" else "/usr/local";
in {
  # macOS-only home config — imported by the nix-darwin host only. Cross-platform
  # tools (fish, git, helix, the CLI toolchain) come from home/common/; this
  # file adds the Mac-specific bits on top.
  home.homeDirectory = "/Users/ni";

  # Homebrew lives outside Nix. Put its bin/sbin on PATH so brew-installed casks
  # and formulae resolve, and export HOMEBREW_PREFIX for tools that consult it.
  # Prepended only when the prefix actually exists, so a Nix-only Mac is unaffected.
  programs.fish.interactiveShellInit = ''
    if test -d ${brewPrefix}/bin
      fish_add_path --prepend --global ${brewPrefix}/bin ${brewPrefix}/sbin
    end
  '';

  home.sessionVariables = {
    HOMEBREW_PREFIX = brewPrefix;
    # Silence the macOS Bash-is-deprecated nag in any bash subshells; fish is the
    # real login shell (set via common.nix programs.fish).
    BASH_SILENCE_DEPRECATION_WARNING = "1";
  };
}
