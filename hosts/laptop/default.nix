{ pkgs, inputs, ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/wm/mangowm.nix
  ];

  networking.hostName = "nixos";
  services.displayManager.defaultSession = "mango";

  programs.fish.enable = true;

  users.users.mathias = {
    isNormalUser = true;
    shell = pkgs.fish;

    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "ydotool"
    ];

    home = "/home/mathias";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  programs.ydotool.enable = true;

  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages.${pkgs.system}.default
    zapzap
    vscode
    proton-pass
    proton-vpn
    wev
    nautilus
  ];
}
