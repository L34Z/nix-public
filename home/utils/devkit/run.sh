# run — build/run/test/clean dispatcher for devkit projects.
# Wrapped by writeShellApplication (default.nix). Deliberately has no
# toolchain dependencies of its own: gcc/odin/cargo/nim/uv are expected on
# PATH from the project's dev shell (see `dev`).

usage() {
  cat <<'EOF'
run — build/run/test the project in the current directory

Usage:
  run [args...]   build + execute (args are passed to the program)
  run build       compile only
  run test        run the test suite
  run clean       remove build artifacts
  run edit        open the Godot editor (godot projects only)

Project type comes from the .dev marker (written by `dev`), with fallback
detection: Cargo.toml -> rust, *.odin -> odin, pyproject.toml -> python,
*.nim(ble) -> nim, *.zig -> zig, tsconfig.json -> typescript,
project.godot -> godot, *.c -> c23.
EOF
}

exists() { [ -e "$1" ]; } # exists ./*.c  -> true iff the glob matched

case "${1:-}" in
  -h | --help | help)
    usage
    exit 0
    ;;
esac

# Walk up to the project root (the dir holding the .dev marker) so `run`
# works from subdirectories too. No marker anywhere -> stay put, heuristics.
d=$PWD
while [ "$d" != / ]; do
  if [ -f "$d/.dev" ]; then
    cd "$d"
    break
  fi
  d=$(dirname "$d")
done

lang=""
bin=""
engine=""
if [ -f .dev ]; then
  lang=$(sed -n 's/^lang=//p' .dev)
  bin=$(sed -n 's/^bin=//p' .dev)
  engine=$(sed -n 's/^engine=//p' .dev)
fi
if [ -z "$lang" ]; then
  if [ -f Cargo.toml ]; then
    lang=rust
  elif exists ./*.odin; then
    lang=odin
  elif [ -f pyproject.toml ]; then
    lang=python
  elif exists ./*.nimble || exists ./*.nim; then
    lang=nim
  elif exists ./*.zig; then
    lang=zig
  elif [ -f tsconfig.json ]; then
    lang=typescript
  elif [ -f go.mod ]; then
    lang=go
  elif [ -f project.godot ]; then
    lang=godot
  elif exists ./*.c; then
    lang=c23
  fi
fi
# The Godot engine binary: `godot` (GDScript) or `godot-mono` (C#), recorded
# in .dev by the scaffolder. Default to plain godot when the marker is absent.
engine=${engine:-godot}
if [ -z "$lang" ]; then
  echo "run: can't tell what kind of project $PWD is" >&2
  echo "  (no .dev marker, Cargo.toml, pyproject.toml, or .c/.odin/.nim files)" >&2
  exit 1
fi
bin=${bin:-$(basename "$PWD")}

cmd=run
case "${1:-}" in
  build | test | clean | edit)
    cmd=$1
    shift
    ;;
esac
if [ "${1:-}" = -- ]; then shift; fi # `run -- <args>` also works

c_build() {
  mkdir -p build
  gcc -std=c23 -Wall -Wextra -g -o "build/$bin" ./*.c
}

nim_main() {
  # New layout keeps the entry at src/<bin>.nim; older single-file projects
  # kept main.nim (or a lone .nim) at the root. nim.cfg routes artifacts to
  # build/, so `nim c` here needs no git commit (unlike `nimble build`).
  if [ -f "src/$bin.nim" ]; then
    echo "src/$bin.nim"
  elif [ -f main.nim ]; then
    echo main.nim
  else
    set -- ./*.nim
    echo "$1"
  fi
}

ts_main() {
  # Entry lives at src/<bin>.ts; fall back to src/main.ts or the first src/*.ts.
  if [ -f "src/$bin.ts" ]; then
    echo "src/$bin.ts"
  elif [ -f src/main.ts ]; then
    echo src/main.ts
  else
    set -- ./src/*.ts
    echo "$1"
  fi
}

case "$lang/$cmd" in
  c23/run)
    c_build
    exec "./build/$bin" "$@"
    ;;
  c23/build)
    c_build
    echo "run: built build/$bin"
    ;;
  c23/test)
    if [ -f Makefile ] && grep -q '^test:' Makefile; then
      exec make test
    else
      echo "run: no tests (add a 'test:' target to a Makefile)" >&2
      exit 1
    fi
    ;;
  c23/clean) rm -rf build ;;

  odin/run)
    # Root package `main` (main.odin) imports the src/ library via a relative
    # import; `odin run .` compiles it and pulls src/ in. tests/ is a sibling
    # package and is not compiled here.
    if [ $# -gt 0 ]; then
      exec odin run . -- "$@"
    else
      exec odin run .
    fi
    ;;
  odin/build)
    mkdir -p build
    exec odin build . "-out:build/$bin"
    ;;
  odin/test)
    # Tests live in the tests/ package (core:testing) and import ../src. Point
    # the runner there; the root main package has no @(test) procs. Fall back
    # to `.` for older single-file odin projects that kept tests at the root.
    if [ -d tests ]; then
      exec odin test tests
    else
      exec odin test .
    fi
    ;;
  odin/clean) rm -rf build ;;

  rust/run) exec cargo run -- "$@" ;;
  rust/build) exec cargo build ;;
  rust/test) exec cargo test ;;
  rust/clean) exec cargo clean ;;

  nim/run) exec nim r --hints:off "$(nim_main)" "$@" ;;
  nim/build)
    mkdir -p build
    exec nim c --hints:off "-o:build/$bin" "$(nim_main)"
    ;;
  nim/test)
    # Compile the test entry directly — reads nim.cfg (src on path, artifacts
    # to build/) and needs no commit, unlike `nimble test`. Committed repos can
    # still `nimble test` for the .nimble task.
    if [ -f tests/test.nim ]; then
      exec nim c -r --hints:off tests/test.nim
    elif exists ./*.nimble; then
      exec nimble test
    else
      echo "run: no tests (add tests/test.nim or a .nimble test task)" >&2
      exit 1
    fi
    ;;
  nim/clean) rm -rf build nimcache ;;

  typescript/run) exec tsx "$(ts_main)" "$@" ;;
  typescript/build)
    # tsc typechecks src/ and emits JS + declarations to dist/ (see tsconfig).
    exec tsc -p tsconfig.json
    ;;
  typescript/test)
    # tsx is a drop-in `node` that preloads its own TS loader (resolving the
    # `.js` import specifiers to `.ts` source) and forwards node's --test runner.
    # Explicit file args bypass node's discovery patterns.
    set -- tests/*.test.ts
    if [ -e "$1" ]; then
      exec tsx --test "$@"
    else
      echo "run: no tests (add tests/*.test.ts)" >&2
      exit 1
    fi
    ;;
  typescript/clean) rm -rf dist node_modules ;;

  zig/run) exec zig run main.zig -- "$@" ;;
  zig/build)
    mkdir -p build
    exec zig build-exe main.zig -femit-bin="build/$bin"
    ;;
  zig/test) exec zig test main.zig ;;
  zig/clean) rm -rf build .zig-cache zig-out ;;

  python/run) exec uv run main.py "$@" ;;
  python/build) exec uv sync ;;
  python/test) exec uv run pytest "$@" ;;
  python/clean) rm -rf .venv __pycache__ ;;

  go/run) exec go run . "$@" ;;
  go/build)
    mkdir -p build
    exec go build -o "build/$bin" .
    ;;
  go/test) exec go test ./... ;;
  go/clean) rm -rf build ;;

  godot/run)
    if exists ./*.csproj; then
      exec "$engine" --path . --build-solutions
    else
      exec "$engine" --path .
    fi
    ;;
  godot/edit) exec "$engine" -e --path . ;;
  godot/build)
    if exists ./*.csproj; then
      exec dotnet build
    elif [ -f export_presets.cfg ]; then
      mkdir -p build
      exec "$engine" --headless --export-release \
        "$(sed -n 's/^name="\(.*\)"/\1/p' export_presets.cfg | head -1)" "build/$bin"
    else
      exec "$engine" --headless --import # import/validate assets
    fi
    ;;
  godot/test)
    if exists ./*.csproj; then
      exec dotnet test
    else
      exec gdlint . # gdtoolkit static check (no bundled test runner)
    fi
    ;;
  godot/clean) rm -rf build .godot bin obj ;;

  *)
    echo "run: unsupported language '$lang' in .dev marker" >&2
    exit 1
    ;;
esac
