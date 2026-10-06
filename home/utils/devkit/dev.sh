# dev — scaffold and enter per-language Nix dev environments.
# Wrapped by writeShellApplication (default.nix), which prepends
# `set -euo pipefail` + shellcheck and exports DEVKIT_TEMPLATES (a nix
# store path holding ./templates).

usage() {
  cat <<'EOF'
dev — scaffold and enter per-language Nix dev environments

Usage:
  dev                 enter the dev shell of the project in the current dir
  dev <lang>          scaffold a new project HERE, then enter its shell
  dev <lang> <name>   create ./<name>, scaffold inside, then enter its shell
  dev godot [name] -cs  scaffold a C#/.NET Godot project instead of GDScript

Languages: c (alias: c23), odin, rust, nim, zig, typescript (alias: ts), python (alias: py), go, godot

Scaffolding writes flake.nix + .envrc + starter source + a .dev marker,
inits git if needed, `git add`s everything (flakes can't see untracked
files), direnv-allows, and drops you into a subshell with the toolchain
on PATH. `exit` returns to your previous shell.

Inside the shell, `run` builds/runs/tests the project (see: run --help).
EOF
}

# The shell to drop the user into. $SHELL normally — but nix print-dev-env
# exports SHELL=<store path of stdenv's readline-less build bash>, so inside
# an already-loaded dev env (old .envrc without the SHELL guard) $SHELL is
# poisoned and would render prompts with literal \[ \]. Distrust store
# paths; fall back to the login shell from passwd.
pick_shell() {
  case "${SHELL:-}" in
    "" | /nix/store/*) getent passwd "$(id -un)" | cut -d: -f7 ;;
    *) echo "$SHELL" ;;
  esac
}

enter() {
  if [ -f .envrc ]; then
    direnv allow .
    exec direnv exec . "$(pick_shell)"
  elif [ -f flake.nix ]; then
    exec nix develop
  else
    echo "dev: no project in $PWD (no .envrc or flake.nix)" >&2
    echo "  start one: dev <lang> [name]   (languages: c odin rust nim zig typescript python go godot)" >&2
    exit 1
  fi
}

case "${1:-}" in
  -h | --help | help)
    usage
    exit 0
    ;;
  "") enter ;;
esac

# Optional -cs/--csharp variant, valid only with godot. Strip it from
# anywhere in the args so the rest parse as `<lang> [name]` as usual.
variant=""
rest=()
for a in "$@"; do
  case "$a" in
    -cs | --csharp) variant=cs ;;
    *) rest+=("$a") ;;
  esac
done
set -- "${rest[@]}"

case "${1:-}" in
  c | c23) tpl=c23 ;;
  odin) tpl=odin ;;
  rust) tpl=rust ;;
  nim) tpl=nim ;;
  zig) tpl=zig ;;
  ts | typescript) tpl=typescript ;;
  py | python) tpl=python ;;
  go) tpl=go ;;
  godot) if [ "$variant" = cs ]; then tpl=godot-cs; else tpl=godot; fi ;;
  *)
    echo "dev: unknown language '${1:-}' (supported: c odin rust nim zig typescript python go godot)" >&2
    exit 1
    ;;
esac

if [ "$variant" = cs ] && [ "$1" != godot ]; then
  echo "dev: -cs is only valid with 'godot'" >&2
  exit 1
fi

target=${2:-.}
mkdir -p "$target"
if [ -e "$target/flake.nix" ]; then
  echo "dev: $target already has a flake.nix — refusing to scaffold over it." >&2
  echo "  to enter its shell instead: cd there and run plain 'dev'" >&2
  exit 1
fi
cd "$target"

cp -r --no-preserve=mode "$DEVKIT_TEMPLATES/$tpl/." .

# JSON schemas power editor autocomplete only; hide them under .schemas/ so they
# don't clutter the project root (gitignored per each template's .gitignore).
[ -d schemas ] && mv schemas .schemas

# Local AI context (nim + odin + typescript projects). The real CLAUDE.md lives ONLY
# in ~/nix/private and is pulled in live when it has content; otherwise we write
# a stub to overwrite. Generated here rather than shipped in the template so the
# public repo tracks no CLAUDE.md. Scaffolded .claude/ is gitignored (see each
# template's .gitignore). Runs before __NAME__ substitution so placeholders fill.
case "$tpl" in
  nim | odin | typescript)
    mkdir -p .claude
    claude_src=${DEVKIT_CLAUDE_SRC:-$HOME/nix/private/home/dotfiles/claude/CLAUDE.md}
    if [ -s "$claude_src" ]; then
      cp -f "$claude_src" .claude/CLAUDE.md
    else
      cat > .claude/CLAUDE.md <<'STUB'
<!-- STUB — overwrite with the real project context (canonical: ~/nix/private). -->

You are the senior engineer who owns this project.
Make it fit to function:
- respect the user
- make it fast
- keep it simple
STUB
    fi
    ;;
esac

# Project name (binary/crate/module name): directory basename, sanitized to
# what cargo/pyproject accept. Substituted into the __NAME__ placeholders —
# first in file *contents*, then in file *names* (e.g. __NAME__.csproj).
# Generic so new templates don't need to touch a hardcoded file list.
name=$(basename "$PWD")
name=${name//[^a-zA-Z0-9_-]/-}
grep -rlZ --exclude-dir=.git __NAME__ . 2>/dev/null |
  while IFS= read -r -d "" f; do sed -i "s/__NAME__/$name/g" "$f"; done
find . -depth -name '*__NAME__*' -not -path './.git/*' |
  while IFS= read -r f; do mv "$f" "${f//__NAME__/$name}"; done

# Flakes only see files git knows about — an un-added flake.nix means
# "path ... does not exist" errors. Init + add before the first evaluation.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init -q
fi
git add -A .

direnv allow .
echo "dev: $tpl project '$name' ready — entering shell (first entry fetches the toolchain)..."
exec direnv exec . "$(pick_shell)"
