# https://github.com/splintah/xmonad-splintah/blob/master/xmonad-splintah/xmonad-splintah.nix
{ mkDerivation, base, containers, process, stdenv, X11, xmonad, xmonad-contrib
, xmonad-extras }:

mkDerivation {
  pname = "xmonad-sybrand";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends =
    [ base containers process X11 xmonad xmonad-contrib xmonad-extras ];
  license = stdenv.lib.licenses.agpl3;
}
