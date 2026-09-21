{ pkgs, inputs, ... }: {
  imports = [
    inputs.silent-sddm.nixosModules.default
  ];

  nixpkgs.config.allowUnfree = true;
  networking.networkmanager.enable = true;

  services.flatpak.enable = true;
  services.udisks2.enable = true;

  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.limine = {
    enable = true;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # github.com/uiriansan/SilentSDDM
  programs.silentSDDM = {
    enable = true;
    theme = "default";
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
    xwayland
    mpv
    imv
    neovim
    sbctl
    ydotool
    libnotify

    # Coding languages
    python3
  ];

  system.stateVersion = "24.05";
}
