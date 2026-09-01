{pkgs ? import <nixpkgs> {}}: {
  venera-bin = pkgs.callPackage ./pkgs/venera-bin {};
}
