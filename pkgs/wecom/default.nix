{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  jq,
  kdePackages,
  buildFHSEnv,
  writeShellScript,
}: let
  version = "5.0.7.6005deepin11";
  appId = "com.qq.weixin.work.deepin";

  wecomFiles = stdenvNoCC.mkDerivation {
    pname = "wecom-deepin-files";
    inherit version;

    src = fetchurl {
      name = "${appId}-${version}-amd64.deb";
      url = "https://com-store-packages.uniontech.com/appstorev23/pool/appstore/c/${appId}/${appId}_${version}_amd64.deb";
      hash = "sha256-In2UafR3SSyyYQjaLZUMIlufXIGTOWi/cYkeez5vCNY=";
      curlOptsList = [
        "--user-agent"
        "Debian APT-HTTP/1.3"
        "--referer"
        "https://com-store-packages.uniontech.com/"
      ];
    };

    strictDeps = true;
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    nativeBuildInputs = [dpkg];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb --extract "$src" .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -a opt "$out/"

      runHook postInstall
    '';
  };

  deepinWine = stdenvNoCC.mkDerivation {
    pname = "deepin-wine10-stable";
    version = "10.14deepin11";

    src = fetchurl {
      name = "deepin-wine10-stable-10.14deepin11-amd64.deb";
      url = "https://pro-store-packages.uniontech.com/appstore/pool/appstore/d/deepin-wine10-stable/deepin-wine10-stable_10.14deepin11_amd64.deb";
      hash = "sha256-o0Epgs+xbY4g0pUId5rFrYo7OJpBc37rt/ZXobW5yw8=";
      curlOptsList = [
        "--user-agent"
        "Debian APT-HTTP/1.3"
      ];
    };

    strictDeps = true;
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    nativeBuildInputs = [dpkg];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb --extract "$src" .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -a opt usr "$out/"

      runHook postInstall
    '';
  };

  sparkWineHelper = stdenvNoCC.mkDerivation {
    pname = "spark-dwine-helper";
    version = "5.8-5.3.14";

    src = fetchurl {
      name = "spark-dwine-helper-5.8-5.3.14-all.deb";
      url = "https://gitee.com/spark-store-project/spark-wine/releases/download/5.7.1-5.3.14/spark-dwine-helper_5.8-5.3.14_all.deb";
      hash = "sha256-RqDctTnq+ihj07cHfp/prh1GVXAQbHb2u32FylFysyc=";
    };

    strictDeps = true;
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    nativeBuildInputs = [dpkg];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb --extract "$src" .
      runHook postUnpack
    '';

    installPhase = ''
            runHook preInstall

            mkdir -p "$out/opt/deepinwine/tools"
            cp -a opt/spark-dwine-helper "$out/opt/"
            substituteInPlace "$out/opt/spark-dwine-helper/spark_run_v4.sh" \
              --replace-fail '"^Name\[$LANGUAGE\]\="' '"^Name\[$LANGUAGE\]="'
            substituteInPlace "$out/opt/spark-dwine-helper/spark_run_v4.sh" \
              --replace-fail '$SHELL_DIR/spark_kill.sh "$BOTTLENAME" block' ':'
            substituteInPlace \
              "$out/opt/spark-dwine-helper/spark-dwine-helper/scale-set-helper/set-wine-scale.sh" \
              --replace-fail \
                'if [ "$appointed_scale_factor" = "" ];then' \
                'if [ -n "$DEEPIN_WINE_SCALE" ]; then
          echo "$DEEPIN_WINE_SCALE" > "$CONTAINER_PATH/scale.txt"
      fi

      if [ "$appointed_scale_factor" = "" ];then'
            ln -s /opt/spark-dwine-helper/spark_run_v4.sh \
              "$out/opt/deepinwine/tools/spark_run_v4.sh"
            ln -s /opt/spark-dwine-helper/spark_kill.sh \
              "$out/opt/deepinwine/tools/spark_kill.sh"
            ln -s /opt/spark-dwine-helper/spark_gl-wine \
              "$out/opt/deepinwine/tools/gl-wine"
            ln -s /opt/spark-dwine-helper/spark_run_v4.sh \
              "$out/opt/deepinwine/tools/run_v4.sh"
            ln -s /opt/spark-dwine-helper/spark_kill.sh \
              "$out/opt/deepinwine/tools/kill.sh"

            runHook postInstall
    '';
  };

  launcher = writeShellScript "wecom-launcher" ''
    requestedScale="''${DEEPIN_WINE_SCALE:-}"

    if [[ -z "$requestedScale" ]]; then
      requestedScale="$(
        ${lib.getExe' kdePackages.libkscreen "kscreen-doctor"} -o 2>/dev/null |
          sed -n 's/^[[:space:]]*Scale:[[:space:]]*\([0-9.]*\).*$/\1/p' |
          head -n 1
      )"
    fi

    if [[ -z "$requestedScale" && -r "$HOME/.config/kwinoutputconfig.json" ]]; then
      requestedScale="$(
        ${lib.getExe jq} --raw-output '
          (map(select(.name == "setups"))[0].data[0].outputs
            | map(select(.enabled == true))
            | sort_by(.priority)
            | .[0].outputIndex) as $index
          | map(select(.name == "outputs"))[0].data[$index].scale // empty
        ' "$HOME/.config/kwinoutputconfig.json" 2>/dev/null || true
      )"
    fi

    if [[ -z "$requestedScale" && -n "''${QT_SCALE_FACTOR:-}" ]]; then
      requestedScale="$QT_SCALE_FACTOR"
    fi

    wineScale="$(
      LC_ALL=C awk -v requested="$requestedScale" '
        BEGIN {
          count = split("1.0 1.25 1.5 1.75 2.0 2.5 3.0 3.5 4.0", scales, " ")
          if (requested !~ /^[0-9]+([.][0-9]+)?$/ || requested <= 0) {
            print "1.0"
            exit
          }

          best = 1
          bestDistance = requested - scales[1]
          if (bestDistance < 0) bestDistance = -bestDistance

          for (candidate = 2; candidate <= count; candidate++) {
            distance = requested - scales[candidate]
            if (distance < 0) distance = -distance
            if (distance < bestDistance) {
              best = candidate
              bestDistance = distance
            }
          }

          print scales[best]
        }
      '
    )"

    export DEEPIN_WINE_SCALE="$wineScale"
    export WINEDEBUG="''${WINEDEBUG:--all}"
    printf 'WeCom: using display scale %s for Wine\n' "$wineScale"
    exec /opt/apps/${appId}/files/run.sh "$@"
  '';
in
  buildFHSEnv {
    pname = "wecom";
    inherit version;

    runScript = launcher;
    executableName = "wecom";

    targetPkgs = pkgs: (with pkgs; [
      wecomFiles
      deepinWine
      sparkWineHelper

      alsa-lib
      alsa-plugins
      cups
      dbus
      fontconfig
      freetype
      glib
      gnutls
      gst_all_1.gst-plugins-base
      gst_all_1.gstreamer
      krb5
      libGL
      libGLU
      libcap
      libgphoto2
      libjpeg
      libpng
      libpulseaudio
      libusb1
      libx11
      libxcomposite
      libxcursor
      libxext
      libxfixes
      libxi
      libxinerama
      libxrandr
      libxrender
      libxxf86vm
      mesa
      ncurses
      ocl-icd
      p7zip
      pcsclite
      procps
      sane-backends
      SDL2
      systemd
      unixodbc
      v4l-utils
      vulkan-loader
      which
      wmctrl
      wqy_microhei
      xdg-utils
      xdpyinfo
      zenity
    ]);

    extraBuildCommands = ''
      mkdir -p "$out/usr/share/applications"
      ln -sf \
        "/opt/apps/${appId}/entries/applications/${appId}.desktop" \
        "$out/usr/share/applications/${appId}.desktop"
      ln -sf /opt/deepin-wine10-stable/bin/wine \
        "$out/usr/bin/deepin-wine10-stable"
    '';

    extraInstallCommands = ''
      mkdir -p "$out/share/applications" "$out/share/icons"
      cp -a \
        "${wecomFiles}/opt/apps/${appId}/entries/applications/${appId}.desktop" \
        "$out/share/applications/"
      cp -a \
        "${wecomFiles}/opt/apps/${appId}/entries/icons/." \
        "$out/share/icons/"

      substituteInPlace "$out/share/applications/${appId}.desktop" \
        --replace-fail 'Exec="/opt/apps/${appId}/files/run.sh" -f %f' 'Exec=wecom -f %f' \
        --replace-fail 'Categories=chat;' 'Categories=Chat;Network;'
      sed -i '/^X-Deepin-PreUninstall=/d' \
        "$out/share/applications/${appId}.desktop"
    '';

    meta = {
      description = "Tencent WeCom client packaged with Deepin Wine";
      homepage = "https://work.weixin.qq.com/";
      license = lib.licenses.unfree;
      mainProgram = "wecom";
      platforms = ["x86_64-linux"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
