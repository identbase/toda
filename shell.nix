let
  pkgs = import <nixpkgs> {};
in
pkgs.mkShell {
  buildInputs = [
    pkgs.d2
    # pkgs.dart - Installed by flutter.
    # pkgs.flutter - Installed outside of nix.
    # pkgs.git - Installed outside of nix.
    pkgs.gnupg
    pkgs.jq
    pkgs.nodejs-18_x # Required for coc.nvim.
  ];
}
