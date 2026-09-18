{ pkgs, ... }:

let
  # Empacota tudo numa única pasta (com o arquivo renomeado pro nome que o
  # ghostty espera) pra virar UM symlink só em ~/.config/ghostty — do jeito
  # que já era antes. Trocar de "pasta inteira" pra "arquivos individuais"
  # dentro do mesmo nome de topo trava o home-manager (o symlink antigo,
  # somente-leitura, ainda existe quando ele tenta criar os novos links
  # dentro dele).
  ghostty-config = pkgs.runCommand "ghostty-config" { } ''
    mkdir -p $out/themes
    cp ${./config.ghostty} $out/config
    cp -r ${./themes/noctalia} $out/themes/noctalia
  '';
in
{
  xdg.configFile."ghostty".source = ghostty-config;
}
