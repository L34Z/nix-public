# Generic system base. Consumed as `nixosModules.base` via partial application
# (`import ./modules/base.nix { pubInputs = inputs; }`) so the home-manager
# wiring can reference the PUBLIC flake's caelestia/dms/self inputs.
#
# This is everything a fresh box needs for a working desktop with NO PII and no
# host-specific hardware: DE (Hyprland + niri), 1Password, browsers, audio,
# bluetooth, dev tooling, fonts. Host-specific bits (hostName, disk/LUKS,
# GPU passthrough, VPN accounts, nh.flake path) are set by the consuming host.
{ pubInputs }:
{ config, pkgs, lib, ... }:

{
  imports = [
    ./desktop.nix # Hyprland + caelestia shell
    ./greeter.nix # greetd + tuigreet session picker
    ./niri.nix # niri compositor (DMS session)
    ./steam.nix # steam + gamemode
  ];

  networking.networkmanager.enable = true;
  # Split DNS so per-interface resolvers (Tailscale MagicDNS, Mullvad tunnel
  # DNS) coexist instead of fighting over a single global /etc/resolv.conf.
  services.resolved.enable = true;

  # ── Boot ────────────────────────────────────────────────────────────────
  # Generic systemd-boot + plymouth splash. LUKS/crypttab (if any) is the
  # host's concern — nothing disk-specific here.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true; # clean graphical LUKS prompt when a host adds one
  boot.plymouth.enable = true;
  boot.kernelParams = [ "quiet" "splash" ];

  # ── Swap ────────────────────────────────────────────────────────────────
  zramSwap.enable = true; # compressed RAM swap, no disk swap / no hibernation

  # ── Locale / time ───────────────────────────────────────────────────────
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Nix itself ──────────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "@wheel" ];
  nixpkgs.config.allowUnfree = true;

  # ── User ────────────────────────────────────────────────────────────────
  users.users.z = {
    isNormalUser = true;
    description = "z";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" "audio" "input" ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # if a real file is in the way of a managed one, back it up instead of
    # failing the whole activation
    backupFileExtension = "hm-bak";
    sharedModules = [
      pubInputs.caelestia-shell.homeManagerModules.default
      pubInputs.dms.homeModules.dank-material-shell
      # NOT inputs.dms.homeModules.niri — that one assumes sodiboo's
      # niri-flake (programs.niri.settings); our niri config is a plain
      # live-editable config.kdl like the hypr dotfiles.
    ];
    # The private layer merges a second `users.z.imports = [ ./home/private.nix ]`
    # onto this (list concatenation), adding VM runners + git identity/signing.
    users.z.imports = [ (import ../home/z.nix { inherit pubInputs; }) ];
  };

  # ── System-level programs / services ────────────────────────────────────
  programs.fish.enable = true;
  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;
  # nix-direnv rides along by default: caches `use flake` evaluation and pins
  # GC roots so project toolchains survive nix-collect-garbage. The devkit
  # templates' .envrc rely on this.
  programs.direnv.enable = true;

  # 1Password needs to be system-level for polkit + the SSH agent to work.
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "z" ];
  };

  # Helps random downloaded binaries and editor tooling run on NixOS.
  programs.nix-ld.enable = true;
  services.envfs.enable = true;

  services.flatpak.enable = true;
  services.udisks2.enable = true;
  services.fstrim.enable = true;

  # `nh os switch` — the consuming host sets `programs.nh.flake` to its own
  # flake path (public example → nixos-public; private → nixos-private).
  programs.nh.enable = true;

  # ── Audio: pipewire ─────────────────────────────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ── Bluetooth ───────────────────────────────────────────────────────────
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # ── System packages (CLI + infrastructure only) ─────────────────────────
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    unzip
    killall
    tldr
    zoxide
    fzf
    bat
    eza
    btop
    fastfetch
    oh-my-posh
    wl-clipboard
    nix-search-cli
    ntfs3g
    pciutils
    appimage-run
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    inter # "Inter Variable" — DMS default UI font
    fira-code # DMS default monospace font
  ];

  system.stateVersion = "26.05"; # do not change later
}
