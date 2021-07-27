# vita

- upstream: https://github.com/inters/vita
- ngi-nix: https://github.com/ngi-nix/ngi/issues/82

vita is a userspace VPN which operates at L3, kind of like IPSEC of wireguard.

> :warning: As most Flakes in `nig-ngi` this Flake is a **work in progress**!

## Using

In order to use this [flake](https://nixos.wiki/wiki/Flakes) you need to have the 
[Nix](https://nixos.org/) package manager installed on your system. Then you can simply run this 
with:

```
$ nix run github:ngi-nix/vita
```

You can also enter a development shell with:

```
$ nix develop github:ngi-nix/vita
```

For information on how to automate this process, please take a look at [direnv](https://direnv.net/).

A working NixOS module is available at `thisFlake.nixosModule`.

## Status

The package itself works and is in fact fetched from upstream. The only current issue is vita not
working in unprivileged containers which is expected nor in VMs or on any of my systems. (the two
possible network drivers are XDP, which doesn't work in containers or the intel NIC driver, which I
assume doesn't work on non Intel platforms or NICs). I may be completely wrong about everything, 
the documentation is sparse and confusing.
