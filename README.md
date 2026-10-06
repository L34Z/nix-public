# public

Generic NixOS desktop base — Hyprland + niri, caelestia/DankMaterialShell,
1Password, browsers, a Neovim dev toolchain, and live-editable dotfiles.
No machine-specific hardware, no personal projects, no secrets. This repo is
self-contained: it builds and boots a working desktop on its own, which makes
it a safe disaster-recovery baseline.

Machine-specific and private things (GPU passthrough, VM guests, VPN accounts,
git identity + signing key, real disk layout) live in a separate **private
wrapper flake** that pulls this repo in as an input and layers them on top.

## What's here

- `flake.nix` — exposes `nixosModules.base`, `homeModules.base`,
  `packages.{dev,run,dispvm}`, and a buildable `nixosConfigurations.example`.
- `modules/base.nix` — the generic system module (DE, audio, bluetooth,
  1Password, dev tooling, fonts, users). Partial-applied with the flake inputs.
- `modules/{desktop,greeter,niri,steam,dispvm-guest}.nix` — desktop pieces.
- `home/z.nix` — `homeModules.base`: base apps + dotfiles wiring.
- `home/dotfiles/` — hypr, niri, fish, kitty, nvim, caelestia configs
  (symlinked live into `~/.config`, editable without a rebuild).
- `home/utils/devkit/` — the `dev` / `run` per-language project scaffolder.
- `hosts/example/` — a placeholder host for fresh installs.

## Set up a fresh box (disaster recovery)

1. Boot the NixOS installer; partition, format, and mount your disks at `/mnt`.
2. `git clone <this repo> /mnt/home/z/nix/public`
3. `nixos-generate-config --root /mnt` and copy the generated
   `hardware-configuration.nix` over `hosts/example/hardware-configuration.nix`.
4. `nixos-install --flake /mnt/home/z/nix/public#example`
5. Reboot, then rebuild with `nh os switch` (points at `~/nix/public`).

## Compose the private layer

The private wrapper flake references this repo with an absolute `git+file:` input
and adds its own host, hardware, and personal home-manager module:

```nix
inputs.pub.url = "git+file:///home/z/nix/public";
# ...
nixosConfigurations.<host> = nixpkgs.lib.nixosSystem {
  modules = [
    home-manager.nixosModules.home-manager
    pub.nixosModules.base
    ./hosts/<host>/configuration.nix   # imports hardware + private modules
    { home-manager.users.z.imports = [ ./home/private.nix ]; }
  ];
};
```
