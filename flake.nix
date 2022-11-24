{
  description = "Nix flake installer";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    utils.url = github:numtide/flake-utils;
  };
  
  outputs = { nixpkgs, utils, ... }:
    utils.lib.eachDefaultSystem (system:
      let
        inherit (pkgs) writeShellApplication lib stdenv;
        pkgs = import nixpkgs { inherit system; };
        name = "inst";
        dependencies = with pkgs; [ nix findutils gnused git ];
        inst = writeShellApplication {
          inherit name;
          runtimeInputs = dependencies;
          text = builtins.readFile ./inst.sh;
        };
      in rec {
        packages.inst = inst;
        defaultPackage = packages.inst;
        apps.inst = utils.lib.mkApp {
          drv = inst;
        };
        defaultApp = apps.inst;
        devShell = pkgs.mkShell {
          packages = with pkgs; [
            shellcheck
          ];
        };
      });
}
