# devkit — `dev` and `run`: per-language Nix dev environments without the
# ceremony.
#
#   dev <lang> [name]  scaffolds flake.nix + .envrc + starter source, inits
#                      git, direnv-allows, and enters the dev shell.
#   dev                just enters the shell of the project you're in.
#   run [build|test|clean]  detects the project type and drives the right
#                      compiler — no remembering `gcc -std=c23 ...`.
#
# Languages: c23, odin, rust, nim, zig, python (uv). Templates in ./templates,
# one dir per language; they ride along in the nix store via the
# DEVKIT_TEMPLATES export below, so scaffolding is offline and needs no
# flake registry or clean git tree.
#
# Wired up in flake.nix (packages.x86_64-linux.{dev,run}) and installed on
# PATH via home/z.nix, same pattern as dispvm/comfyui-vm.
{ pkgs }:
{
  dev = pkgs.writeShellApplication {
    name = "dev";
    # direnv + nix come from the system profile; getent backs pick_shell()
    runtimeInputs = [ pkgs.git pkgs.getent ];
    text = ''
      export DEVKIT_TEMPLATES=${./templates}
    '' + builtins.readFile ./dev.sh;
  };

  # No runtimeInputs on purpose: the toolchains (gcc/odin/cargo/nim/zig/uv) must
  # come from the project's dev shell — that's the whole point of `run`.
  run = pkgs.writeShellApplication {
    name = "run";
    text = builtins.readFile ./run.sh;
  };
}
