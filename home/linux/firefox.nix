{ ... }: {
  # Firefox — managed by home-manager so extensions / policies can be added later
  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";  # keep legacy path (pre-26.05 default)
  };
}
