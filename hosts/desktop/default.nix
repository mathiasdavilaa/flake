{ pkgs, inputs, ... }:

{
  imports = [
    ../../modules/common.nix
    ./optimization.nix
    ../../modules/wm/plasma.nix
  ];

  #========================================
  # settings for my ssd
  boot = {
    kernelParams = [
      "nvme_core.default_ps_max_latency_us=0"
      "usbcore.autosuspend=-1"
    ];
    loader.limine = {
      secureBoot.enable = true;
      extraEntries = ''/Windows
        protocol: efi_chainload
        image_path: boot():/EFI/Microsoft/Boot/bootmgfw.efi''    ;
    };
  };
  fileSystems."/mad" = {
    device = "/dev/nvme0n1p1";
    fsType = "ext4";
    options = [ "nofail" ];
  };
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.udisks2.filesystem-mount-system" &&
          subject.user == "mad") {
        return polkit.Result.YES;
      }
    });
  '';
  #========================================

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
    #gaming
    prismlauncher
    mangohud

    #browsers and media
    inputs.zen-browser.packages.${pkgs.system}.default
    spotify
    firefox

    #proton
    proton-vpn
    proton-pass
    protonup-qt

    #chat
    discord
    zapzap

    #files
    localsend
    kdePackages.dolphin

    #utils
    usbutils
  ];
}
