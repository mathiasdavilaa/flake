{ config, pkgs, ... }:

{
  # NVIDIA driver and Wayland support
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = true;
  };

  boot.kernelParams = [
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia-drm.modeset=1"
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # keep the kernel memory limits suitable for modern games
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
  };

  # NVIDIA VA-API support and direct video acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    __GL_MaxFramesAllowed = "1";
  };

  # gameMode prioritizes CPU performance while a game is running
  programs.gamemode = {
    enable = true;
    enableRenice = true;

    settings = {
      general = {
        desiredgov = "performance";
        desiredprof = "performance";
        softrealtime = "auto";
        renice = 10;
        ioprio = 0;
        inhibit_screensaver = 1;
        disable_splitlock = 1;
      };
    };
  };

  services.irqbalance.enable = true;

  # gamescope provides a dedicated game compositor and frame control
  programs.gamescope = {
    enable = true;
    capSysNice = true;
    enableWsi = true;
  };

  # steam Input compatibility for Wayland sessions
  programs.steam.extest.enable = true;

  # gaming diagnostics and performance tools
  environment.systemPackages = with pkgs; [
    gamemode
    gamescope
    mangohud
    nvtopPackages.nvidia
    vulkan-tools
    mesa-demos
  ];
}
