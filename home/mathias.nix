{ inputs, pkgs, ... }:

{
  imports = [
    ../modules/features/zed
    ../modules/features/fastfetch
    ../modules/features/ghostty
    ../modules/features/mango
    inputs.dms.homeModules.dank-material-shell
  ];

  home.username = "mathias";
  home.homeDirectory = "/home/mathias";
  home.stateVersion = "24.05";

  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 20;

    gtk.enable = true;
    x11.enable = true;
  };

  programs.dank-material-shell = {
      enable = true;
      systemd = {
        enable = true;
        restartIfChanged = true;
      };
    };

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -g fish_greeting
      fastfetch
    '';

    shellAliases = {
      nixos = "zeditor ~/flake";
      nrs = "cd ~/flake && git add . && sudo nixos-rebuild switch --impure --flake ~/flake#laptop";
      nru = "nix flake update --flake ~/flake";
      nixclean = "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5";
      ff = "fastfetch";
    };
  };

  programs.yazi.enable = true;

  programs.home-manager.enable = true;
}
