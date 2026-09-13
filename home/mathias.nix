{ config, pkgs, ... }:

{
  imports = [
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

  home.username = "mathias";
  home.homeDirectory = "/home/mathias";
  home.stateVersion = "24.05";

  xdg.configFile."fastfetch".source = ../modules/features/fastfetch;
  xdg.configFile."kitty".source = ../modules/features/kitty;

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -g fish_greeting
      fastfetch
    '';

    shellAliases = {
      ncfg = "zediter ~/.nixos";
      nrs = "git add . && sudo nixos-rebuild switch --impure --flake ~/flake#laptop";
      nru = "nix flake update --flake ~/.nixos";
      ff = "fastfetch";
    };
  };

  programs.home-manager.enable = true;
}
