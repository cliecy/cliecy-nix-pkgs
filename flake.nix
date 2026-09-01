{
  description = "cliecy's personal Nix package repository";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    repository = import ./default.nix {inherit pkgs;};
  in {
    legacyPackages.${system} = repository;

    packages.${system} = {
      inherit (repository) venera-bin;
      default = repository.venera-bin;
    };

    checks.${system}.venera-bin = repository.venera-bin;

    overlays.default = final: _prev: {
      cliecyPackages = import ./default.nix {pkgs = final;};
    };

    formatter.${system} = pkgs.alejandra;
  };
}
