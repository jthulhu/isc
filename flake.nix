{
  description = "Template handler";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    utils.url = github:numtide/flake-utils;
  };
  
  outputs = { nixpkgs, utils, ... }:
    utils.lib.eachDefaultSystem (system:
      let
        inherit (pkgs) writeShellApplication lib stdenv;
        pkgs = import nixpkgs { inherit system; };
        name = "isc";
        dependencies = with pkgs; [ nix findutils gnused git ];
        isc = writeShellApplication {
          inherit name;
          runtimeInputs = dependencies;
          text = builtins.readFile ./isc.sh;
        };
      in rec {
        packages.isc = isc;
        defaultPackage = packages.isc;
        apps.isc = utils.lib.mkApp {
          drv = isc;
        };
        defaultApp = apps.isc;
        devShell = pkgs.mkShell {
          packages = with pkgs; [
            shellcheck
          ];
        };
      });
}
