{ pkgs, inputs, ... }:

{
  imports = [
    ../../modules/common.nix
    ./optimization.nix
    ../../modules/wm/plasma.nix
  ];

  boot.loader.limine = {
    secureBoot.enable = true;

    extraEntries = ''/Windows
      protocol: efi_chainload
      image_path: boot():/EFI/Microsoft/Boot/bootmgfw.efi''    ;
  };

  fileSystems."/mad" = {
    device = "/dev/disk/by-uuide/a8d26eb8-c63c-419a-9d8b-ccdf5b8b2411";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.device-timeout=30s" ];
  };

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
