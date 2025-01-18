# Zen Browser

This is a flake for the Zen browser.

Just add it to your NixOS `flake.nix` or home-manager:

```nix
inputs = {
  zen-browser = {
      url = "github:NikSneMC/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
  };
  ...
}
```

## Packages

This flake exposes four channels, release, alpha, beta and twilight. [There are no generic and specific versions.](https://github.com/zen-browser/desktop/wiki/Why-have-optimized-builds-been-removed%3F)

Then in the `configuration.nix` in the `environment.systemPackages` add one of:

```nix
inputs.zen-browser.packages."${system}".release
inputs.zen-browser.packages."${system}".alpha
inputs.zen-browser.packages."${system}".beta
inputs.zen-browser.packages."${system}".twilight
```

Depending on which version you want

```shell
$ sudo nixos-rebuild switch
$ zen
```

## 1Password

Zen has to be manually added to the list of browsers that 1Password will communicate with. See [this wiki article](https://nixos.wiki/wiki/1Password) for more information. To enable 1Password integration, you need to add the line `.zen-wrapped` to the file `/etc/1password/custom_allowed_browsers`.
