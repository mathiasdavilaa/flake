{ pkgs, inputs, ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/wm/plasma.nix
  ];

  networking.hostName = "nixos";
  services.displayManager.defaultSession = "plasma";

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

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  programs.ydotool.enable = true;

  environment.systemPackages = with pkgs; [
    firefox
    inputs.zen-browser.packages.${pkgs.system}.default
    zapzap
    vscode
    proton-pass
    proton-vpn
  ];
}
