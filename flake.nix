{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-21.05";
  };

  outputs = { nixpkgs, self }:
    let
      supportedSystems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
      forAllSystems' = systems: fun: nixpkgs.lib.genAttrs systems fun;
      forAllSystems = forAllSystems' supportedSystems;
    in
    {
      overlays.vita = final: prev:
        let
          version = "master";
          src = prev.fetchFromGitHub {
            owner = "inters";
            repo = "vita";
            rev = version;
            sha256 = "sha256-B6VNtRd3TtpFroG8Ze9fOdTrnAPJRW9EpbfvhDyusdI=";
          };
        in
          {
            vita = import (src)
              { pkgs = prev;
                inherit version;
              };
          };

      defaultPackage = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; overlays = [ self.overlays.vita ]; };
        in
          pkgs.vita
      );

      hydraJobs = forAllSystems (system: {
        build = self.defaultPackage.${system};
      });

      nixosConfigurations = forAllSystems (system:
        nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
            ./module.nix
            ({ ... }:
              {
                nixpkgs.overlays = [ self.overlays.vita ];

                users.users.main = {
                  extraGroups = [ "wheel" ];
                  password = "toor";
                  isNormalUser = true;
                };

                services.vita = {
                  enable = true;

                  instances."paris" = {
                    xdp = true;
                    cpus = [ 1 ];
                    config = {
                      private-interface4 = [
                        {
                          ifname = "eth1";
                          mac = "0a:cc:b1:e4:24:d2";
                          ip = "172.31.1.20";
                          nexthop-ip = "172.31.0.1";
                        }
                      ];

                      public-interface4 = [
                        {
                          queue = 1;
                          ifname = "eth2";
                          device-queue = "1";
                          mac = "0a:42:13:9e:a8:ae";
                          ip = "172.31.1.30";
                          nat-ip = "203.0.113.2";
                          nexthop-ip = "172.31.0.1";
                        }

                        {
                          queue = 2;
                          ifname = "eth3";
                          device-queue = 1;
                          mac = "0a:33:39:04:9c:ac";
                          ip = "172.31.1.40";
                          nat-ip = "203.0.113.3";
                          nexthop-ip = "172.31.0.1";
                        }
                      ];

                      mtu = 1440;

                      route4 = [
                        {
                          id = "tokyo";
                          gateway = [
                            { queue = 1; ip = "203.0.113.5"; }
                            { queue = 2; ip = "203.0.113.6"; }
                          ];
                          net = "172.32.0.0/16";
                          preshared-key = "ACAB129A...";
                          spi = 1234;
                        }
                      ];
                    };
                  };
                };
              })
          ];
        }
      );
    };
}
