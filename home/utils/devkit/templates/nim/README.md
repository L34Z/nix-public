# __NAME__

A new Nim project.

## Develop

    dev              enter the nix dev shell (nim + nimble on PATH)
    run              build + run        -> build/__NAME__
    run build        compile only, into build/
    run test         nimble test — invariant + golden checks
    run clean        remove build/ and nimcache

## Layout

    src/__NAME__.nim   entry point / core module
    tests/test.nim     invariant + golden tests
    docs/              design notes
    build/             compiled artifacts (gitignored)
    .claude/           local AI context (gitignored stub; real one in ~/nix/private)
