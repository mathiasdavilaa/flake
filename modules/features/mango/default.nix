{ inputs, ... }:

{
  imports = [
    inputs.mangowm.hmModules.mango
  ];

  wayland.windowManager.mango = {
    enable = true;

    # autostart_sh em vez de exec-once=[lista]: essa opção é
    # documentada explicitamente pra isso, sem ambiguidade de como
    # múltiplos exec-once viram linhas. O "&" é obrigatório aqui —
    # é UM script rodando em sequência, sem background o noctalia
    # nunca devolve o terminal e o fcitx5 nunca chega a subir.
    autostart_sh = ''
      noctalia &
      fcitx5 &
    '';

    settings = {
      sloppyfocus = 0;

      # --- input (antigo devices.conf) ---
      xkb_rules_layout = "us,br";
      xkb_rules_options = "caps:escape";
      repeat_rate = 30;
      repeat_delay = 400;

      mouse_accel_profile = 2;
      mouse_accel_speed = -0.6;

      # scroll_method / trackpad_natural_scrolling removidos por
      # enquanto: a wiki documenta esses nomes, mas o build acusa
      # "Unknown keyword" pros dois — a wiki não bate com a versão
      # nightly pinada no seu flake. Veja meu comentário no chat:
      # preciso do /etc/mango/config.conf real do seu sistema pra
      # acertar isso sem mais chute.

      # --- aparência (antigo decorations.conf) ---
      # NOTA: isso substitui os valores que estavam em noctalia.conf
      # (um snapshot gerado automaticamente pelo Noctalia). Optei
      # por NÃO portar esse snapshot pro Nix — ele era regenerado
      # em tempo real pelo Noctalia, e essa pasta inteira já estava
      # symlinkada pro Nix store (somente leitura) antes dessa
      # migração, então o Noctalia provavelmente já não conseguia
      # reescrever ali mesmo; era um valor estático desatualizado,
      # não uma sincronização viva de verdade. Se o Noctalia
      # realmente escreve nesse arquivo em tempo real no seu
      # sistema, me avisa que eu religo o `source=./noctalia.conf`
      # (e paro de gerenciar esse caminho específico via Nix, pra
      # sobrar gravável).
      borderpx = 2;
      border_radius = 15;
      gappiv = 2;
      gappih = 2;
      gappov = 2;
      gappoh = 2;
      rootcolor = "0x323232ff";
      bordercolor = "0x444444ff";
      dropcolor = "0x8FBA7C55";
      splitcolor = "0xEB441EFF";
      focuscolor = "0xc66b25ff";
      urgentcolor = "0xad401fff";

      # --- regras (antigo rules.conf) ---
      tagrule = [
        "id:*,layout_name:scroller"
      ];
      # windowrule desativada no arquivo antigo — mantida comentada:
      # "isfloating:1,title:^Yazi$"
      devicerule = [
        "name:ydotoold virtual device,accel_profile:0,accel_speed:0"
      ];

      # --- binds (antigo binds.conf) ---
      bind = [
        # Main binds
        "SUPER,w,spawn,ghostty"
        "SUPER,q,killclient"
        "SUPER,e,spawn,ghostty --title=Yazi -e yazi"
        ''SUPER,r,spawn_shell,mmsg reload_config && noctalia msg notification-show "Mango recarregado" "Configuração atualizada"''

        # Mango
        "SUPER+Alt,F4,quit"

        # Noctalia
        "SUPER,d,spawn,noctalia msg panel-toggle launcher"
        "SUPER,F2,spawn,noctalia msg panel-toggle clipboard"
        "SUPER,Escape,spawn,noctalia msg panel-toggle session"
        "SUPER,F1,spawn,noctalia msg panel-toggle kenn/keybind-cheatsheet:cheatsheet"
        "NONE,Print,spawn,noctalia msg screenshot-region"
        "NONE,XF86AudioRaiseVolume,spawn,noctalia msg volume-up"
        "NONE,XF86AudioLowerVolume,spawn,noctalia msg volume-down"
        "NONE,XF86AudioMute,spawn,noctalia msg volume-mute"
        "NONE,XF86MonBrightnessUp,spawn,noctalia msg brightness-up"
        "NONE,XF86MonBrightnessDown,spawn,noctalia msg brightness-down"

        # Window
        "SUPER+SHIFT,f,togglefullscreen"
        # "SUPER,f,togglemaximizescreen" # desativada no arquivo antigo
        "SUPER,f,set_proportion,1.0"
        "SUPER,v,togglefloating"

        "SUPER,equal,resizewin,+150,0"
        "SUPER,minus,resizewin,-150,0"
        "SUPER,Prior,set_proportion,0.5"
        "SUPER,Next,set_proportion,0.8"

        # Navigation
        "SUPER,h,focusdir,left"
        "SUPER,k,focusdir,up"
        "SUPER,j,focusdir,down"
        "SUPER,l,focusdir,right"
        "SUPER,left,focusdir,left"
        "SUPER,up,focusdir,up"
        "SUPER,down,focusdir,down"
        "SUPER,right,focusdir,right"

        "SUPER,1,view,1,0"
        "SUPER,2,view,2,0"
        "SUPER,3,view,3,0"
        "SUPER,4,view,4,0"
        "SUPER,5,view,5,0"
        "SUPER,6,view,6,0"
        "SUPER,7,view,7,0"
        "SUPER,8,view,8,0"
        "SUPER,9,view,9,0"

        "SUPER+SHIFT,1,tag,1"
        "SUPER+SHIFT,2,tag,2"
        "SUPER+SHIFT,3,tag,3"
        "SUPER+SHIFT,4,tag,4"
        "SUPER+SHIFT,5,tag,5"
        "SUPER+SHIFT,6,tag,6"
        "SUPER+SHIFT,7,tag,7"
        "SUPER+SHIFT,8,tag,8"
        "SUPER+SHIFT,9,tag,9"

        "SUPER+CTRL,1,tagsilent,1"
        "SUPER+CTRL,2,tagsilent,2"
        "SUPER+CTRL,3,tagsilent,3"
        "SUPER+CTRL,4,tagsilent,4"
        "SUPER+CTRL,5,tagsilent,5"
        "SUPER+CTRL,6,tagsilent,6"
        "SUPER+CTRL,7,tagsilent,7"
        "SUPER+CTRL,8,tagsilent,8"
        "SUPER+CTRL,9,tagsilent,9"

        "SUPER+SHIFT,h,exchange_client,left"
        "SUPER+SHIFT,l,exchange_client,right"
        "SUPER+SHIFT,left,exchange_client,left"
        "SUPER+SHIFT,right,exchange_client,right"
        "SUPER+SHIFT,k,exchange_client,up"
        "SUPER+SHIFT,j,exchange_client,down"
        "SUPER+SHIFT,up,exchange_client,up"
        "SUPER+SHIFT,down,exchange_client,down"

        "SUPER,home,focusmon,right"
        "SUPER+SHIFT,home,tagmon,right"
        "SUPER+CTRL,home,spawn,~/.config/mango/scripts/move-window-right-silent.sh"

        # DEBUG — usa pra checar o estado do mango quando o Sober
        # travar em fullscreen. Loga num arquivo em vez de abrir
        # terminal de propósito: abrir uma janela nova por cima
        # pode, sozinho, tirar o jogo do fullscreen (muita coisa
        # sai do fullscreen ao perder foco/monitor), o que
        # contaminaria o teste. Depois de apertar, sai do jogo
        # (ou Alt+Tab) e roda: cat /tmp/mango-debug.log
        "SUPER+SHIFT,i,spawn_shell,{ echo === $(date +%T) ===; mmsg get focusing-client; mmsg -m; echo; } >> /tmp/mango-debug.log 2>&1"

        # SCRIPT
        "SUPER,F8,spawn_shell,macro-toggle portal"
      ];

      mousebind = [
        "SUPER,btn_left,moveresize,curmove"
        "SUPER,btn_right,moveresize,curresize"
      ];
    };
  };

  # move-window-right-silent.sh ainda é referenciado por um bind
  # acima (~/.config/mango/scripts/...) — o módulo do mango só
  # gerencia config.conf/autostart.sh, então esse script continua
  # sendo linkado à parte.
  xdg.configFile."mango/scripts/move-window-right-silent.sh".source =
    ./scripts/move-window-right-silent.sh;
}
