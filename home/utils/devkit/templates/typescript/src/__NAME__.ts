/**
 * __NAME__ — entry point and core module.
 *
 * Deliberate by design: write the concrete thing first, assert densely,
 * keep output deterministic. Extract abstractions only once three real
 * call sites exist, not before.
 */

// Owned, not imported: a two-line assert keeps this module dependency-free
// (no @types/node needed to typecheck) and still fires on every real run —
// a failed check throws with a file:line stack trace.
function assert(cond: boolean, msg: string): asserts cond {
  if (!cond) throw new Error(`assertion failed: ${msg}`);
}

export function greet(name: string): string {
  // Precondition: a non-empty name.
  assert(name.length > 0, "greet needs a name");
  const line = `hello from ${name}`;
  // Postcondition: a stable line strictly longer than the name.
  assert(line.length > name.length, "greeting must exceed the name");
  return line;
}

// `import.meta.main` is Node 24+; declare it locally until @types/node is added.
declare global {
  interface ImportMeta {
    readonly main?: boolean;
  }
}

// Run directly (`run`, or `tsx src/__NAME__.ts`); import-safe otherwise.
if (import.meta.main) {
  console.log(greet("__NAME__"));
}
