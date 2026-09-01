{pkgs ? import <nixpkgs> {}}: {
  douyin-bin = pkgs.callPackage ./pkgs/douyin-bin {};
  venera-bin = pkgs.callPackage ./pkgs/venera-bin {};
}
