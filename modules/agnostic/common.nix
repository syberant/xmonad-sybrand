{ pkgs, lib, config, ... }:

with lib;
let
  inherit (lib) mkEnableOption mkOption mkIf;
  cfg = config.services.xserver.sybrand-desktop-environment;
in {
  options.services.xserver.sybrand-desktop-environment = {
    enable = mkEnableOption "Sybrand's desktop environment";

    xmonad = mkEnableOption "Sybrand's XMonad build" // { default = true; };

    autostart = mkOption {
      default = "";
      type = with types; lines;
      description = ''
        Programs that should be automatically started by the DE/WM.
      '';
    };

    impureConfig = mkEnableOption "non self-contained settings";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.xserver.windowManager.xmonad-sybrand.enable =
        mkIf cfg.xmonad true;

      # TODO: clean this the fuck up.
      services.xserver.sybrand-desktop-environment.autostart = ''
        ${pkgs.polybar}/bin/polybar -c ${
          pkgs.callPackage ./dotfiles/polybar.nix {
            config = config.systemInfo;
            polybar = { modules-left = "ewmh"; };
          }
        } example &
        ${pkgs.sxhkd}/bin/sxhkd -c ${
          pkgs.callPackage ./dotfiles/sxhkdrc.nix { }
        } &
        ${pkgs.dunst}/bin/dunst -config ${./dotfiles/dunst-config} &
        ~/.fehbg || feh --bg-fill ${./background.jpg}
      '';

      environment.systemPackages = with pkgs; [
        (writeScriptBin "autostart_sybrand_de" cfg.autostart)
        feh
        st
      ];

    }
    (mkIf cfg.impureConfig {
      # Hide mouse after a while
      services.unclutter = {
        enable = true;
        extraOptions = [ "noevents" "idle 2" ];
      };

      # Enable the X11 windowing system.
      services.xserver = {
        # Keyboard delay
        autoRepeatDelay = 250;
        xkbOptions = "compose:ralt";
      };

      # Enable compton
      services.compton = {
        enable = true;
        opacityRules = [
          "90:class_g = 'st-256color'"
          # "90:class_g = 'st-256color' && enabled"
          # "70:class_g = 'st-256color' && !enabled"
        ];
      };
    })
  ]);
}
