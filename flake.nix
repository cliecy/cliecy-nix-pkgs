{
  description = "cliecy's personal Nix package repository";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = package:
        builtins.elem (nixpkgs.lib.getName package) [
          "dingtalk-bin"
          "douyin-bin"
          "qq"
          "wecom"
        ];
    };
    repository = import ./default.nix {inherit pkgs;};
  in {
    legacyPackages.${system} = repository;

    packages.${system} = {
      inherit (repository) dingtalk-bin douyin-bin qq venera-bin wecom;
      default = repository.venera-bin;
    };

    checks.${system} = {
      inherit (repository) dingtalk-bin douyin-bin qq venera-bin wecom;
    };

    overlays.default = final: _prev: {
      cliecyPackages = import ./default.nix {pkgs = final;};
    };

    formatter.${system} = pkgs.alejandra;
  };
}
