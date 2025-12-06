# Cursor AppImage Native Module Fix

## Problem Analysis

The issue with Cursor when using the custom developed flake is related to native modules not being found when the AppImage runs. The error shows:

```text
Error: Cannot find module './build/Debug/keymapping'
Require stack:
- /home/user/.cache/appimage-run/d249132fa6429cbc46050495a19ed410e04db53655428955024ff631c095d11c/usr/share/cursor/resources/app/node_modules/native-keymap/index.js
```

This is a common issue with Electron applications packaged as AppImages on NixOS systems. The native modules are compiled for a specific environment and don't work properly in the NixOS sandbox.

## Solution

We need to modify the Cursor wrapper in `home.nix` to add additional environment variables that help with native module loading. Here are the changes to make:

### Updated Cursor Wrapper Configuration

```nix
{ config, pkgs, lib, ... }:

let
  # Cursor 1.4.2 AppImage wrapper with enhanced compatibility and update handling
  cursorAppImage = pkgs.writeShellScriptBin "cursor" ''
    # Set up environment for better AppImage compatibility
    export APPDIR=""
    export ARGV0=""
    export OWD=""
    
    # Disable Cursor's auto-update mechanism to prevent crashes
    export CURSOR_DISABLE_UPDATE="1"
    export CURSOR_SKIP_UPDATE_CHECK="1"
    
    # Ensure proper library paths
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
      pkgs.glib
      pkgs.gtk3
      pkgs.cairo
      pkgs.pango
      pkgs.atk
      pkgs.gdk-pixbuf
      pkgs.xorg.libX11
      pkgs.xorg.libXcomposite
      pkgs.xorg.libXcursor
      pkgs.xorg.libXext
      pkgs.xorg.libXfixes
      pkgs.xorg.libXi
      pkgs.xorg.libXrandr
      pkgs.xorg.libXrender
      pkgs.xorg.libXtst
      pkgs.nss
      pkgs.nspr
      pkgs.dbus
      pkgs.at-spi2-atk
      pkgs.at-spi2-core
      pkgs.mesa
      pkgs.alsa-lib
      pkgs.fuse
      pkgs.libxkbcommon
      pkgs.libxkbfile
    ]}:$LD_LIBRARY_PATH"
    
    # Set additional environment variables to handle keymapping and native module issues
    export ELECTRON_DISABLE_SECURITY_WARNINGS="1"
    export ELECTRON_NO_ATTACH_CONSOLE="1"
    export ELECTRON_RUN_AS_NODE="0"
    
    # Additional environment variables for native module compatibility
    export NODE_OPTIONS="--no-warnings"
    export NODE_ENV="production"
    export ELECTRON_ENABLE_LOGGING="false"
    export ELECTRON_DISABLE_SECURITY_WARNINGS="true"
    
    # Fix for native keymap module issues
    export XDG_CACHE_HOME="/tmp/cursor-xdg-cache-$$"
    mkdir -p "$XDG_CACHE_HOME"
    
    # Create a temporary directory for Cursor's cache to avoid permission issues
    export CURSOR_CACHE_DIR="/tmp/cursor-cache-$$"
    mkdir -p "$CURSOR_CACHE_DIR"
    
    # Additional fixes for AppImage native modules
    export APPIMAGE_EXTRACT_AND_RUN="1"
    
    # Run the AppImage with appimage-run and additional flags
    exec ${pkgs.appimage-run}/bin/appimage-run \
      --no-sandbox \
      --appimage-extract-and-run \
      ${pkgs.fetchurl {
                  url = "https://downloads.cursor.com/production/07aa3b4519da4feab4761c58da3eeedd253a1671/linux/x64/Cursor-1.4.2-x86_64.AppImage";
                  sha256 = "0gb89li1aklzgc9h8y5rlrnk0n6sb4ikahaml4r9kr6ixadc4b1a";
      }} \
      --disable-updates \
      --no-update-check \
      --disable-gpu-sandbox \
      --no-sandbox \
      --disable-dev-shm-usage \
      "$@"
  '';
in
{
  home.username = "user";
  home.homeDirectory = "/home/user";
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Add Cursor to home packages
  home.packages = with pkgs; [
    cursorAppImage
    # Additional development tools
    nodejs_20
    python3
    rustc
    cargo
    # Terminal improvements
    starship
    zsh
    # Git tools
    git-crypt
    git-lfs
    # Additional utilities
    ripgrep
    fd
    bat
    eza
    fzf
    tmux
  ];

  # Shell configuration
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "eza -la";
      la = "eza -a";
      cat = "bat";
      find = "fd";
      grep = "rg";
    };
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      prompt_order = [ "directory" "git_branch" "git_status" "nodejs" "rust" "python" "cmd_duration" "line_break" "$all" ];
    };
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your.email@example.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # VS Code settings (for Cursor compatibility)
  home.file.".config/Code/User/settings.json".text = builtins.toJSON {
    "editor.fontSize" = 14;
    "editor.fontFamily" = "'JetBrains Mono', 'Fira Code', Consolas, 'Courier New', monospace";
    "editor.fontLigatures" = true;
    "editor.tabSize" = 2;
    "editor.insertSpaces" = true;
    "editor.rulers" = [ 80 120 ];
    "editor.minimap.enabled" = false;
    "workbench.colorTheme" = "Default Dark+";
    "workbench.iconTheme" = "material-icon-theme";
    "terminal.integrated.fontSize" = 14;
    "terminal.integrated.fontFamily" = "'JetBrains Mono', 'Fira Code', Consolas, 'Courier New', monospace";
  };

  # Cursor-specific settings
  home.file.".config/Cursor/User/settings.json".text = builtins.toJSON {
    "editor.fontSize" = 14;
    "editor.fontFamily" = "'JetBrains Mono', 'Fira Code', Consolas, 'Courier New', monospace";
    "editor.fontLigatures" = true;
    "editor.tabSize" = 2;
    "editor.insertSpaces" = true;
    "editor.rulers" = [ 80 120 ];
    "editor.minimap.enabled" = false;
    "workbench.colorTheme" = "Default Dark+";
    "workbench.iconTheme" = "material-icon-theme";
    "terminal.integrated.fontSize" = 14;
    "terminal.integrated.fontFamily" = "'JetBrains Mono', 'Fira Code', Consolas, 'Courier New', monospace";
    "cursor.chat.enabled" = true;
    "cursor.chat.autoComplete" = true;
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "cursor";
    VISUAL = "cursor";
    BROWSER = "firefox";
  };

  # XDG directories
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      publicShare = "$HOME/Public";
      templates = "$HOME/Templates";
      videos = "$HOME/Videos";
    };
  };
}
```

## Key Changes Made

1. **Added libxkbcommon and libxkbfile** to the library path to help with keyboard mapping
2. **Added ELECTRON_RUN_AS_NODE="0"** to ensure Electron runs properly
3. **Added NODE_OPTIONS="--no-warnings"** and **NODE_ENV="production"** for better Node.js compatibility
4. **Added XDG_CACHE_HOME** environment variable with a temporary directory to avoid permission issues
5. **Added APPIMAGE_EXTRACT_AND_RUN="1"** to help with AppImage native modules
6. **Added --appimage-extract-and-run** flag to the appimage-run command
7. **Added --disable-gpu-sandbox** and **--disable-dev-shm-usage** flags to help with sandbox issues

## How to Apply These Changes

1. Open your `home.nix` file
2. Replace the existing `cursorAppImage` section with the updated version above
3. Rebuild your system with:

   ```bash
   sudo nixos-rebuild switch --flake .#cursor-system
   ```

4. Test Cursor:

   ```bash
   cursor --version
   ```

## Additional Troubleshooting

If you still encounter issues:

1. Clear the AppImage cache:

   ```bash
   rm -rf ~/.cache/appimage-run/*
   ```

2. Try running Cursor with additional debugging:

   ```bash
   cursor --enable-logging --v=1
   ```

3. Check if the issue persists in a fresh terminal session

These changes should resolve the native module loading issues you're experiencing with Cursor in your NixOS flake.
