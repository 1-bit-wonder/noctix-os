{ pkgs, ... }: {
  # Starship prompt theme — the user's own (powerline segments, Catppuccin palette),
  # kept as a verbatim file so the Nerd Font glyphs survive intact. programs.starship
  # is enabled in home/common/starship.nix with no `settings`, so the module doesn't write its own
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

  # VS Code — Astro's officially recommended editor. Extensions are pinned
  # declaratively from nixpkgs (current HM schema nests these under
  # profiles.default). The Astro extension bundles the language server,
  # .astro syntax highlighting, and formatting.
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = [
        pkgs.vscode-extensions.astro-build.astro-vscode
        pkgs.vscode-extensions.biomejs.biome   # fast JS/TS/JSON linter + formatter
      ];
      userSettings = {
        # Use the Astro extension as the formatter for .astro files, and Biome
        # for the JS/TS/JSON family it handles.
        "[astro]"."editor.defaultFormatter" = "astro-build.astro-vscode";
        "[javascript]"."editor.defaultFormatter" = "biomejs.biome";
        "[javascriptreact]"."editor.defaultFormatter" = "biomejs.biome";
        "[typescript]"."editor.defaultFormatter" = "biomejs.biome";
        "[typescriptreact]"."editor.defaultFormatter" = "biomejs.biome";
        "[json]"."editor.defaultFormatter" = "biomejs.biome";
        "[jsonc]"."editor.defaultFormatter" = "biomejs.biome";
        "editor.formatOnSave" = true;
      };
    };
  };

  # Git — commit signing via the YubiKey FIDO2 resident SSH key (no GPG needed).
  # Reuses ~/.ssh/id_ecdsa_sk_rk.pub, the same sk-ecdsa key used to push.
  # Identity is declared here, not via `git config --global` — home-manager
  # symlinks ~/.config/git/config into the read-only Nix store, so the imperative
  # command fails with "Read-only file system". Edit here + rebuild instead.
  # The email is GitHub's no-reply form to keep a real address out of this public
  # repo. Signing is a no-op until the YubiKey key exists on the machine, so it's
  # safe on hosts without the key yet (the ISO, or a freshly set-up Mac).
  programs.git = {
    enable = true;
    settings = {
      user.name        = "Ni";
      user.email       = "22556482+1-bit-wonder@users.noreply.github.com";
      gpg.format       = "ssh";
      user.signingKey  = "~/.ssh/id_ecdsa_sk_rk.pub";
      commit.gpgSign   = true;
      tag.gpgSign      = true;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      # Open commit messages in Helix (not the EDITOR=nano default).
      core.editor      = "hx";

      # `git cc` — commit using the message Claude Code prepped at
      # <git-dir>/CLAUDE_COMMIT_MSG, so I run the actual (YubiKey-signed) commit
      # myself in my own shell while Claude only writes the message + stages files.
      # The leading `!` runs the body through a shell so `$(git rev-parse
      # --git-dir)` is evaluated — that keeps it working from subdirectories and
      # inside git worktrees (where the git dir isn't a literal `.git`).
      #
      # Two extras vs a plain `git commit -F`:
      #   - `ssh-add` first if the agent is empty, so the YubiKey PIN is entered
      #     once per session (the agent caches it; see services.ssh-agent in
      #     home/common/ssh.nix). The touch is still required per commit.
      #   - `-e` opens the prepped message in Helix (core.editor above) for a
      #     final review/edit before the commit is created.
      alias.cc = ''!f() { ssh-add -l >/dev/null 2>&1 || ssh-add ~/.ssh/id_ecdsa_sk_rk; git commit -e -F "$(git rev-parse --git-dir)/CLAUDE_COMMIT_MSG"; }; f'';
    };
  };

  # Teach Claude Code the `git cc` workflow globally. Files in ~/.claude/rules/
  # are a native Claude Code feature: every *.md there is auto-loaded as a
  # user-level rule at session start and applies to every project on the
  # machine, no per-project setup. Declarative + shared across hosts (it's in
  # home/common/), so every NixOS and macOS host picks it up. (Read-only nix
  # symlink, so it can't be edited
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

    `git cc` and this rule are configured together in home/common/dev.nix.
  '';

  home.packages = with pkgs; [
    claude-code          # agentic coding CLI
    zed-editor           # zed — GPU-accelerated code editor

    # Modern CLI staples
    ripgrep              # rg — fast grep
    fd                   # fast find
    jq                   # JSON processor
    eza                  # modern ls
    tree
    lazygit              # git TUI

    # Web deploy CLIs
    wrangler             # Cloudflare Workers/Pages deploy + dev
    cloudflared          # Cloudflare Tunnel daemon
    netlify-cli          # `netlify` — deploy + dev for Netlify

    # Nix tooling (for working on this flake)
    nixd                 # Nix language server
    alejandra            # Nix formatter
    nix-output-monitor   # `nom` — readable build output
  ];
}
