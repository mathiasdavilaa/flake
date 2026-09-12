{ pkgs, inputs, ... }:

{
  imports = [
    ../../modules/common.nix
    ./optimization.nix
  ];

  networking.hostName = "tarnished";
  services.displayManager.defaultSession = "plasma";

  programs.fish.enable = true;

  users.users.mad = {
    isNormalUser = true;
    shell = pkgs.fish;

    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "ydotool"
    ];

    home = "/home/mad";
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  programs.ydotool.enable = true;

  environment.systemPackages = with pkgs; [
    spotify
    firefox
    chromium
    proton-vpn
    proton-pass
    discord
    zapzap
    localsend
    prismlauncher
    ydotool
    mangohud
    protonup-qt
    brmodelo
    kdePackages.dolphin
  ];
}
