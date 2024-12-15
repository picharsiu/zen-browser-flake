{
  description = "Zen Browser";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: let
    variants = {
      aarch64-linux = ["aarch64"];
      x86_64-linux = ["generic" "specific"];
    };
  in
    flake-utils.lib.eachSystem (builtins.attrNames variants) (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) lib;

      info = lib.pipe ./info.json [
        builtins.readFile
        builtins.fromJSON
      ];

      mkZen = {
        channel,
        variant,
      }: let
        sourceInfo = {
          inherit channel variant system;
          src = info.${channel}.${variant};
          inherit (info.${channel}) version;
        };
        unwrapped = pkgs.callPackage ./package-unwrapped.nix {inherit sourceInfo;};
        wrapped = pkgs.callPackage ./package.nix {
          inherit sourceInfo;
          zen-browser-unwrapped = unwrapped;
        };
      in {
        ${channel} = {
          "${variant}-unwrapped" = unwrapped;
          ${variant} = wrapped;
        };
      };

      mkZenChannels = channel: variant:
        lib.pipe {inherit channel variant;} [
          lib.cartesianProduct
          (map mkZen)
          (builtins.zipAttrsWith (
            name: values:
              lib.pipe values [
                (map lib.attrsToList)
                builtins.concatLists
                builtins.listToAttrs
              ]
          ))
        ];
    in {
      packages = mkZenChannels [
        "alpha"
        "beta"
        "twilight"
      ]
      variants.${system};
    });
}
