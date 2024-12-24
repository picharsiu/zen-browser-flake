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
    systems = {
      aarch64-linux = "linux-aarch64";
      x86_64-linux = "linux-x86_64";
    };
  in
    flake-utils.lib.eachSystem (builtins.attrNames systems) (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) lib;

      info = lib.pipe ./info.json [
        builtins.readFile
        builtins.fromJSON
      ];

      mkZen = channel: let
        sourceInfo = {
          inherit channel system;
          inherit (info.${channel}) version;
          src = info.${channel}.systems.${systems.${system}};
        };

        unwrapped = pkgs.callPackage ./package-unwrapped.nix {inherit sourceInfo;};
        wrapped = pkgs.callPackage ./package.nix {inherit unwrapped;};
      in {
        "${channel}-unwrapped" = unwrapped;
        ${channel} = wrapped;
      };

      mkZenChannels = channels:
        lib.pipe channels [
          (map mkZen)
          lib.zipAttrs
          (builtins.mapAttrs (_: drv: builtins.elemAt drv 0))
        ];
    in {
      packages = mkZenChannels [
        "alpha"
        "beta"
        "twilight"
      ];
    });
}
