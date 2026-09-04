{pkgs ? import <nixpkgs> {}}: {
  dingtalk-bin = pkgs.callPackage ./pkgs/dingtalk-bin {};
  douyin-bin = pkgs.callPackage ./pkgs/douyin-bin {};
  qq = pkgs.callPackage ./pkgs/qq {};
  venera-bin = pkgs.callPackage ./pkgs/venera-bin {};
}
