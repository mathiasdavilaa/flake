{ pkgs, ... }:

let
  macrosDir = ./macros;

  macro-mouse = pkgs.writeShellScriptBin "macro-mouse" ''
    MACROS_DIR="${macrosDir}"
    ${builtins.readFile ./macro-mouse.sh}
  '';

  macro-toggle = pkgs.writeShellScriptBin "macro-toggle" (
    builtins.readFile ./macro-toggle.sh
  );

  get-mousepos = pkgs.writeShellScriptBin "get-mousepos" (
    builtins.readFile ./get-mousepos.sh
  );
in
{
  home.packages = [
    macro-mouse
    macro-toggle
    get-mousepos
    pkgs.jq
  ];

  systemd.user.services."macro-mouse@" = {
    Unit = {
      Description = "Auto Farm Mouse Macro (%i)";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      Path = [ pkgs.jq ];

      ExecStart = "${macro-mouse}/bin/macro-mouse %i";

      Environment = [
        "YDOTOOL_SOCKET=/run/ydotoold/socket"
      ];

      # mata o script e os 'sleep' filhos junto
      KillMode = "control-group";
      KillSignal = "SIGTERM";
      TimeoutStopSec = 3;
      Restart = "no";
    };
  };
}
