## Invariant + golden checks for __NAME__.
##
## nim.cfg puts src/ on the path, so the module imports by its bare name.
## Run via `run test` (nimble test) or `nim c -r tests/test.nim`.
import std/unittest
import __NAME__

suite "__NAME__":
  test "greet is deterministic":
    check greet("world") == "hello from world"

  test "greet is bounded by its input":
    check greet("z").len > "z".len
