{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
    ../modules/features/zed
  ];

  systemd.user.services.macro-mouse = {
    Unit = {
      Description = "Auto Farm Mouse Macro";
    };

    Service = {
      Type = "simple";

      ExecStart = "${pkgs.writeShellScript "macro-mouse" (
        builtins.readFile ../modules/features/scripts/macro-mouse.sh
      )}";

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

  xdg.configFile."niri".source = ../modules/features/niri;

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
      nrs = "git add . && sudo nixos-rebuild switch --impure --flake ~/.nixos#desktop";
      nru = "nix flake update --flake ~/.nixos";
      ff = "fastfetch";
    };
  };

  programs.home-manager.enable = true;
}
