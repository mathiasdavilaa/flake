{ pkgs, xwayland-satellite-v081, ... }:

{
  # niri já vem no nixpkgs — não precisa de flake input próprio
  # (diferente do mango, que não está no nixpkgs ainda).
  programs.niri.enable = true;

  # o niri integra com xwayland-satellite sozinho desde a 25.08: ele
  # cria o socket X11, exporta $DISPLAY e sobe o xwayland-satellite
  # sob demanda quando um app X11 conecta — só precisa do binário no
  # PATH. Reusa o mesmo pin (v0.8.1) que o mango já usa.
  environment.systemPackages = [ xwayland-satellite-v081 ];
}
