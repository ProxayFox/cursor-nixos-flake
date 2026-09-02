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
          version = "3.18.25";
          url = "https://downloads.cursor.com/production/280eca2911f1774689696e5f1efa5a4f97a87af3/linux/x64/Cursor-3.18.25-x86_64.AppImage";
          sha256 = "0zggxxl9qjpgzh55klv2k2s63jpiqckdrwn8npy8na5yid91fkc7";
        };
      };

      # Overlay for easy integration into other flakes
      overlays.default = final: prev: {
        cursor = self.packages.${system}.cursor;
      };
    };
}
