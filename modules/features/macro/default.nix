{ pkgs, ... }:

let
  # writeShellScriptBin (não writeShellApplication): mantém o
  # `set -uo pipefail` original dos scripts tal como escrito, sem
  # forçar `-e` nem shellcheck em cima. Cada um vira um comando de
  # verdade em $out/bin/<nome> — sempre executável, sem depender de
  # chmod no git nem de caminho fixo em ~/.config.
  macrosDir = ./macros;

  # MACROS_DIR aponta pro store: macro-mouse descobre e carrega
  # cada macros/*.macro sozinho, então adicionar um macro é só
  # criar um arquivo novo ali — não precisa editar este .nix nem
  # o macro-mouse.sh.
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
  # os três comandos ficam disponíveis no PATH: macro-mouse,
  # macro-toggle, get-mousepos. É o que o bind SUPER,F8 no mango
  # chama agora (`macro-toggle portal`), em vez de um caminho fixo
  # dentro de ~/.config/mango/scripts.
  # jq também precisa estar no PATH interativo, não só no da unit
  # systemd — macro-mouse --capture/--pos rodam direto do shell.
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

      # jq entra no PATH explicitamente: o serviço systemd --user
      # não usa o PATH interativo do shell, e o script precisa de
      # jq pra ler a resolução via mmsg.
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
