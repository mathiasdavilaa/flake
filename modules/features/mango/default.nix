{ inputs, ... }:

{
  imports = [
    inputs.mangowm.hmModules.mango
  ];

  wayland.windowManager.mango = {
    enable = true;
    autostart_sh = ''
      dbus-update-activation-environment --systemd --all
      systemctl --user start mango-session.target
      fcitx5 &
    '';

    settings = {
      sloppyfocus = 0;
      scroller_structs = 1;

      xkb_rules_layout = "us,br";
      xkb_rules_options = "caps:escape";
      repeat_rate = 30;
      repeat_delay = 400;

      mouse_accel_profile = 2;
      mouse_accel_speed = -0.6;

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

      monitorrule = [
        "name:^HDMI-A-1$,rr:1"
        "name:^DE-3$,rr:0"
      ];

      tagrule = [
        "id:1,monitor_name:HDMI-A-1,layout_name:vertical_scroller"
        "id:2,monitor_name:HDMI-A-1,layout_name:vertical_scroller"
        "id:3,monitor_name:HDMI-A-1,layout_name:vertical_scroller"
        "id:4,monitor_name:HDMI-A-1,layout_name:vertical_scroller"
        "id:5,monitor_name:HDMI-A-1,layout_name:vertical_scroller"
        "id:6,monitor_name:HDMI-A-1,layout_name:vertical_scroller"
        "id:7,monitor_name:HDMI-A-1,layout_name:vertical_scroller"
        "id:8,monitor_name:HDMI-A-1,layout_name:vertical_scroller"
        "id:9,monitor_name:HDMI-A-1,layout_name:vertical_scroller"

        "id:1,monitor_name:DP-3,layout_name:scroller"
        "id:2,monitor_name:DP-3,layout_name:scroller"
        "id:3,monitor_name:DP-3,layout_name:scroller"
        "id:4,monitor_name:DP-3,layout_name:scroller"
        "id:5,monitor_name:DP-3,layout_name:scroller"
        "id:6,monitor_name:DP-3,layout_name:scroller"
        "id:7,monitor_name:DP-3,layout_name:scroller"
        "id:8,monitor_name:DP-3,layout_name:scroller"
        "id:9,monitor_name:DP-3,layout_name:scroller"
      ];
      devicerule = [
        "name:ydotoold virtual device,accel_profile:0,accel_speed:0"
      ];

      bind = [
        "SUPER,w,spawn,ghostty"
        "SUPER,q,killclient"
        "SUPER,e,spawn,ghostty --title=Yazi -e yazi"
        "SUPER,r,spawn_shell,mmsg reload_config"

        "SUPER+Alt,F4,quit"

        "SUPER,d,spawn,dms ipc call spotlight toggle"
        "SUPER,F2,spawn,dms ipc call clipboard toggle"
        "SUPER,Escape,spawn,dms ipc call powermenu toggle"
        "SUPER,F1,spawn,dms ipc call keybinds toggle mangowc"
        "NONE,Print,spawn,dms screenshot"
        "NONE,XF86AudioRaiseVolume,spawn,dms ipc call audio increment 3"
        "NONE,XF86AudioLowerVolume,spawn,dms ipc call audio decrement 3"
        "NONE,XF86AudioMute,spawn,dms ipc call audio mute"
        "NONE,XF86MonBrightnessUp,spawn,dms ipc call brightness increment 5"
        "NONE,XF86MonBrightnessDown,spawn,dms ipc call brightness decrement 5"

        "SUPER+SHIFT,f,togglefullscreen"
        "SUPER,f,set_proportion,1.0"
        "SUPER,v,togglefloating"

        "SUPER,equal,resizewin,+150,0"
        "SUPER,minus,resizewin,-150,0"
        "SUPER,Prior,set_proportion,0.5"
        "SUPER,Next,set_proportion,0.8"

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
      ];

      mousebind = [
        "SUPER,btn_left,moveresize,curmove"
        "SUPER,btn_right,moveresize,curresize"
      ];
    };
  };

  xdg.configFile."mango/scripts/move-window-right-silent.sh".source =
    ./scripts/move-window-right-silent.sh;
}
