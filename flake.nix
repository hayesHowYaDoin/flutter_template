{
  description = "Flutter project template utilizing nix flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devenv.url = "github:cachix/devenv";
    nix-github-actions.url = "github:nix-community/nix-github-actions";
    android.url = "github:tadfisher/android-nixpkgs";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    devenv,
    nix-github-actions,
    android,
    ...
  }@inputs:
    {
      overlay = final: prev: {
        inherit (self.packages.${final.system}) android-sdk android-studio;
      };
    }
    //
    flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ] (system:
      let
        inherit (nixpkgs) lib;
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Work around the lack of extension ordering in VS Code
        # See: https://github.com/Microsoft/vscode/issues/57481#issuecomment-910883638
        loadAfter = deps: pkg: pkg.overrideAttrs (old: {
          nativeBuildInputs = old.nativeBuildInputs or [] ++ [ pkgs.jq pkgs.moreutils ];

          preInstall = ''
            ${old.preInstall or ""}
            jq '.extensionDependencies |= . + $deps' \
            --argjson deps ${lib.escapeShellArg (builtins.toJSON deps)} \
            package.json | sponge package.json
          '';
        });

        extensions = with pkgs.vscode-extensions; [
	        mkhl.direnv
          (loadAfter [ "mkhl.direnv" ] bbenoist.nix)
          (loadAfter [ "mkhl.direnv" ] dart-code.flutter)
          (loadAfter [ "mkhl.direnv" ] jnoortheen.nix-ide)
        ];
      in {
        packages.devenv-up = self.devShells.${system}.default.config.procfileScript;
        packages.devenv-test = self.devShells.${system}.default.config.test;

        devShell = devenv.lib.mkShell {
          inherit pkgs inputs;
          modules = [
            ({ pkgs, config, ... }: {
              devcontainer.enable = true;

              packages = with pkgs; [
                flutter
                chromium
              ] ++ [
                (vscode-with-extensions.overrideAttrs (finalAttrs: previousAttrs: {
                  vscodeExtensions = previousAttrs.vscodeExtensions ++ extensions;
                }))
              ];

              android = {
                enable = true;
                flutter.enable = true;
              };
            })
          ];
        };
      }
    );
}
