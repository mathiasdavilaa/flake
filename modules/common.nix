{ pkgs, inputs, ... }: {
  nixpkgs.config.allowUnfree = true;
  networking.networkmanager.enable = true;

  services.flatpak.enable = true;

  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.limine = {
    enable = true;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    font-awesome
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  environment.systemPackages = with pkgs; [
    git
    lazygit
    ghostty
    fastfetch
    xwayland
    mpv
    imv
    neovim
    sbctl
    ydotool
    libnotify

    #coding languages
    python3
  ];

  system.stateVersion = "24.05";
}
