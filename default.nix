{pkgs ? import <nixpkgs> {}}: {
  chatgpt-bin = pkgs.callPackage ./pkgs/chatgpt-bin {};
  douyin-bin = pkgs.callPackage ./pkgs/douyin-bin {};
  venera-bin = pkgs.callPackage ./pkgs/venera-bin {};
}
