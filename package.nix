{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  wrapGAppsHook,
  copyDesktopItems,
  makeDesktopItem,
  fd,
  # deps
  alsa-lib,
  dbus-glib,
  ffmpeg,
  gtk3,
  libglvnd,
  libnotify,
  libva,
  mesa,
  pciutils,
  pipewire,
  pulseaudio,
  xorg,
  # package-related
  sourceInfo,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "zen-browser-${sourceInfo.channel}-${sourceInfo.variant}";
  inherit (sourceInfo) version;

  src = fetchurl sourceInfo.src;

  nativeBuildInputs = [
    fd
    autoPatchelfHook
    wrapGAppsHook
    copyDesktopItems
  ];

  buildInputs = [
    gtk3
    alsa-lib
    dbus-glib
    xorg.libXtst
  ];

  installPhase = ''
    runHook preInstall

    # mimic Firefox's dir structure
    mkdir -p $out/bin
    mkdir -p $out/lib/zen && cp -r * $out/lib/zen

    fd --type x --exclude '*.so' --exec ln -s $out/lib/zen/{} $out/bin/{}

    # link icons to the appropriate places
    pushd $out/lib/zen/browser/chrome/icons/default
    for icon in *; do
      num=$(sed 's/[^0-9]//g' <<<$icon)
      dir=$out/share/icons/hicolor/"$num"x"$num"/apps

      mkdir -p $dir
      ln -s $PWD/$icon $dir/zen.png
    done
    popd

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
      pciutils
      pipewire
      pulseaudio
      libva
      libnotify
      libglvnd
      mesa
      ffmpeg
    ]}"
    )
    gappsWrapperArgs+=(--set MOZ_LEGACY_PROFILES 1)
    wrapGApp $out/bin/zen
  '';

  desktopItems = makeDesktopItem {
    name = "zen-browser-${sourceInfo.channel}";
    desktopName = "Zen Browser${
      if sourceInfo.variant == "twilight"
      then " Twilight"
      else ""
    }";
    categories = ["Network" "WebBrowser"];
    exec = "zen --name zen %U";
    genericName = "Web Browser";
    icon = "zen";
    keywords = ["Internet" "WWW" "Browser" "Web" "Explorer"];
    mimeTypes = ["text/html" "text/xml" "application/xhtml+xml" "x-scheme-handler/http" "x-scheme-handler/https" "application/x-xpinstall" "application/pdf" "application/json"];
    startupNotify = true;
    startupWMClass = "zen-${sourceInfo.channel}";
    terminal = false;
    extraConfig.X-MultipleArgs = "false";
    actions = {
      new-window = {
        name = "New Window";
        exec = "zen --new-window %U";
      };
      new-private-window = {
        name = "New Private Window";
        exec = "zen --private-window %U";
      };
      profile-manager-window = {
        name = "Profile Manager";
        exec = "zen --ProfileManager %U";
      };
    };
  };

  meta = {
    homepage = "https://zen-browser.app";
    description = "Beautiful, fast, private browser";
    license = lib.licenses.mpl20;
    mainProgram = "zen";
    platforms = [sourceInfo.system];
  };
})
