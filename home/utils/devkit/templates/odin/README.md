# __NAME__

A new Odin project.

## Develop

    dev              enter the nix dev shell (odin + ols + gdb on PATH)
    run              build + run        -> build/__NAME__
    run build        compile only, into build/
    run test         odin test — invariant checks in tests/
    run clean        remove build/

## Layout

    main.odin          program entry point (package main; imports src/)
    src/__NAME__.odin  core module / library (package src)
    tests/test.odin    invariant tests (core:testing)
    docs/              design notes
    ols.json           language-server config (checker targets)
    odinfmt.json       formatter config (tabs, width 100)
    .schemas/          vendored JSON schemas for the two configs (autocomplete only; gitignored)
    build/             compiled artifacts (gitignored)
    .claude/           local AI context (gitignored stub; real one in ~/nix/private)
