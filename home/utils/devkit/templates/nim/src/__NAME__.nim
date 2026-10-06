## __NAME__ — entry point and core module.
##
## Deliberate by design: write the concrete thing first, assert densely,
## keep output deterministic. Extract abstractions only once three real
## call sites exist — not before.

proc greet*(name: string): string =
  ## Precondition: a non-empty name.
  ## Postcondition: a stable line strictly longer than the name.
  assert name.len > 0, "greet needs a name"
  result = "hello from " & name
  assert result.len > name.len

when isMainModule:
  echo greet("__NAME__")
