# Stolen from:
# https://github.com/splintah/xmonad-splintah/blob/master/flake.nix
{
  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      haskellPackages = pkgs.haskellPackages;
    in {
      packages.${system}.xmonad-sybrand =
        haskellPackages.callPackage ./derivation.nix { };

      defaultPackage.${system} = self.packages.${system}.xmonad-sybrand;

      # Build script for XMonad, used for recompiling.
      # See https://github.com/xmonad/xmonad/blob/master/CHANGES.md#enhancements-1
      apps.${system}.build = {
        type = "app";
        program = let
          build = pkgs.writeScriptBin "build" ''
            #!${pkgs.stdenv.shell}
            dist=$1
            cp ${self.packages.${system}.xmonad-sybrand}/bin/xmonad "$dist"
            chmod a+w "$dist"
          '';
        in "${build}/bin/build";
      };

      defaultApp.${system} = {
        type = "app";
        program = "${self.packages.${system}.xmonad-sybrand}/bin/xmonad";
      };
    };
}
