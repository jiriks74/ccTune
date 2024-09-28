let
  pkgs = import <nixpkgs> {};
in
pkgs.mkShell {
  packages = with pkgs; [
    # Choose the build tools that you need
    ccemux
    lua54Packages.luafilesystem
  ];
}

