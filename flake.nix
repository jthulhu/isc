{
  description = "Nix flake installer";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    utils.url = github:numtide/flake-utils;
  };
  
  outputs = { nixpkgs, utils, ... }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        inst = pkgs.writeShellScriptBin "inst" (builtins.readFile ./inst.sh);
      in {
        packages.inst = inst;
        defaultPackage = inst;
        apps.inst = inst;
        defaultApp = inst;
      });
}
