{ pkgs, ... }:

let
  ghostty-config = pkgs.runCommand "ghostty-config" { } ''
    mkdir -p $out/themes
    cp ${./config.ghostty} $out/config
    cp -r ${./themes/noctalia} $out/themes/noctalia
  '';
in
{
  xdg.configFile."ghostty".source = ghostty-config;
}
