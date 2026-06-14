{ pkgs, ... }: {
  # Starship prompt theme — the user's own (powerline segments, Catppuccin palette),
  # kept as a verbatim file so the Nerd Font glyphs survive intact. programs.starship
  # is enabled in home/apps.nix with no `settings`, so the module doesn't write its own
  # starship.toml and there's no collision with this file.
  xdg.configFile."starship.toml".source = ./starship.toml;

  # Polyglot runtime/version manager (Node, Python, Go, …). Successor to asdf/rtx;
  # manages its own per-project tools + env via mise.toml.
  # Install a runtime with e.g. `mise use -g node@lts`.
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

      # `git cc` — commit using the message Claude Code prepped at
      # <git-dir>/CLAUDE_COMMIT_MSG, so I run the actual (YubiKey-signed) commit
      # myself in my own shell while Claude only writes the message + stages files.
      # The leading `!` runs the body through a shell so `$(git rev-parse
      # --git-dir)` is evaluated — that keeps it working from subdirectories and
      # inside git worktrees (where the git dir isn't a literal `.git`).
      alias.cc = ''!git commit -F "$(git rev-parse --git-dir)/CLAUDE_COMMIT_MSG"'';
    };
  };

  # Teach Claude Code the `git cc` workflow globally. Files in ~/.claude/rules/
  # are a native Claude Code feature: every *.md there is auto-loaded as a
  # user-level rule at session start and applies to every project on the
  # machine, no per-project setup. Declarative + shared across hosts, so a fresh
  # laptop build picks it up too. (Read-only nix symlink, so it can't be edited
  # in-app — change it here and rebuild.) Pairs with alias.cc above.
  home.file.".claude/rules/git-cc.md".text = ''
    # Git commit workflow (YubiKey-signed)

    When asked to commit:
    1. Write the commit message to `<git-dir>/CLAUDE_COMMIT_MSG` (resolve
       `<git-dir>` with `git rev-parse --git-dir`).
    2. Stage the relevant files.
    3. Do NOT run the commit yourself. Tell me to run `git cc` in my own
       terminal — it's a global git alias that commits from that file. The
       commit is signed by my YubiKey (FIDO2 SSH key), which needs an
       interactive touch a sandboxed shell can't provide.

    `git cc` and this rule are configured together in home/dev.nix.
  '';

  home.packages = with pkgs; [
    claude-code          # agentic coding CLI

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
