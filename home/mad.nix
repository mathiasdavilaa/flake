{ pkgs, inputs, ... }:

{
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
    ../modules/features/zed
    ../modules/features/fastfetch
    ../modules/features/ghostty
    ../modules/features/mango
    inputs.dms.homeModules.dank-material-shell
  ];

  programs.dank-material-shell = {
    enable = true;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
  };

  home.username = "mad";
  home.homeDirectory = "/home/mad";
  home.stateVersion = "24.05";

  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 20;

    gtk.enable = true;
    x11.enable = true;
  };

  services.flatpak = {
    packages = [
      {
        appId = "org.vinegarhq.Sober";
        origin = "flathub";
      }
    ];

    overrides = {
      "org.vinegarhq.Sober" = {
        Environment = {
          FLATPAK_GL_DRIVERS = "host";
        };
      };
    };
  };

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -g fish_greeting
      fastfetch
    '';

    shellAliases = {
      ncfg = "zeditor ~/flake";
      nrs = "cd ~/flake && git add . && sudo nixos-rebuild switch --impure --flake ~/flake#desktop";
      nru = "nix flake update --flake ~/flake";
      ff = "fastfetch";
    };
  };

  programs.yazi.enable = true;

  programs.home-manager.enable = true;
}
