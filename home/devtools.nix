# devtools — language servers, formatters, and debug adapters for Neovim/Neovide.
#
# The devkit dev shells (home/utils/devkit) deliberately provide *compilers
# only* (gcc/odin/cargo/nim/zig/uv) — see devkit/default.nix. Editor tooling is
# separate, and lives here so it isn't tangled into z.nix's app list.
#
# Why Nix and not mason.nvim: mason ships prebuilt, dynamically-linked binaries
# that don't run on NixOS. LSP servers must come from nixpkgs. Installing them
# here just puts them on PATH — nvim launches each one on demand per open file
# and kills it on exit, so there's no always-running cost. For full features
# (rust-analyzer proc-macros, clangd headers) the *toolchain* also has to be on
# PATH, so launch Neovide from inside a devkit `dev` shell.
#
# Imported by home/z.nix (imports = [ ./devtools.nix ];).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # ── LSP servers (one per devkit language) ──────────────────────────────
    clang-tools # clangd + clang-format  (C23)
    rust-analyzer #                       (Rust)
    ols #          Odin Language Server   (Odin)
    nimlangserver #                       (Nim)
    zls #          Zig Language Server     (Zig)
    typescript-language-server # ts_ls     (TypeScript)
    typescript #   tsserver + tsc backing ts_ls (TypeScript)
    pyright #      types/completion       (Python)
    ruff #         lint + format          (Python)
    gopls #        Go Language Server     (Go)
    gofumpt #      strict gofmt formatter (Go)
    gdtoolkit_4 #  gdlint + gdformat      (Godot / GDScript)
    # GDScript LSP is served by the *running Godot editor* (port 6005) — nvim's
    # `gdscript` LSP connects to it, so there's no standalone server to install.

    # ── Formatters for conform.nvim (format-on-save) ───────────────────────
    # clang-format ships in clang-tools; ruff formats Python; nph formats Nim;
    # Odin formatting comes from ols; Rust via rustfmt and Zig via `zig fmt`
    # (both present in their respective dev shells alongside the compiler).
    nph # Nim formatter
    prettier # TS/JS formatter

    # ── Treesitter build deps ──────────────────────────────────────────────
    # lazy.nvim's nvim-treesitter compiles grammars at runtime, which needs a
    # C compiler and (for some grammars) the tree-sitter CLI on PATH.
    gcc
    tree-sitter

    # ── Debug adapters (nvim-dap, IDE-lite) ────────────────────────────────
    # lldb ships lldb-dap for native binaries (C/Rust/Odin/Nim/Zig); debugpy for
    # Python. Best-effort — wire per-language in nvim as needed.
    lldb
    python3Packages.debugpy

    # Nerd Font (JetBrainsMono) is already installed system-wide in
    # hosts/nix/configuration.nix, so Neovide's glyphs Just Work.
  ];
}
