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
      # Cache the key in the agent after the first use so the PIN is asked once.
      AddKeysToAgent = "yes";
    };
  };

  # ssh-agent, so the YubiKey is "unlocked" (PIN entered) once per session instead
  # of on every commit/push. Runs as a systemd user service and exports
  # SSH_AUTH_SOCK into the session ($XDG_RUNTIME_DIR/ssh-agent). The key is loaded
  # on demand: `git cc` (home/dev.nix) runs `ssh-add` if the agent is empty, and
  # github.com pushes add it via AddKeysToAgent above.
  #
  # NOTE: this caches the FIDO2 *PIN* only. The physical *touch* is user-presence
  # enforced by the YubiKey itself and is required per-signature — it cannot be
  # cached. (Dropping it would mean regenerating the key with `no-touch-required`,
  # which weakens it and needs re-registering on GitHub.)
  services.ssh-agent.enable = true;
}
