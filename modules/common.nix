{ pkgs, inputs, ... }: {
  imports = [
    inputs.silent-sddm.nixosModules.default
  ];

  nixpkgs.config.allowUnfree = true;
  networking.networkmanager.enable = true;

  services.flatpak.enable = true;

  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.limine = {
    enable = true;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";

  # o mango faz a parte dele do text-input-v3 (é feature anunciada
  # no README dele), mas esse protocolo só funciona com um input
  # method DAEMON do outro lado pra receber os eventos de teclado e
  # devolver o texto composto (commit_string) — sem isso, um app
  # que pede foco via text-input-v3 (comum em engines de jogo/UI
  # customizada, como o Sober/Roblox) fica esperando texto que
  # nunca chega, mesmo com teclado normal us/br. Esse flake nunca
  # teve nenhum IME configurado — suspeito forte de ser essa a causa
  # do bug "não consigo digitar nada" no Sober. fcitx5 aqui só pelo
  # papel de "ponte" pro protocolo — não precisa de addon de CJK
  # pros seus layouts (us,br).
  #
  # waylandFrontend=true é essencial e NÃO é o padrão do módulo do
  # NixOS (default: false) — sem isso o fcitx5 conversa por
  # XIM/X11 em vez do protocolo Wayland de verdade, o que explica
  # "funcionou uma vez e depois parou": o caminho via XIM depende
  # de X11/Xwayland estar presente e focado do jeito certo,
  # bem mais frágil que o input-method-v2 nativo.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # tema SilentSDDM (github.com/uiriansan/SilentSDDM). "default" é o
  # tema neutro (fundo estático), sem personagem/vídeo — troca pra
  # "rei", "ken", "silvia", "nord", "gruvbox", "catppuccin-mocha"
  # etc (lista completa em SilentSDDM/configs/*.conf) se preferir
  # outra estética. O módulo cuida de fontes/QT/tema sozinho.
  programs.silentSDDM = {
    enable = true;
    theme = "default";
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    font-awesome
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  environment.systemPackages = with pkgs; [
    git
    lazygit
    ghostty
    fastfetch
    xwayland
    mpv
    imv
    neovim
    sbctl
    ydotool
    libnotify

    #coding languages
    python3
  ];

  system.stateVersion = "24.05";
}
