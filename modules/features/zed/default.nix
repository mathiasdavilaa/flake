{ pkgs, ... }:

{

  # ============================================================
  # ZED
  # ============================================================

  programs.zed-editor = {
    enable = true;
    defaultEditor = true;

    # ==========================================================
    # EXTENSIONS
    # ==========================================================

    extensions = [
      # Nix
      "nix"

      # Interface / icons
      "material-icon-theme"

      # Build / configuration
      "make"
      "toml"
      "dockerfile"

      # Git
      "git-firefly"

      # Discord Rich Presence
      "discord-presence"
    ];

    # ==========================================================
    # TOOLS
    # ==========================================================

    extraPackages = with pkgs; [
      # --------------------------------------------------------
      # C / C++
      # --------------------------------------------------------

      gcc
      clang
      clang-tools
      gdb

      # --------------------------------------------------------
      # Build systems
      # --------------------------------------------------------

      cmake
      gnumake
      ninja
      pkg-config

      # --------------------------------------------------------
      # Nix
      # --------------------------------------------------------

      nixd
      nil
      nixfmt-rfc-style

      # --------------------------------------------------------
      # Rust
      # --------------------------------------------------------

      rust-analyzer
      rustfmt

      # --------------------------------------------------------
      # Python
      # --------------------------------------------------------

      python3
      pyright
      ruff

      # --------------------------------------------------------
      # Git
      # --------------------------------------------------------

      git
      git-lfs
      lazygit

      # --------------------------------------------------------
      # Utilities
      # --------------------------------------------------------

      jq
      ripgrep
      fd
    ];

    # ==========================================================
    # SETTINGS
    # ==========================================================

    userSettings = {

      # --------------------------------------------------------
      # THEME
      # --------------------------------------------------------

      theme = {
        mode = "dark";
      };

      icon_theme = "Material Icon Theme";

      # --------------------------------------------------------
      # FONTS
      # --------------------------------------------------------

      ui_font_size = 16;
      buffer_font_size = 15;

      ui_font_family = "JetBrainsMono Nerd Font";
      buffer_font_family = "JetBrainsMono Nerd Font";

      # --------------------------------------------------------
      # EDITOR
      # --------------------------------------------------------

      tab_size = 2;

      soft_wrap = "none";

      relative_line_numbers = false;

      show_whitespaces = "selection";

      cursor_blink = true;

      use_smartcase_search = true;

      seed_search_query_from_cursor = "always";

      show_completions_on_input = true;

      use_autoclose = true;

      # Do not format while typing
      use_on_type_format = false;

      # Do not format on save
      format_on_save = "off";

      # Keep manual formatting available
      formatter = "language_server";

      # --------------------------------------------------------
      # TERMINAL
      # --------------------------------------------------------

      terminal = {
        font_family = "JetBrainsMono Nerd Font";
        font_size = 14;

        shell = {
          program = "fish";
        };

        blinking = "terminal_controlled";

        working_directory = "current_project_directory";
      };

      # --------------------------------------------------------
      # GIT
      # --------------------------------------------------------

      git = {
        inline_blame = {
          enabled = false;
        };

        gutter = {
          enabled = true;
        };
      };

      # --------------------------------------------------------
      # FILES
      # --------------------------------------------------------

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

      # --------------------------------------------------------
      # PROJECT PANEL
      # --------------------------------------------------------

      project_panel = {
        dock = "left";
        default_width = 300;
        git_status = true;
      };

      # --------------------------------------------------------
      # MINIMAP
      # --------------------------------------------------------

      minimap = {
        show = "never";
      };

      # --------------------------------------------------------
      # DIAGNOSTICS
      # --------------------------------------------------------

      diagnostics = {
        inline = {
          enabled = true;
        };

        include_warnings = true;
      };

      # ========================================================
      # LANGUAGE SERVERS
      # ========================================================

      languages = {

        # ------------------------------------------------------
        # NIX
        # ------------------------------------------------------

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

        # ------------------------------------------------------
        # C
        # ------------------------------------------------------

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

        # ------------------------------------------------------
        # C++
        # ------------------------------------------------------

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

        # ------------------------------------------------------
        # RUST
        # ------------------------------------------------------

        Rust = {
          language_servers = [
            "rust-analyzer"
          ];

          tab_size = 2;
        };

        # ------------------------------------------------------
        # PYTHON
        # ------------------------------------------------------

        Python = {
          language_servers = [
            "pyright"
          ];

          tab_size = 2;
        };
      };

      # --------------------------------------------------------
      # TELEMETRY
      # --------------------------------------------------------

      # --------------------------------------------------------
      # DISCORD RICH PRESENCE
      # --------------------------------------------------------
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

    # ==========================================================
    # KEYMAP
    # ==========================================================

    userKeymaps = [

      # --------------------------------------------------------
      # BOTTOM DOCK / TERMINAL
      # --------------------------------------------------------

      {
        context = "Workspace";

        bindings = {
          "ctrl-`" = "workspace::ToggleBottomDock";
        };
      }

      # --------------------------------------------------------
      # TASKS
      # --------------------------------------------------------

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

      # --------------------------------------------------------
      # C++ BUILD & RUN
      # --------------------------------------------------------

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

      # --------------------------------------------------------
      # DEBUGGER
      # --------------------------------------------------------

      {
        context = "Workspace";

        bindings = {
          "f9" = "debugger::Start";
        };
      }

      # --------------------------------------------------------
      # SAVE
      # --------------------------------------------------------

      {
        context = "Editor";

        bindings = {
          "ctrl-s" = "workspace::Save";
        };
      }

      # --------------------------------------------------------
      # MANUAL FORMATTING
      # --------------------------------------------------------

      {
        context = "Editor";

        bindings = {
          "ctrl-shift-i" = "editor::Format";
        };
      }

      # --------------------------------------------------------
      # FILE FINDER
      # --------------------------------------------------------

      {
        context = "Workspace";

        bindings = {
          "ctrl-p" = "file_finder::Toggle";
        };
      }

      # --------------------------------------------------------
      # COMMAND PALETTE
      # --------------------------------------------------------

      {
        context = "Workspace";

        bindings = {
          "ctrl-shift-p" = "command_palette::Toggle";
        };
      }
    ];

    # ==========================================================
    # TASKS
    # ==========================================================

    userTasks = [

      # ========================================================
      # C++
      # ========================================================

      {
        label = "C++: Build & Run";

        command = ''
          set -e

          # Create the outputs directory at the project root
          mkdir -p "$ZED_WORKTREE_ROOT/outputs"

          # Compile the program
          g++ \
            -std=c++23 \
            -Wall \
            -Wextra \
            -Wpedantic \
            -O2 \
            "$ZED_FILE" \
            -o "$ZED_WORKTREE_ROOT/outputs/$ZED_STEM"

          echo "==============================================="

          # Run the program with std::cin input enabled
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

      # ========================================================
      # C++ BUILD DEBUG
      # ========================================================

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

      # ========================================================
      # C++ RUN
      # ========================================================

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

      # ========================================================
      # CMAKE
      # ========================================================

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

      # ========================================================
      # NIX
      # ========================================================

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

      # --------------------------------------------------------
      # REBUILD LAPTOP
      # --------------------------------------------------------

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

      # --------------------------------------------------------
      # REBUILD DESKTOP
      # --------------------------------------------------------

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

      # ========================================================
      # RUST
      # ========================================================

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

      # ========================================================
      # PYTHON
      # ========================================================

      {
        label = "Python: Run";

        command = "python3";

        args = [
          "$ZED_FILE"
        ];

        cwd = "$ZED_WORKTREE_ROOT";

        reveal = "always";
      }

      # ========================================================
      # GIT
      # ========================================================

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

    # ==========================================================
    # DEBUGGER
    # ==========================================================

    userDebug = [
      {
        label = "C++: Debug";

        adapter = "CodeLLDB";

        request = "launch";

        # Executable inside outputs/
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
