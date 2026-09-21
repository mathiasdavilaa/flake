{ pkgs, ... }:

{
  home.packages = [ pkgs.fastfetch ];

  xdg.configFile = {
    "fastfetch/config.jsonc".source = ./config.jsonc;
    "fastfetch/ascii.txt".source = ./ascii.txt;
    "fastfetch/ascii2.txt".source = ./ascii2.txt;
  };
}
