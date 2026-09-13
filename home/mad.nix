{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
    ../modules/features/zed
  ];


  systemd.user.services."macro-mouse@" = {
    Unit = {
      Description = "Auto Farm Mouse Macro (%i)";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";

      ExecStart = "${pkgs.writeShellScript "macro-mouse" (
        builtins.readFile ../modules/features/scripts/macro-mouse.sh
      )} %i";

      Environment = [
        "YDOTOOL_SOCKET=/run/ydotoold/socket"
      ];

      KillMode = "control-group";
      Restart = "no";
    };
  };

  home.username = "mad";
  home.homeDirectory = "/home/mad";
  home.stateVersion = "24.05";

  home.pointerCursor = {
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

  xdg.configFile."fastfetch".source = ../modules/features/fastfetch; #home manager
  xdg.configFile."kitty".source = ../modules/features/kitty; #home manager

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -g fish_greeting
      fastfetch
    '';

    shellAliases = {
      ncfg = "zeditor ~/flake";
      nrs = "git add . && sudo nixos-rebuild switch --impure --flake ~/flake#desktop";
      nru = "nix flake update --flake ~/flake";
      ff = "fastfetch";
    };
  };

  programs.home-manager.enable = true;
}
