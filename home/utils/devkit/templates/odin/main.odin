// __NAME__ — program entry point.
//
// The real logic lives in the src/ library package (package src), so it
// can be imported and tested in isolation. This file is the thin executable
// shell: it imports that package and calls into it. Mirrors Nim's
// `when isMainModule` block, split out because Odin's test runner needs the
// library to be main-free.
package main

import "core:fmt"
import lib "src"

main :: proc() {
	fmt.println(lib.greet("__NAME__"))
}
