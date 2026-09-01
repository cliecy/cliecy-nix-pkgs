{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  at-spi2-core,
  autoPatchelfHook,
  cairo,
  copyDesktopItems,
  dpkg,
  fontconfig,
  gdk-pixbuf,
  glib,
  gtk3,
  harfbuzz,
  libepoxy,
  libsoup_3,
  makeDesktopItem,
  pango,
  webkitgtk_4_1,
  wrapGAppsHook3,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "venera-bin";
  version = "1.6.3";

  src = fetchurl {
    url = "https://github.com/venera-app/venera/releases/download/v${finalAttrs.version}/venera_${finalAttrs.version}_amd64.deb";
    hash = "sha256-w08evtYt/K/njcg0EzR1gd/bkPFE0hJf7P1cLNRAgFw=";
  };

  strictDeps = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    dpkg
    wrapGAppsHook3
  ];

  buildInputs = [
    at-spi2-core
    cairo
    fontconfig
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    libepoxy
    libsoup_3
    pango
    stdenv.cc.cc.lib
    webkitgtk_4_1
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg -x "$src" .
    runHook postUnpack
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "venera";
      exec = "venera";
      icon = "venera";
      genericName = "Venera";
      desktopName = "Venera";
      categories = ["Utility"];
      keywords = [
        "Flutter"
        "comic"
        "images"
      ];
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib"
    cp -r usr/local/lib/venera "$out/lib/venera"
    ln -s ../lib/venera/venera "$out/bin/venera"
    install -Dm644 usr/share/icons/venera.png \
      "$out/share/icons/hicolor/1024x1024/apps/venera.png"

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "$out/lib/venera/lib"
    )
  '';

  meta = {
    description = "Cross-platform comic reader for local and network comics";
    homepage = "https://github.com/venera-app/venera";
    changelog = "https://github.com/venera-app/venera/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Plus;
    mainProgram = "venera";
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
