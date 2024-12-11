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
  }:
    flake-utils.lib.eachSystem [
      "aarch64-linux"
      "x86_64-linux"
    ] (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) lib;

      info = lib.pipe ./info.json [
        builtins.readFile
        builtins.fromJSON
      ];

      mkZen = channel: variant:
        pkgs.callPackage ./package.nix {
          sourceInfo = {
            inherit channel variant system;
            src = info.${channel}.${variant};
            inherit (info.${channel}) version;
          };
        };

      mkZenChannel = channel: variants:
        lib.pipe variants [
          (map (variant: lib.nameValuePair variant (mkZen channel variant)))
          builtins.listToAttrs
        ];

      mkZenChannels = channels: variants:
        lib.pipe channels [
          (map (channel: lib.nameValuePair channel (mkZenChannel channel variants)))
          builtins.listToAttrs
        ];
    in {
      packages =
        mkZenChannels [
          "alpha"
          "beta"
          "twilight"
        ] (
          if system == "aarch64-linux"
          then ["aarch64"]
          else [
            "generic"
            "specific"
          ]
        );
    });
}
