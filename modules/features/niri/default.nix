{ inputs, pkgs, ... }:

{
  imports = [
    inputs.dankMaterialShell.homeModules.dank-material-shell
  ];

  # DMS é o shell histórico do seu setup com niri (noctalia continua
  # sendo o do mango — os binds em config.kdl chamam `noctalia msg
  # ...` e continuam funcionando se você preferir manter noctalia
  # também no niri; os dois shells vão coexistir instalados, é só
  # não deixar os dois RODANDO ao mesmo tempo pra não duplicar
  # painel/barra. Ajusta o autostart em config.kdl conforme decidir.
  programs.dank-material-shell.enable = true;

  xdg.configFile."niri/config.kdl".source = ./config.kdl;
}
