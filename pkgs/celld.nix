{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:

let
  sources = lib.importJSON ./sources.json;
  inherit (sources) version;
  system = stdenvNoCC.hostPlatform.system;
  fetchAsset =
    key:
    let
      asset = sources.assets.${key};
    in
    fetchurl {
      url = "https://github.com/denoland/celld/releases/download/v${version}/${asset.name}";
      inherit (asset) hash;
    };
  platforms = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];
in
stdenvNoCC.mkDerivation {
  pname = "celld";
  inherit version;

  src =
    if lib.elem system platforms then
      fetchAsset system
    else
      throw "celld: unsupported system ${system}";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -d $out/bin
    gunzip -c $src > $out/bin/celld
    chmod 0755 $out/bin/celld
    install -Dm0644 ${fetchAsset "LICENSE"} $out/share/licenses/celld/LICENSE
    install -Dm0644 ${fetchAsset "NOTICE"} $out/share/licenses/celld/NOTICE
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/celld --help > /dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Self-hosted, distributed Durable Objects";
    homepage = "https://github.com/denoland/celld";
    changelog = "https://github.com/denoland/celld/releases/tag/v${version}";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "celld";
    inherit platforms;
  };
}
