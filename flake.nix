{
  description = "cliecy's personal Nix package repository";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = package:
        builtins.elem (nixpkgs.lib.getName package) [
          "chatgpt-bin"
          "douyin-bin"
        ];
    };
    repository = import ./default.nix {inherit pkgs;};
  in {
    legacyPackages.${system} = repository;

    packages.${system} = {
      inherit (repository) chatgpt-bin douyin-bin venera-bin;
      default = repository.venera-bin;
    };

    checks.${system} = {
      inherit (repository) chatgpt-bin douyin-bin venera-bin;
    };

    overlays.default = final: _prev: {
      cliecyPackages = import ./default.nix {pkgs = final;};
    };

    formatter.${system} = pkgs.alejandra;
  };
}
