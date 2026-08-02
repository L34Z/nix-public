# Base home-manager config. Consumed as `homeModules.base` via partial
# application: the public flake calls `import ./home/z.nix { pubInputs = inputs; }`
# so the caelestia/dms/self references resolve against the PUBLIC flake's inputs
# without needing `inputs` threaded through home-manager.extraSpecialArgs (that
# slot is left free for the private layer's own inputs).
{ pubInputs }:
{ config, pkgs, lib, ... }:

let
  # The public repo is expected to live at ~/nixos-public on the installed
  # system. hypr/fish/nvim/kitty/niri are linked "out of store" so you can edit
  # them live (SUPER+ALT+H etc.) without a rebuild. The path is a plain string,
  # so it points at the working-tree checkout, never the flake's store copy —
  # that's what keeps live-edit working under a `path:` flake input.
  repo = "${config.home.homeDirectory}/nixos-public";
  live = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";
in
{
  # devtools.nix carries the Neovim/Neovide toolchain (LSP servers, formatters,
  # debug adapters) via Nix — kept out of the app list below.
  imports = [ ./devtools.nix ];

  home.username = "z";
  home.homeDirectory = "/home/z";
  home.stateVersion = "26.05"; # do not change later

  programs.home-manager.enable = true;

  # ── Cursor ───────────────────────────────────────────────────────────────
  # Without a theme installed Hyprland falls back to the bare X11 pointer.
  # This installs Bibata and wires up XCURSOR (x11), GTK, and hyprcursor at
  # once. This is the SINGLE source of the cursor theme/size for the session:
  # it exports XCURSOR_*/HYPRCURSOR_*, so hyprland.lua no longer sets them.
  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };

  # ── Icon theme ───────────────────────────────────────────────────────────
  # Without a full icon theme installed only `hicolor` exists, which has
  # almost no named icons. blueman-applet then renders broken icons both for
  # its tray icon and for every entry in its right-click device menu
  # (audio-card, input-mouse, phone, bluetooth, blueman-*), and DMS's taskbar
  # tray — which resolves the same StatusNotifierItem icon names against the
  # XDG icon theme — shows the same breakage. Papirus has complete blueman
  # coverage. Enabling the gtk module also writes ~/.config/gtk-{3,4}.0 so
  # GTK apps and quickshell/DMS pick the theme up.
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
  };

  # Polkit auth agent — GUI privilege prompts (gparted, flatpak, etc.)
  # don't work in a bare Hyprland session without one. Starts with
  # graphical-session.target, which exists because of UWSM.
  services.hyprpolkitagent.enable = true;

  # ── Caelestia shell ──────────────────────────────────────────────────────
  # Quickshell-based shell: bar + launcher + notifications + OSD + session
  # menu. Replaces waybar/rofi/swaync/hyprpaper. Module comes from the
  # caelestia-shell flake input (wired in via home-manager.sharedModules).
  # Keybinds stay in hyprland.lua: the shell only *registers* global
  # shortcuts (caelestia:launcher etc.); nothing is bound unless we bind it.
  programs.caelestia = {
    enable = true;
    # QML overrides, swapped in at install time. The QML is installed as
    # plain files, so this only re-runs the cheap install step — the C++
    # plugin derivations are reused as-is.
    #  - ColourSelect: upstream's nexus "Colours" sub-page is an
    #    under-construction stub; replace it with our colour editor.
    #  - ActiveWindow: bar window title in m3onPrimary instead of m3primary.
    package = pubInputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli.overrideAttrs (prev: {
      postInstall = (prev.postInstall or "") + ''
        install -Dm644 ${./dotfiles/caelestia/nexus/ColourSelect.qml} \
          $out/share/caelestia-shell/modules/nexus/pages/wallandstyle/ColourSelect.qml
        install -Dm644 ${./dotfiles/caelestia/bar/ActiveWindow.qml} \
          $out/share/caelestia-shell/modules/bar/components/ActiveWindow.qml
      '';
    });
    # Started from hyprland.lua's autostart like every other session process,
    # not as a systemd unit — keeps startup logic in one place.
    systemd.enable = false;
    cli.enable = true; # `caelestia` command (shell IPC, wallpaper, etc.)
    # NO `settings` here on purpose: the module renders settings as a read-only
    # store symlink at ~/.config/caelestia/shell.json, but the shell writes its
    # config back at runtime (nexus settings app, config plugin) and spams
    # "Failed to write: Read-only file system" otherwise. shell.json is kept as
    # a plain mutable file instead; seed copy in home/dotfiles/caelestia/.
  };

  # ── DankMaterialShell (niri session) ─────────────────────────────────────
  # Installs the dms CLI + quickshell + deps (dgop, matugen, cava, khal).
  # Runs as a systemd user unit (dms.service, satisfies the DMS system check).
  # The unit binds to graphical-session.target, which the Hyprland session
  # also activates — the ConditionEnvironment below keeps it niri-only: both
  # compositors import XDG_CURRENT_DESKTOP into the systemd user environment
  # before starting the target, so the condition fails under Hyprland and
  # caelestia keeps the session to itself.
  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
  };
  systemd.user.services.dms.Unit.ConditionEnvironment = "XDG_CURRENT_DESKTOP=niri";

  # ── Base apps ────────────────────────────────────────────────────────────
  # Generic desktop set — no personal projects or hardware-bound tools (those
  # are layered in by the private home module). 1Password is system-level in
  # modules/base.nix for polkit/ssh-agent.
  home.packages = with pkgs; [
    firefox
    google-chrome
    pubInputs.self.packages.${pkgs.stdenv.hostPlatform.system}.dispvm # disposable Firefox VM (modules/dispvm-guest.nix)
    pubInputs.self.packages.${pkgs.stdenv.hostPlatform.system}.dev # scaffold/enter per-language nix dev shells (home/utils/devkit)
    pubInputs.self.packages.${pkgs.stdenv.hostPlatform.system}.run # in-shell build/run/test dispatcher (home/utils/devkit)
    claude-code
    bubblewrap # sandbox engine for the play/play-offline/play-gpu functions (aliases.fish)
    hyprpicker # screen colour picker; the nexus Colours page shells out to it
    qbittorrent
    mpv
    qimgv # image/media viewer; plays video via mpv
    neovide
    discord
    stremio-linux-shell
    yt-dlp
    fastfetch
    obsidian
    gh
  ];

  # ── Steam data on the storage SSD ────────────────────────────────────────
  # Steam itself is enabled system-side (modules/steam.nix). Its entire data
  # dir is redirected to /storage/games/steam so games land on the big drive
  # with zero Steam UI configuration. Target dir is created by a tmpfiles rule
  # in modules/steam.nix (on a box without /storage it just lands on root).
  home.file.".local/share/Steam".source =
    config.lib.file.mkOutOfStoreSymlink "/storage/games/steam";

  # ── Dotfiles ─────────────────────────────────────────────────────────────
  # Live-editable (symlink into the repo working tree):
  xdg.configFile."hypr".source = live "home/dotfiles/hypr";
  xdg.configFile."fish".source = live "home/dotfiles/fish";
  xdg.configFile."niri".source = live "home/dotfiles/niri";
  # kitty must be writable too: DMS's theme worker (matugen) writes
  # kitty/dank-theme.conf on every colour-mode switch and dies with EROFS
  # if the dir is a store symlink.
  xdg.configFile."kitty".source = live "home/dotfiles/kitty";
  # nvim must be writable for the same reason as kitty: DMS/matugen writes the
  # generated colorscheme (colors/dms.lua + lua/lualine/themes/dms.lua) into
  # this dir on every colour-mode switch. lazy.nvim also manages plugins under
  # ~/.local/share/nvim, outside the repo. Enable the matugen target with
  # matugenTemplateNeovim=true in ~/.config/DankMaterialShell/settings.json.
  xdg.configFile."nvim".source = live "home/dotfiles/nvim";
  # (waybar link removed with the caelestia migration; home/dotfiles/waybar
  # kept in the repo for reference/rollback)

  # ── Disposable Firefox VM: launcher entry ────────────────────────────────
  # Qubes-style amnesic browser — one throwaway QEMU VM per click, RAM-only,
  # gone on close. VM defined in modules/dispvm-guest.nix, wrapper in
  # flake.nix (packages.dispvm, also installed above so `dispvm` is on PATH).
  xdg.desktopEntries.dispvm = {
    name = "Disposable Firefox";
    comment = "Amnesic private-browsing VM — RAM-only, leaves no trace";
    exec = "${pubInputs.self.packages.${pkgs.stdenv.hostPlatform.system}.dispvm}/bin/dispvm";
    icon = "firefox";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
  };

  # ── SSH via 1Password agent ──────────────────────────────────────────────
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # skip home-manager's default Host * block
    settings."*".IdentityAgent = "~/.1password/agent.sock";
  };

  # ── Git ──────────────────────────────────────────────────────────────────
  # Enabled here with NO identity or signing on purpose: a public-only box has
  # no signing key, and forcing commit.gpgsign would make every `git commit`
  # fail. The private home layer adds user.{name,email,signingkey} + signing.
  programs.git.enable = true;
}
