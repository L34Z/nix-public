# __NAME__

A new TypeScript project.

## Develop

    dev              enter the nix dev shell (node + tsc + tsx on PATH)
    run              run via tsx        -> src/__NAME__.ts
    run build        tsc typecheck + emit to dist/
    run test         node --test (through tsx) -> tests/
    run clean        remove dist/ and node_modules/

## Layout

    src/__NAME__.ts         entry point / core module
    tests/__NAME__.test.ts  invariant + golden tests
    tsconfig.json           compiler config (src -> dist)
    docs/                   design notes
    dist/                   compiled artifacts (gitignored)
    .claude/                local AI context (gitignored stub; real one in ~/nix/private)
