{
  wrapFirefox,
  zen-browser-unwrapped,
  sourceInfo,
  iconsDir ? "browser/chrome/icons/default",
  ...
}:
wrapFirefox (zen-browser-unwrapped.override {inherit iconsDir;}) {
  pname = "zen-browser-${sourceInfo.variant}";
}
