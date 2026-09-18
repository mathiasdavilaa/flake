{ lib, ... }:

{
  # Copia a pasta inteira (config.conf, binds.conf, devices.conf, rules.conf,
  # decorations.conf, noctalia.conf, scripts/) pro store e symlinka
  # ~/.config/mango pra ela — preserva os `source=./xxx.conf` relativos do
  # mango e os bits de execução dos scripts. Só exclui este default.nix.
  xdg.configFile."mango".source = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.difference ./. ./default.nix;
  };
}
