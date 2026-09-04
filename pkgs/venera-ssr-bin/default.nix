{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  at-spi2-core,
  autoPatchelfHook,
  cairo,
  copyDesktopItems,
  fontconfig,
  gdk-pixbuf,
  glib,
  gtk3,
  harfbuzz,
  libepoxy,
  libsoup_3,
  makeDesktopItem,
  pango,
  unzip,
  webkitgtk_4_1,
  wrapGAppsHook3,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "venera-ssr-bin";
  version = "2.1.5";

  src = fetchurl {
    url = "https://github.com/Kiastr/Venera-SSR/releases/download/v${finalAttrs.version}/Venera-SSR-v${finalAttrs.version}-linux.zip";
    hash = "sha256-Vj/+Tc98thgGw2QTS1KPvzi8q0YPnUH/zXweogpUgY8=";
  };

  strictDeps = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    unzip
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
    unzip "$src"
    runHook postUnpack
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "venera-ssr";
      exec = "venera-ssr";
      icon = "venera-ssr";
      genericName = "Comic Reader";
      desktopName = "Venera SSR";
      comment = "Comic reader with real-time Anime4K upscaling";
      categories = ["Graphics" "Viewer"];
      keywords = [
        "comic"
        "manga"
        "Anime4K"
        "upscaling"
      ];
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib/venera-ssr"
    cp -r bundle/. "$out/lib/venera-ssr/"
    chmod +x "$out/lib/venera-ssr/venera"
    ln -s ../lib/venera-ssr/venera "$out/bin/venera-ssr"
    install -Dm644 bundle/data/flutter_assets/assets/app_icon.png \
      "$out/share/pixmaps/venera-ssr.png"

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "$out/lib/venera-ssr/lib"
    )
  '';

  meta = {
    description = "Venera fork with local real-time Anime4K upscaling";
    homepage = "https://github.com/Kiastr/Venera-SSR";
    changelog = "https://github.com/Kiastr/Venera-SSR/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Only;
    mainProgram = "venera-ssr";
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
