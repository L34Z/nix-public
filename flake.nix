{
  description = "z's NixOS — public base (generic desktop, no PII). Layered on by a private wrapper flake.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Quickshell-based desktop shell (bar/launcher/notifs/OSD).
    # Upstream builds against unstable; if quickshell ever fails to build on
    # the 26.05 channel, drop this `follows` and eat the extra store closure.
    caelestia-shell.url = "github:caelestia-dots/shell";
    caelestia-shell.inputs.nixpkgs.follows = "nixpkgs";

    # DankMaterialShell — quickshell-based shell for the niri session.
    dms.url = "github:AvengeMedia/DankMaterialShell";
    dms.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, disko, home-manager, ... }: {
    # ── Reusable modules (a private wrapper flake composes these) ───────────
    # Partial-applied with the public flake's inputs so their home-manager
    # wiring resolves caelestia/dms/self here, not in the consumer.
    nixosModules.base = import ./modules/base.nix { pubInputs = inputs; };
    homeModules.base = import ./home/z.nix { pubInputs = inputs; };

    # ── Disaster-recovery host ──────────────────────────────────────────────
    # A generic, buildable host so the public repo can stand up a fresh box
    # with no credentials. hosts/example/hardware-configuration.nix is a
    # PLACEHOLDER — regenerate it with `nixos-generate-config` on real
    # hardware (and set up disks) before `nixos-rebuild switch`.
    nixosConfigurations.example = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        home-manager.nixosModules.home-manager
        self.nixosModules.base
        ./hosts/example/configuration.nix
      ];
    };

    # ── Disposable VM (Qubes-style dispvm) ──────────────────────────────────
    # Guest config for an amnesic one-shot Firefox session; generic, no
    # hardware passthrough. Wrapped by packages.dispvm below.
    nixosConfigurations.disp = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./modules/dispvm-guest.nix ];
    };

    # ── devkit: `dev` + `run` (home/utils/devkit) ───────────────────────────
    # Per-language Nix dev environments. `dev <lang> [name]` scaffolds
    # flake+direnv+git and enters the shell; `run [build|test|clean]` builds.
    # Languages: c23, odin, rust, nim, python, zig, godot. On PATH via home/z.nix.
    packages.x86_64-linux.dev =
      (import ./home/utils/devkit { pkgs = nixpkgs.legacyPackages.x86_64-linux; }).dev;
    packages.x86_64-linux.run =
      (import ./home/utils/devkit { pkgs = nixpkgs.legacyPackages.x86_64-linux; }).run;

    # `dispvm` — on PATH and in the app launcher via home/z.nix. Wraps the
    # qemu runner so its scratch files (control sockets, xchg share) land on
    # tmpfs and vanish with the VM.
    packages.x86_64-linux.dispvm =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in
      pkgs.writeShellApplication {
        name = "dispvm";
        text = ''
          # Default qemu flags, overridable wholesale by setting QEMU_OPTS:
          #  - GL display: required by the guest's virtio-vga-gl (headless
          #    runs: QEMU_OPTS="-display egl-headless ..." — not "none").
          #  - Audio only when the host has a PipeWire socket, so the VM
          #    still boots from a bare TTY. The stream is a normal client:
          #    route it to your sink once and wireplumber remembers.
          if [ -z "''${QEMU_OPTS:-}" ]; then
            # zoom-to-fit: scale the framebuffer into however the compositor
            # tiles the window; on top of that, cage follows window resizes
            # with a real guest mode change, so once it settles it's 1:1 again.
            QEMU_OPTS="-display gtk,gl=on,zoom-to-fit=on"
            if [ -S "''${XDG_RUNTIME_DIR:-/nonexistent}/pipewire-0" ]; then
              QEMU_OPTS="$QEMU_OPTS -audiodev pipewire,id=snd0 -device virtio-sound-pci,audiodev=snd0"
            fi
          fi
          export QEMU_OPTS
          d=$(mktemp -d -p "''${XDG_RUNTIME_DIR:-/tmp}" dispvm.XXXXXX)
          trap 'cd /; rm -rf "$d"' EXIT
          export TMPDIR="$d"
          cd "$d"
          ${self.nixosConfigurations.disp.config.system.build.vm}/bin/run-disp-vm "$@"
        '';
      };
  };
}
