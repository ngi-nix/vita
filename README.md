# vita

- upstream: https://github.com/inters/vita
- ngi-nix: https://github.com/ngi-nix/ngi/issues/82

vita is a userspace VPN which operates at L3, kind of like IPSEC of wireguard.

## Status

The package works, NixOS module too, but it doesn't run in a VM and fails with `Couldn't set affinity for cpuset 1.`, I'm assuming it's go something to the with the fact it's a VM or maybe
systemd is blocking it. Honestly no clue.
