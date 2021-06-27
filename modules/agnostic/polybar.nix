{ lib, config, pkgs, ... }:

with builtins;
with lib;

# https://github.com/NixOS/nixpkgs/pull/75584/files
# lib.generators.toINI
# lib.formats.ini

let
  cfg = config.services.xserver.sybrand-desktop-environment.polybar;

  # Quick hack, copied code from nixpkgs
  format = {
    type = with lib.types;
      let
        singleIniAtom = nullOr (oneOf [ bool int float str ]) // {
          description = "INI atom (null, bool, int, float or string)";
        };

        iniAtom = coercedTo singleIniAtom lib.singleton (listOf singleIniAtom)
          // {
            description = singleIniAtom.description
              + " or a list of them for duplicate keys";
          };
      in attrsOf (attrsOf iniAtom);

    generate = name: value:
      let
        transformedValue = lib.mapAttrs (section:
          lib.mapAttrs (key: val:
            if lib.isList val then
              concatMapStringsSep " " toString val
            else
              val)) value;
      in pkgs.writeText name (lib.generators.toINI { } transformedValue);
  };
in {
  options.services.xserver.sybrand-desktop-environment.polybar = {
    config = mkOption {
      type = format.type;
      description = ''
        Config for polybar in Nix format, will get automatically translated into Polybar's TOML-like format.
        To write ''${something like this} please use \'\' ''${this format} as that will escape it properly in Nix.
      '';
    };

    enablePomo = mkEnableOption
      "polypomo, this polybar module offers pomodoro functionality. Available as [module/polypomo].";

    wlanInterface = mkOption {
      default = null;
      type = with types; nullOr str;
      example = "wlp3s0";
      description = ''
        The WLAN interface Polybar should get the WIFI status from.
      '';
    };

    dotfile = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final result of the polybar config is made available here.
        You can't change this option as it is read-only.
        Please use `services.xserver.sybrand-desktop-environment.polybar.config` instead.
      '';
    };
  };

  config = {
    # Some fonts providing extra icons
    fonts.fonts = with pkgs; [ font-awesome_5 font-awesome_4 ];

    services.xserver.sybrand-desktop-environment.polybar = {
      dotfile = format.generate "polybar-config" cfg.config;

      config = mkMerge [
        (fromTOML (readFile ./dotfiles/polybar.toml))
        (mkIf cfg.enablePomo {
          "module/polypomo" = {
            type = "custom/script";
            exec = "${polypomo}/polypomo --worktime 1500 --breaktime 300";
            tail = true;

            label = "%output%";
            click-left = "${polypomo}/polypomo toggle";
            click-right = "${polypomo}/polypomo end";
            click-middle = "${polypomo}/polypomo lock";
            scroll-up = "${polypomo}/polypomo time +60";
            scroll-down = "${polypomo}/polypomo time -60";
          };
        })
        (mkIf (cfg.wlanInterface != null) {
          "bar/example".modules-right = mkOrder 100 [ "wlan" ];
          "module/wlan".interface = cfg.wlanInterface;
        })
      ];
    };
  };
}
