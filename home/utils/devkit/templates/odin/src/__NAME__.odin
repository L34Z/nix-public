// __NAME__ — core module.
//
// Deliberate by design: write the concrete thing first, assert densely,
// keep output deterministic. Extract abstractions only once three real
// call sites exist — not before. No main proc here: this package is a
// library, imported by ../main.odin (to run) and ../tests (to test).
//
// The package is named for its directory (src) — Odin package names must be
// identifiers, so they can't carry a project name with dashes in it.
package src

import "core:fmt"

// greet builds a stable line for `name`.
//   Precondition:  a non-empty name.
//   Postcondition: a deterministic string strictly longer than the name.
// The caller owns the returned string (context.allocator); free it or use a
// scratch/arena allocator at the call site.
greet :: proc(name: string) -> string {
	assert(len(name) > 0, "greet needs a name")
	out := fmt.aprintf("hello from %s", name)
	assert(len(out) > len(name))
	return out
}
