{ pkgs, lib, config, ... }:
with lib;

let
  cfg = config.services.vita;

  instanceModule = types.submodule
    {
      options = {
        xdp = mkEnableOption "Enable XDP sockets.";

        cpus = mkOption {
          type = with types; nullOr (listOf int);
          description = "Which CPUs should Vita use.";
          default = null;
        };
        
        config = mkOption {
          type = with types; attrsOf (
            oneOf [ str bool int
                    (listOf (attrsOf (oneOf [ str bool int
                                              (listOf (attrsOf (oneOf [str bool int])))
                                            ])))
                  ]);
          description = "Vita config.";
          example = literalExample ''
            {
              public-interface4 = [
                {
                  queue = 1;
                  ifname = "eth1";
                  device-queue = "1";
                  mac = "0a:42:13:9e:a8:ae";
                  ip = "172.31.1.30";
                  nat-ip = "203.0.113.2";
                  nexthop-ip = "172.31.0.1";
                }
              ];

              mtu = 1440;

              route4 = [
                {
                  id = "tokyo";
                  gateway = [
                    { queue = 1; ip = "203.0.113.5"; }
                  ];
                  net = "172.32.0.0/16";
                  preshared-key = "ACAB129A";
                  spi = 1234;
                }
              ];
            };
          '';
          apply = x:
            mapAttrsToList (n1: e1:
              if isString e1 then
                "${n1} \"${e1}\";\n"
              else if isInt e1 then
                "${n1} \"${toString e1}\";\n"
              else if isBool e1 then
                "${n1} ${if e1 then "true" else "false"};\n"
              else if isList e1 then
                map (e2:
                  "${n1} {\n" +
                  (concatStringsSep "\n" (mapAttrsToList (n3: e3:
                    if isString e3 then
                      "${n3} \"${e3}\";"
                    else if isInt e3 then
                      "${n3} \"${toString e3}\";"
                    else if isBool e3 then
                      "${n3} ${if e3 then "true" else "false"};"
                    else if isList e3 then
                      concatStringsSep "\n" (map (e4:
                        "gateway {" +
                        (concatStringsSep " " (mapAttrsToList (n5: e5:
                          if isString e5 then
                            "${n5} \"${e5}\";"
                          else if isInt e5 then
                            "${n5} \"${toString e5}\";"
                          else if isBool e5 then
                            "${n5} ${if e5 then "true" else "false"};"
                          else
                            abort "Invalid value"
                        ) e4))
                        + "}"
                      ) e3)
                    else
                      abort "Invalid value"
                  ) e2))
                  + "\n}\n"
                ) e1
              else
                abort "Invalid value"
            ) x;
        };
      };
    };
in

{
  options.services.vita = {
    enable = mkEnableOption "Enable vita, a high-performance IPsec VPN gateway";

    instances = mkOption {
      type = types.attrsOf instanceModule;
      description = "Vita instance";
      default = {};
      example = literalExample ''
        instances = {
          paris.config = { ... };
          tokyo.config = { ... };
        };
      '';
    };

    package = mkOption {
      type = types.package;
      description = "Vita package.";
      default = pkgs.vita;
    };
  };

  config = mkIf cfg.enable {
    systemd.services = mapAttrs' (n: v: nameValuePair "vita-${n}"
      { description = "Vita instance ${n}";

        wantedBy = [ "network.target" ];

        serviceConfig = {
          ExecStart = ''
            ${cfg.package}/bin/vita \
              --name ${n} \
              ${if v.xdp then "--xdp" else ""} \
              ${if v.cpus != null then "--cpu " + (concatMapStringsSep "," (x: toString x) v.cpus) else ""}
          '';
          ExecStartPost = pkgs.writeShellScript "vita-post-start" ''
            timeout=60

            while [[ ! -d /var/run/snabb/by-name/paris/ ]];
            do
              # When the timeout is equal to zero, show an error and leave the loop.
              if [[ "$timeout" == 0 ]]; then
                echo "ERROR: Timeout while waiting for /var/run/snabb/by-name/paris/."
                exit 1
              fi

              sleep 1

              # Decrease the timeout of one
              ((timeout--))
            done 
            
            ${cfg.package}/bin/snabb config set ${n} / < ${pkgs.writeText "vita-${n}.conf" v.config}
          '';
        };
      }) cfg.instances;
  };
}
