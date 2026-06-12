{ pkgs, ... }: {
  # Shell prompt — fish integration is enabled automatically by home-manager
  programs.starship.enable = true;

  # Per-directory environments + cached `nix develop` shells
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Polyglot runtime/version manager (Node, Python, Go, …). Successor to asdf/rtx.
  # Install a runtime with e.g. `mise use -g node@lts`. Chosen over fnm because it
  # is not Node-only and pairs cleanly with direnv.
  programs.mise.enable = true;

  # Fuzzy finder, smarter `cd`, nicer `cat`
  programs.fzf.enable    = true;
  programs.zoxide.enable = true;
  programs.bat.enable    = true;

  # GitHub CLI
  programs.gh.enable = true;

  # git-delta — syntax-highlighted diffs, wired into git
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  # Git — commit signing via the YubiKey FIDO2 resident SSH key (no GPG needed).
  # Reuses ~/.ssh/id_ecdsa_sk_rk.pub, the same sk-ecdsa key used to push.
  # NOTE: set your identity per-machine with `git config --global user.{name,email}`;
  # it's intentionally not baked into this public repo. Signing is no-op until the
  # YubiKey key exists on the machine, so it's safe on the laptop stub / ISO.
  programs.git = {
    enable = true;
    settings = {
      gpg.format       = "ssh";
      user.signingKey  = "~/.ssh/id_ecdsa_sk_rk.pub";
      commit.gpgSign   = true;
      tag.gpgSign      = true;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };

  home.packages = with pkgs; [
    # Modern CLI staples
    ripgrep              # rg — fast grep
    fd                   # fast find
    jq                   # JSON processor
    eza                  # modern ls
    tree
    lazygit              # git TUI

    # Nix tooling (for working on this flake)
    nixd                 # Nix language server
    alejandra            # Nix formatter
    nix-output-monitor   # `nom` — readable build output
  ];
}
