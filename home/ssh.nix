{ ... }: {
  # SSH client — enough that `git push` over SSH "just works" once the YubiKey's
  # resident key has been exported to ~/.ssh (a one-time `ssh-keygen -K`, since a
  # physical touch can't be declared). programs.ssh also creates ~/.ssh itself.
  #
  # The key is NOT in this repo on purpose (public repo): export it per-machine with
  #   cd ~/.ssh && ssh-keygen -K     # touch + PIN; writes id_ecdsa_sk_rk[.pub]
  # After that, pushing to GitHub uses the key below directly and prompts for a touch —
  # no ssh-agent or manual `ssh-add` needed.
  programs.ssh = {
    enable = true;
    # Opt out of home-manager's legacy default "*" block (deprecated); its values are
    # just OpenSSH's own defaults, so there's nothing to carry over.
    enableDefaultConfig = false;
    settings."github.com" = {
      # FIDO2 resident SSH key (sk-ecdsa) — the same key used for commit signing.
      IdentityFile   = "~/.ssh/id_ecdsa_sk_rk";
      IdentitiesOnly = true;
    };
  };
}
