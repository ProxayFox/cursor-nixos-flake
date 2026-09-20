{
  description = "Cursor AppImage package flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # code-cursor is unfree
      };

      # Reuse nixpkgs' code-cursor (buildVscode: autoPatchelfHook + wrapGAppsHook3) and
      # only swap in the AppImage this flake tracks, so we stay ahead of nixpkgs on
      # version without reimplementing the packaging.
      #
      # Deliberately NOT appimageTools.wrapType2: that is buildFHSEnv -> bubblewrap, and
      # bwrap sets PR_SET_NO_NEW_PRIVS=1, which every child process inherits. That breaks
      # setuid binaries (sudo) in Cursor's integrated terminal.
      buildCursor = { version, url, sha256 }:
        let
          appimage = pkgs.fetchurl { inherit url sha256; };
        in
        pkgs.code-cursor.overrideAttrs (old: {
          inherit version;

          src = pkgs.appimageTools.extract {
            pname = "cursor";
            inherit version;
            src = appimage;
          };

          sourceRoot = "cursor-${version}-extracted/usr/share/cursor";
        });
    in
    {
      packages.${system} = {
        default = self.packages.${system}.cursor;
        cursor = buildCursor {
          version = "3.21.16";
          url = "https://downloads.cursor.com/production/8ae78e8eee1e63479c7e0504b664bc0a80c6800f/linux/x64/Cursor-3.21.16-x86_64.AppImage";
          sha256 = "1l5vmbml3cmcnkvr1w631ivf2wizyd1dg34cp7zxqay0rnp14axq";
        };
      };

      # Overlay for easy integration into other flakes
      overlays.default = final: prev: {
        cursor = self.packages.${system}.cursor;
      };
    };
}
