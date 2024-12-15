{
  wrapFirefox,
  zen-browser-unwrapped,
  sourceInfo,
  ...
}:
wrapFirefox zen-browser-unwrapped {
  pname = "zen-browser-${sourceInfo.variant}";
}
