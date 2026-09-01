{
  lib,
  stdenvNoCC,
  fetchurl,
  addDriverRunpath,
  alsa-lib,
  at-spi2-core,
  atk,
  autoAddDriverRunpath,
  autoPatchelfHook,
  cairo,
  cups,
  dbus,
  dpkg,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libglvnd,
  libnotify,
  libpulseaudio,
  libusb1,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  makeWrapper,
  nspr,
  nss,
  pango,
  stdenv,
  systemd,
  vulkan-loader,
  wrapGAppsHook3,
  xdg-utils,
}: let
  runtimeLibraries = [
    alsa-lib
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libglvnd
    libnotify
    libpulseaudio
    libusb1
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    systemd
    vulkan-loader
  ];
in
  stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "chatgpt-bin";
    version = "26.831.20005";

    src = fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${finalAttrs.version}_amd64.deb";
      hash = "sha256-HO8+hAX2lbfwP9GwckYNEYW31T4ktyfjviVhPminUao=";
    };

    strictDeps = true;
    dontConfigure = true;
    dontBuild = true;

    nativeBuildInputs = [
      addDriverRunpath
      autoPatchelfHook
      dpkg
      makeWrapper
      wrapGAppsHook3
    ];

    buildInputs = runtimeLibraries;

    runtimeDependencies = map lib.getLib [
      libglvnd
      libnotify
      libpulseaudio
      libusb1
      vulkan-loader
    ];

    # These are optional Qt integration shims and unused musl prebuilds.
    autoPatchelfIgnoreMissingDeps = [
      "libQt5Core.so.5"
      "libQt5Gui.so.5"
      "libQt5Widgets.so.5"
      "libQt6Core.so.6"
      "libQt6Gui.so.6"
      "libQt6Widgets.so.6"
      "libc.musl-x86_64.so.1"
    ];

    unpackPhase = ''
      runHook preUnpack
      dpkg -x "$src" .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/lib" "$out/share/applications" \
        "$out/share/icons/hicolor/1024x1024/apps" "$out/share/licenses/chatgpt-bin"
      cp -r usr/lib/chatgpt "$out/lib/chatgpt"
      install -Dm644 usr/share/applications/chatgpt.desktop \
        "$out/share/applications/chatgpt.desktop"
      install -Dm644 usr/share/pixmaps/chatgpt.png \
        "$out/share/icons/hicolor/1024x1024/apps/chatgpt.png"
      install -Dm644 usr/share/doc/chatgpt/copyright \
        "$out/share/licenses/chatgpt-bin/copyright"
      ln -s "$out/lib/chatgpt/LICENSES.chromium.html" \
        "$out/share/licenses/chatgpt-bin/LICENSES.chromium.html"
      makeWrapper "$out/lib/chatgpt/ChatGPT" "$out/bin/chatgpt" \
        --suffix PATH : ${lib.makeBinPath [xdg-utils]}

      runHook postInstall
    '';

    preFixup = ''
      gappsWrapperArgs+=(
        --prefix XDG_DATA_DIRS : "${addDriverRunpath.driverLink}/share"
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
      )
    '';

    # Do not apply autoAddDriverRunpath recursively: patchelf corrupts the
    # statically linked Codex executable when it adds a RUNPATH.
    postFixup = ''
      for file in \
        "$out/lib/chatgpt/ChatGPT" \
        "$out/lib/chatgpt/libEGL.so" \
        "$out/lib/chatgpt/libGLESv2.so" \
        "$out/lib/chatgpt/libvk_swiftshader.so" \
        "$out/lib/chatgpt/libvulkan.so.1"; do
        addDriverRunpath "$file"
      done
    '';

    meta = {
      description = "Official desktop application for ChatGPT";
      homepage = "https://chatgpt.com/download/";
      license = lib.licenses.unfree;
      mainProgram = "chatgpt";
      platforms = ["x86_64-linux"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  })
