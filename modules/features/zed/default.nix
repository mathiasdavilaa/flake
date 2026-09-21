{ pkgs, ... }:

{

  programs.zed-editor = {
    enable = true;
    defaultEditor = true;

    extensions = [
      "nix"

      "material-icon-theme"

      "make"
      "toml"
      "dockerfile"

      "git-firefly"

      "discord-presence"
    ];

    extraPackages = with pkgs; [

      gcc
      clang
      clang-tools
      gdb

      cmake
      gnumake
      ninja
      pkg-config

      nixd
      nil
      nixfmt-rfc-style

      rust-analyzer
      rustfmt

      python3
      pyright
      ruff

      git
      git-lfs
      lazygit

      jq
      ripgrep
      fd
    ];

    userSettings = {

      theme = {
        mode = "dark";
      };

      icon_theme = "Material Icon Theme";

      ui_font_size = 16;
      buffer_font_size = 15;

      ui_font_family = "JetBrainsMono Nerd Font";
      buffer_font_family = "JetBrainsMono Nerd Font";

      tab_size = 2;

      soft_wrap = "none";

      relative_line_numbers = false;

      show_whitespaces = "selection";

      cursor_blink = true;

      use_smartcase_search = true;

      seed_search_query_from_cursor = "always";

      show_completions_on_input = true;

      use_autoclose = true;

      use_on_type_format = false;

      format_on_save = "off";

      formatter = "language_server";

      terminal = {
        font_family = "JetBrainsMono Nerd Font";
        font_size = 14;

        shell = {
          program = "fish";
        };

        blinking = "terminal_controlled";

        working_directory = "current_project_directory";
      };

      git = {
        inline_blame = {
          enabled = false;
        };

        gutter = {
          enabled = true;
        };
      };

      file_scan_exclusions = [
        "**/.git"
        "**/.hg"
        "**/.svn"
        "**/node_modules"
        "**/target"
        "**/build"
        "**/.direnv"
        "**/result"
      ];

      project_panel = {
        dock = "left";
        default_width = 300;
        git_status = true;
      };

      minimap = {
        show = "never";
      };

      diagnostics = {
        inline = {
          enabled = true;
        };

        include_warnings = true;
      };

      languages = {

        Nix = {
          language_servers = [
            "nixd"
            "!nil"
          ];

          formatter = {
            external = {
              command = "nixfmt";
              arguments = [ "--" ];
            };
          };

          tab_size = 2;
        };

        C = {
          language_servers = [
            "clangd"
          ];

          formatter = {
            language_server = {
              name = "clangd";
            };
          };

          tab_size = 2;
        };

        Cpp = {
          language_servers = [
            "clangd"
          ];

          formatter = {
            language_server = {
              name = "clangd";
            };
          };

          tab_size = 2;
        };

        Rust = {
          language_servers = [
            "rust-analyzer"
          ];

          tab_size = 2;
        };

        Python = {
          language_servers = [
            "pyright"
          ];

          tab_size = 2;
        };
      };

      lsp = {
        discord_presence = {
          initialization_options = {
            application_id = "1263505205522337886";
            base_icons_url = "https://raw.githubusercontent.com/xhyrom/zed-discord-presence/main/assets/icons/";

            state = "Working on {filename}:{line_number}";
            details = "In {workspace}";

            large_image = "{base_icons_url}/{language:lo}.png";
            large_text = "{language:u}";

            small_image = "{base_icons_url}/zed.png";
            small_text = "Zed";

            idle = {
              timeout = 300;
              action = "change_activity";
              state = "Idling";
              details = "In Zed";
              large_image = "{base_icons_url}/zed.png";
              large_text = "Zed";
              small_image = "{base_icons_url}/idle.png";
              small_text = "Idle";
            };

            git_integration = true;
          };
        };
      };

      telemetry = {
        diagnostics = false;
        metrics = false;
      };
    };

    userKeymaps = [

      {
        context = "Workspace";

        bindings = {
          "ctrl-`" = "workspace::ToggleBottomDock";
        };
      }

      {
        context = "Workspace";

        bindings = {
          "ctrl-shift-b" = "task::Spawn";
        };
      }

      {
        context = "Workspace";

        bindings = {
          "f6" = "task::Rerun";
        };
      }

      {
        context = "Editor";

        bindings = {
          "f5" = [
            "task::Spawn"
            {
              task_name = "C++: Build & Run";
            }
          ];
        };
      }

      {
        context = "Workspace";

        bindings = {
          "f9" = "debugger::Start";
        };
      }

      {
        context = "Editor";

        bindings = {
          "ctrl-s" = "workspace::Save";
        };
      }

      {
        context = "Editor";

        bindings = {
          "ctrl-shift-i" = "editor::Format";
        };
      }

      {
        context = "Workspace";

        bindings = {
          "ctrl-p" = "file_finder::Toggle";
        };
      }

      {
        context = "Workspace";

        bindings = {
          "ctrl-shift-p" = "command_palette::Toggle";
        };
      }
    ];

    userTasks = [

      {
        label = "C++: Build & Run";

        command = ''
          set -e

          mkdir -p "$ZED_WORKTREE_ROOT/outputs"

          g++ \
            -std=c++23 \
            -Wall \
            -Wextra \
            -Wpedantic \
            -O2 \
            "$ZED_FILE" \
            -o "$ZED_WORKTREE_ROOT/outputs/$ZED_STEM"

          echo "==============================================="

          "$ZED_WORKTREE_ROOT/outputs/$ZED_STEM"

          echo ""
          echo "==============================================="
          echo "✓ A tarnished cannot become a Lord."
        '';

        cwd = "$ZED_WORKTREE_ROOT";

        save = "current";

        reveal = "always";
        hide = "never";

        show_summary = false;
        show_command = false;

        shell = {
          with_arguments = {
            program = "${pkgs.bash}/bin/bash";
            args = [
              "--noprofile"
              "--norc"
            ];
          };
        };

        use_new_terminal = false;

        allow_concurrent_runs = false;
      }

      {
        label = "C++: Build Debug";

        command = "bash";

        args = [
          "-c"
          ''
            set -e

            mkdir -p "$ZED_WORKTREE_ROOT/outputs"

            g++ \
              -std=c++23 \
              -Wall \
              -Wextra \
              -Wpedantic \
              -g \
              "$ZED_FILE" \
              -o "$ZED_WORKTREE_ROOT/outputs/$ZED_STEM"
          ''
        ];

        cwd = "$ZED_WORKTREE_ROOT";

        save = "current";

        reveal = "always";

        allow_concurrent_runs = false;
      }

      {
        label = "C++: Run";

        command = "bash";

        args = [
          "-c"
          ''exec "$ZED_WORKTREE_ROOT/outputs/$ZED_STEM"''
        ];

        cwd = "$ZED_WORKTREE_ROOT";

        reveal = "always";

        allow_concurrent_runs = false;
      }

      {
        label = "CMake: Configure";

        command = "cmake";

        args = [
          "-S"
          "$ZED_WORKTREE_ROOT"

          "-B"
          "$ZED_WORKTREE_ROOT/build"

          "-DCMAKE_BUILD_TYPE=Debug"
        ];

        cwd = "$ZED_WORKTREE_ROOT";

        reveal = "always";
      }

      {
        label = "CMake: Build";

        command = "cmake";

        args = [
          "--build"
          "$ZED_WORKTREE_ROOT/build"

          "-j8"
        ];

        cwd = "$ZED_WORKTREE_ROOT";

        reveal = "always";
      }

      {
        label = "Nix: Format";

        command = "nix";

        args = [
          "fmt"
          "$ZED_WORKTREE_ROOT"
        ];

        cwd = "$ZED_WORKTREE_ROOT";

        reveal = "always";
      }

      {
        label = "Nix: Flake Check";

        command = "nix";

        args = [
          "flake"
          "check"
          "$ZED_WORKTREE_ROOT"
        ];

        cwd = "$ZED_WORKTREE_ROOT";

        reveal = "always";
      }

      {
        label = "NixOS: Rebuild Laptop";

        command = "sudo";

        args = [
          "nixos-rebuild"
          "switch"
          "--flake"
          "$ZED_WORKTREE_ROOT#laptop"
        ];

        cwd = "$ZED_WORKTREE_ROOT";

        reveal = "always";
      }

      {
        label = "NixOS: Rebuild Desktop";

        command = "sudo";

        args = [
          "nixos-rebuild"
          "switch"
          "--flake"
          "$ZED_WORKTREE_ROOT#desktop"
        ];

        cwd = "$ZED_WORKTREE_ROOT";

        reveal = "always";
      }

      {
        label = "Rust: Build";

        command = "cargo";

        args = [
          "build"
        ];

        cwd = "$ZED_WORKTREE_ROOT";

        reveal = "always";
      }

      {
        label = "Rust: Run";

        command = "cargo";

        args = [
          "run"
        ];

        cwd = "$ZED_WORKTREE_ROOT";

        reveal = "always";
      }

      {
        label = "Rust: Test";

        command = "cargo";

        args = [
          "test"
        ];

        cwd = "$ZED_WORKTREE_ROOT";

        reveal = "always";
      }

      {
        label = "Python: Run";

        command = "python3";

        args = [
          "$ZED_FILE"
        ];

        cwd = "$ZED_WORKTREE_ROOT";

        reveal = "always";
      }

      {
        label = "Git: Status";

        command = "git";

        args = [
          "status"
          "--short"
        ];

        cwd = "$ZED_WORKTREE_ROOT";

        reveal = "always";
      }

      {
        label = "Git: LazyGit";

        command = "lazygit";

        cwd = "$ZED_WORKTREE_ROOT";

        reveal = "always";
      }
    ];

    userDebug = [
      {
        label = "C++: Debug";

        adapter = "CodeLLDB";

        request = "launch";

        program = "$ZED_WORKTREE_ROOT/outputs/$ZED_STEM";

        cwd = "$ZED_WORKTREE_ROOT";

        build = {
          command = "g++";

          args = [
            "-std=c++23"
            "-Wall"
            "-Wextra"
            "-g"

            "$ZED_FILE"

            "-o"
            "$ZED_WORKTREE_ROOT/outputs/$ZED_STEM"
          ];
        };
      }
    ];
  };
}
