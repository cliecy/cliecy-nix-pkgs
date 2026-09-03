{pkgs ? import <nixpkgs> {}}: {
  douyin-bin = pkgs.callPackage ./pkgs/douyin-bin {};
  qq = pkgs.callPackage ./pkgs/qq {};
  venera-bin = pkgs.callPackage ./pkgs/venera-bin {};
}
