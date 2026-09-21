{ pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";

    extraPackages = with pkgs; [
      ffmpeg
      poppler
      imagemagick
      resvg
      chafa
      fd
      ripgrep
      fzf
      zoxide
      jq
      p7zip
      file
      wl-clipboard
      trash-cli
      sshfs
      ouch
      util-linux
    ];

    plugins = with pkgs.yaziPlugins; {
      smart-enter = smart-enter;
      smart-paste = smart-paste;
      full-border = {
        package = full-border;
        setup = true;
      };
      toggle-pane = toggle-pane;
      git = {
        package = git;
        setup = true;
        settings = {
          order = 1500;
        };
      };
      mount = mount;
      ouch = ouch;
    };

    settings = {
      mgr = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
        sort_sensitive = false;
        sort_reverse = false;
        linemode = "size";
        scrolloff = 5;
        mouse_events = [ "click" "scroll" "touch" ];
      };

      preview = {
        wrap = "yes";
        tab_size = 2;
        max_width = 1000;
        max_height = 1000;
      };

      opener = {
        edit = [
          {
            run = "zeditor \"$@\"";
            block = true;
            desc = "Zed";
          }
        ];

        open = [
          {
            run = "xdg-open \"$@\"";
            orphan = true;
            desc = "Open";
          }
        ];

        reveal = [
          {
            run = "xdg-open \"$(dirname \"$1\")\"";
            orphan = true;
            desc = "Reveal";
          }
        ];
      };

      open = {
        rules = [
          {
            use = "edit";
            mime = "text/*";
          }
          {
            use = "edit";
            mime = "application/json";
          }
          {
            use = "edit";
            mime = "application/x-nix";
          }
          {
            use = "open";
            mime = "*";
          }
        ];
      };
      plugin = {
        prepend_fetchers = [
          {
            url = "*";
            run = "git";
            group = "git";
          }
          {
            url = "*/";
            run = "git";
            group = "git";
          }
        ];

        prepend_previewers = [
          {
            mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}";
            run = "ouch";
          }
        ];
      };
    };

    keymap = {
      mgr.prepend_keymap = [
        {
          on = [ "<Enter>" ];
          run = "plugin smart-enter";
          desc = "Enter directory or open file";
        }
        {
          on = [ "p" ];
          run = "plugin smart-paste";
          desc = "Paste into hovered directory";
        }
        {
          on = [ "M" ];
          run = "plugin mount";
          desc = "Mount / unmount / eject devices";
        }
        {
          on = [ "g" "g" ];
          run = "plugin git";
          desc = "Git status";
        }
        {
          on = [ "T" ];
          run = "plugin toggle-pane max-preview";
          desc = "Maximize / restore preview";
        }
        {
          on = [ "C" ];
          run = "plugin ouch";
          desc = "Compress selected files";
        }
      ];
    };
  };

  # zoxide is used by Yazi's built-in `z` integration.
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
