{
  fetchurl,
  jq,
  qq,
}: let
  downloadUrl = "https://qqdl.gtimg.cn/qqfile/QQNTV2/9.9.33/release/3f89efc5/QQ_3.2.32_260812_amd64_01.deb";
in
  qq.overrideAttrs (
    _finalAttrs: previousAttrs: {
      version = "3.2.32-2026-08-12";

      src = fetchurl {
        name = "qq-3.2.32-260812-amd64.deb";
        url = "https://im.qq.com/http2rpc/gotrpc/noauth/trpc.qqntv2.urlsign.UrlSign/GetSign";
        hash = "sha256-0IXdiTlyJQYeufGUMI9ogSmBjtRFd36XpKChbhPXsOg=";
        downloadToTemp = true;
        nativeBuildInputs = [jq];
        curlOptsList = [
          "--request"
          "POST"
          "--header"
          "Content-Type: application/json"
          "--header"
          ''x-oidb: {"uint32_command":"0x9b8e","uint32_service_type":1}''
          "--data"
          (builtins.toJSON {url = downloadUrl;})
        ];
        postFetch = ''
          signedUrl="$(
            jq --exit-status --raw-output \
              '.data.url | select(type == "string" and length > 0)' \
              "$downloadedFile"
          )"
          curl \
            --fail \
            --insecure \
            --location \
            --retry 3 \
            --retry-all-errors \
            --output "$out" \
            "$signedUrl"
        '';
      };

      passthru = removeAttrs (previousAttrs.passthru or {}) ["updateScript"];

      meta =
        previousAttrs.meta
        // {
          platforms = ["x86_64-linux"];
        };
    }
  )
