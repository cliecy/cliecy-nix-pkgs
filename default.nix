{pkgs ? import <nixpkgs> {}}: {
  dingtalk-bin = pkgs.callPackage ./pkgs/dingtalk-bin {};
  douyin-bin = pkgs.callPackage ./pkgs/douyin-bin {};
  qq = pkgs.callPackage ./pkgs/qq {};
  wecom = pkgs.callPackage ./pkgs/wecom {};
  venera-bin = pkgs.callPackage ./pkgs/venera-bin {};
  venera-ssr-bin = pkgs.callPackage ./pkgs/venera-ssr-bin {};
}
