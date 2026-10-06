# Example / disaster-recovery host. Pulls in the generic base plus a PLACEHOLDER
# hardware profile so the flake evaluates and a fresh box can be stood up.
#
# On real hardware:
#   1. Boot the NixOS installer, partition + format your disks, mount at /mnt.
#   2. `nixos-generate-config --root /mnt` and copy the generated
#      hardware-configuration.nix over the placeholder here.
#   3. `nixos-install --flake .#example` (or rebuild switch once booted).
{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "example";

  # Rebuild this same flake with `nh os switch` once installed.
  programs.nh.flake = "/home/z/nix/public";
}
