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
          version = "3.29.9";
          url = "https://downloads.cursor.com/production/306d153d51d714882ab7b1bc49649cab624e8a31/linux/x64/Cursor-3.29.9-x86_64.AppImage";
          sha256 = "14x69ifrzwg3llpch5c21g0nx710g0z7xz8bkbh5bpzl2yv5afy4";
        };
      };

      # Overlay for easy integration into other flakes
      overlays.default = final: prev: {
        cursor = self.packages.${system}.cursor;
      };
    };
}
