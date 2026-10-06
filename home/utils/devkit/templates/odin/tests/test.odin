// Invariant checks for __NAME__.
//
// Relative import pulls the core library from ../src; the test runner supplies
// its own entry point, so src/ stays main-free. Run via `run test`
// (odin test tests/) — see run.sh.
package tests

import "core:testing"
import lib "../src"

@(test)
greet_is_deterministic :: proc(t: ^testing.T) {
	got := lib.greet("world")
	defer delete(got)
	testing.expect_value(t, got, "hello from world")
}

@(test)
greet_is_bounded_by_its_input :: proc(t: ^testing.T) {
	got := lib.greet("z")
	defer delete(got)
	testing.expectf(t, len(got) > len("z"), "expected output longer than input, got %q", got)
}
