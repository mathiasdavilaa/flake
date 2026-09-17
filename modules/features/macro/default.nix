{ pkgs, ... }:

let
  macro-mouse = pkgs.writeShellScript "macro-mouse" (
    builtins.readFile ./macro-mouse.sh
  );
in
{
  systemd.user.services."macro-mouse@" = {
    Unit = {
      Description = "Auto Farm Mouse Macro (%i)";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";

      # jq entra no PATH explicitamente: o serviço systemd --user
      # não usa o PATH interativo do shell, e o script precisa de
      # jq pra ler a resolução via mmsg.
      Path = [ pkgs.jq ];

      ExecStart = "${macro-mouse} %i";

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
