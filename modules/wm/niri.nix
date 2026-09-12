{ pkgs, inputs, xwayland-satellite-v081, ... }: {
  programs.niri.enable = true;

  environment.systemPackages = with pkgs; [
    inputs.dankmaterialshell.packages.${pkgs.system}.default
    quickshell
    matugen
    wireplumber
    pipewire
    brightnessctl
    playerctl
    xdg-utils
    libnotify
    grim
    slurp
    wl-clipboard

    xwayland-satellite-v081
  ];
}
