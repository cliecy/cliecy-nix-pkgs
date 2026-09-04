{
  lib,
  stdenv,
  fetchurl,
  alsa-lib,
  apr,
  aprutil,
  at-spi2-atk,
  at-spi2-core,
  autoPatchelfHook,
  copyDesktopItems,
  cups,
  dpkg,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libappindicator-gtk3,
  libdbusmenu-gtk3,
  libdrm,
  libgbm,
  libGLU,
  libglvnd,
  libpulseaudio,
  libuuid,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxinerama,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxt,
  libxmu,
  libxtst,
  makeDesktopItem,
  makeWrapper,
  nspr,
  nss,
  pango,
  patchelfUnstable,
  qt5,
  udev,
  wrapGAppsHook3,
}: let
  version = "8.1.0.6021101";
  sources = {
    x86_64-linux = {
      arch = "amd64";
      hash = "sha256-7EkvEv6r7ONHAupH48/BoWSuLo2r3umwXnSjpeTeIdU=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-SEKPcpWGmBWQDDQYZ7u9J5sOsXI2QofdeLshzt+0me8=";
    };
  };
  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "dingtalk-bin: unsupported system ${stdenv.hostPlatform.system}");
  serviceTerms = fetchurl {
    url = "https://terms.alicdn.com/legal-agreement/terms/suit_bu1_dingtalk/suit_bu1_dingtalk202010200940_84493.html";
    hash = "sha256-gnydhV6ef9y3tsYW91ix1OopcWikhjaWsR6Q2oqyZWA=";
  };
  libraries = [
    alsa-lib
    apr
    aprutil
    at-spi2-atk
    at-spi2-core
    cups
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libappindicator-gtk3
    libdbusmenu-gtk3
    libdrm
    libgbm
    libGLU
    libglvnd
    libpulseaudio
    libuuid
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxinerama
    libxkbcommon
    libxrandr
    libxrender
    libxscrnsaver
    libxt
    libxmu
    libxtst
    nspr
    nss
    pango
    qt5.qtbase
    qt5.qtmultimedia
    qt5.qtsvg
    qt5.qtx11extras
    udev
  ];
in
  stdenv.mkDerivation {
    pname = "dingtalk-bin";
    inherit version;

    src = fetchurl {
      url = "https://dtapp-pub.dingtalk.com/dingtalk-desktop/xc_dingtalk_update/linux_deb/Release/com.alibabainc.dingtalk_${version}_${source.arch}.deb";
      inherit (source) hash;
    };

    strictDeps = true;
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    dontWrapGApps = true;
    dontWrapQtApps = true;

    nativeBuildInputs = [
      autoPatchelfHook
      copyDesktopItems
      dpkg
      makeWrapper
      patchelfUnstable
      qt5.wrapQtAppsHook
      wrapGAppsHook3
    ];

    buildInputs = libraries;

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb --extract "$src" .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/libexec/dingtalk"
      mv opt/apps/com.alibabainc.dingtalk/files/version "$out/libexec/dingtalk/version"
      mv opt/apps/com.alibabainc.dingtalk/files/*-Release.*/* "$out/libexec/dingtalk/"

      rm -f "$out"/libexec/dingtalk/{*.a,*.la,*.prl,dingtalk_crash_report,dingtalk_updater,libapr*,libcurl.so.*}
      rm -f "$out"/libexec/dingtalk/{libdouble-conversion.so.*,libEGL*,libfontconfig*,libfreetype*,libfribidi*,libgdk*}
      rm -f "$out"/libexec/dingtalk/{libGLES*,libgtk-x11-2.0.so.*,libharfbuzz*,libicu*,libidn2*,libjpeg*,libm.so.*,libnghttp2*}
      rm -f "$out"/libexec/dingtalk/{libpango-1.0.*,libpangocairo-1.0.*,libpangoft2-1.0.*,libpcre2*,libpng*,libpsl*,libQt5*,libssh2*}
      rm -f "$out"/libexec/dingtalk/{libstdc++.so.6,libstdc++*,libunistring*,libvk*,libvulkan*,libxcb*,libz*,libgbm*}
      rm -rf "$out"/libexec/dingtalk/{engines-1_1,imageformats,platform*,swiftshader,xcbglintegrations}
      rm -rf "$out"/libexec/dingtalk/Resources/{i18n/tool/*.exe,qss/mac}

      patchelf --clear-execstack "$out/libexec/dingtalk/dingtalk_dll.so"
      patchelf --clear-execstack "$out/libexec/dingtalk/libconference_new.so"

      install -Dm644 "$out/libexec/dingtalk/Resources/image/common/about/logo.png" \
        "$out/share/icons/hicolor/512x512/apps/dingtalk.png"
      install -Dm644 "${serviceTerms}" \
        "$out/share/licenses/dingtalk/service-terms-zh.html"

      runHook postInstall
    '';

    # DingTalk opens GTK3 file choosers from its Qt UI. Both wrapper argument
    # sets are required so GIO can find GTK's compiled GSettings schemas.
    preFixup = ''
      makeWrapper "$out/libexec/dingtalk/com.alibabainc.dingtalk" "$out/bin/dingtalk" \
        "''${qtWrapperArgs[@]}" \
        "''${gappsWrapperArgs[@]}" \
        --argv0 com.alibabainc.dingtalk \
        --chdir "$out/libexec/dingtalk" \
        --unset WAYLAND_DISPLAY \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath libraries}"
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck

      program="$out/libexec/dingtalk/com.alibabainc.dingtalk"
      mv "$program" "$program.real"
      cat >"$program" <<'EOF'
      #!${stdenv.shell}
      exec ${lib.getExe' glib "gsettings"} get org.gtk.Settings.FileChooser location-mode
      EOF
      chmod +x "$program"

      test "$(GSETTINGS_BACKEND=memory "$out/bin/dingtalk")" = "'path-bar'"
      mv "$program.real" "$program"

      runHook postInstallCheck
    '';

    # These belong to an unused bundled GTK2 OpenGL extension. The application
    # itself uses GTK3; keeping the extension is required by its plugin layout.
    autoPatchelfIgnoreMissingDeps = [
      "libgdkglext-x11-1.0.so.0"
      "libpangox-1.0.so.0"
      "libgtk-x11-2.0.so.0"
      "libgdk-x11-2.0.so.0"
    ];

    desktopItems = [
      (makeDesktopItem {
        name = "dingtalk";
        desktopName = "DingTalk";
        genericName = "Enterprise Communication Tool";
        comment = "Alibaba DingTalk desktop client";
        categories = [
          "Chat"
          "Network"
        ];
        exec = "dingtalk %u";
        icon = "dingtalk";
        keywords = ["dingtalk"];
        mimeTypes = ["x-scheme-handler/dingtalk"];
        extraConfig = {
          "Name[zh_CN]" = "钉钉";
          "Name[zh_TW]" = "釘釘";
        };
      })
    ];

    meta = {
      description = "Enterprise communication platform developed by Alibaba";
      homepage = "https://www.dingtalk.com/";
      license = lib.licenses.unfree;
      mainProgram = "dingtalk";
      platforms = builtins.attrNames sources;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
