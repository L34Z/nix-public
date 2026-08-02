# ─────────────────────────────────────────────────────────────────────────
# PLACEHOLDER hardware profile — NOT bootable as-is.
#
# This exists only so `nixosConfigurations.example` EVALUATES (for CI / a
# sanity `nix flake check`). The filesystems below reference labels that won't
# exist on your machine. On real hardware, REGENERATE this file:
#     nixos-generate-config --root /mnt   # then copy hardware-configuration.nix here
# and set up your disks (LUKS/btrfs/ext4, whatever you like).
# ─────────────────────────────────────────────────────────────────────────
{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Common desktop/laptop initrd modules — adjust to your hardware.
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ]; # or "kvm-amd"
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # PLACEHOLDER filesystems — replace with your real layout. Evaluates fine;
  # only fails at boot/activation, which is the intended "regenerate me" signal.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };
}
