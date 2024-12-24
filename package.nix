{
  wrapFirefox,
  unwrapped,
  iconsDir ? "browser/chrome/icons/default",
  ...
}:
wrapFirefox (unwrapped.override {inherit iconsDir;}) {
  pname = "zen-browser";
}
