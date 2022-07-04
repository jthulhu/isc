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
        name = "inst";
        inst = pkgs.resholve.writeScriptBin name {
          interpreter = "${pkgs.bash}/bin/bash";
          inputs = with pkgs; [ nix findutils gnused ];
          execer = [ "cannot:${pkgs.nix}/bin/nix" ]; 
        } (builtins.readFile ./inst.sh);
      in rec {
        packages.inst = inst;
        defaultPackage = packages.inst;
        apps.inst = utils.lib.mkApp {
          drv = inst;
        };
        defaultApp = apps.inst;
      });
}
