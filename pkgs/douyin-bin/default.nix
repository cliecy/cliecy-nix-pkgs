{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  electron_42,
  makeWrapper,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "douyin-bin";
  version = "8.3.0";

  src = fetchurl {
    url = "https://github.com/kota-rina3/hokeshi/releases/download/douyin${finalAttrs.version}/com.douyin.otohime_${finalAttrs.version}_amd64.deb";
    hash = "sha256-chAraILGu4G3cyYYV26kLxPKu0E1QSZnHjGfN5qkpAY=";
  };

  patches = [./harden-runtime.patch];

  strictDeps = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    dpkg
    makeWrapper
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg -x "$src" .
    runHook postUnpack
  '';

  prePatch = ''
    sed -i 's/\r$//' \
      opt/apps/com.douyin.otohime/files/resources/app/dy.js \
      opt/apps/com.douyin.otohime/files/resources/app/dy-tray.js
  '';

  postPatch = ''
    rm opt/apps/com.douyin.otohime/files/resources/app/dy-js.js
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib" "$out/share/applications" "$out/share/icons"
    cp -r opt/apps/com.douyin.otohime/files/resources "$out/lib/douyin"
    install -Dm644 ${./preload.js} "$out/lib/douyin/app/preload.js"
    cp -r opt/apps/com.douyin.otohime/entries/icons/hicolor "$out/share/icons/"
    install -Dm644 opt/apps/com.douyin.otohime/entries/applications/douyin.desktop \
      "$out/share/applications/douyin.desktop"

    substituteInPlace "$out/share/applications/douyin.desktop" \
      --replace-fail "Exec=/opt/apps/com.douyin.otohime/files/douyin" "Exec=douyin" \
      --replace-fail "Icon=/opt/apps/com.douyin.otohime/files/resources/app/douyin.png" "Icon=douyin"

    makeWrapper ${lib.getExe electron_42} "$out/bin/douyin" \
      --argv0 douyin \
      --add-flags "$out/lib/douyin/app" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --set-default ELECTRON_FORCE_IS_PACKAGED 1 \
      --set-default ELECTRON_IS_DEV 0 \
      --set DOUYIN_EXECUTABLE "$out/bin/douyin"

    runHook postInstall
  '';

  meta = {
    description = "Unofficial Electron client for Douyin";
    homepage = "https://github.com/kota-rina3/hokeshi";
    changelog = "https://github.com/kota-rina3/hokeshi/releases/tag/douyin${finalAttrs.version}";
    license = lib.licenses.unfree;
    mainProgram = "douyin";
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
