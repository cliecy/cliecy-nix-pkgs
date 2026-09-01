{
  description = "cliecy's personal Nix package repository";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = package: nixpkgs.lib.getName package == "douyin-bin";
    };
    repository = import ./default.nix {inherit pkgs;};
  in {
    legacyPackages.${system} = repository;

    packages.${system} = {
      inherit (repository) douyin-bin venera-bin;
      default = repository.venera-bin;
    };

    checks.${system} = {
      inherit (repository) douyin-bin venera-bin;
    };

    overlays.default = final: _prev: {
      cliecyPackages = import ./default.nix {pkgs = final;};
    };

    formatter.${system} = pkgs.alejandra;
  };
}
