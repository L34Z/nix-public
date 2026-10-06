version     = "0.1.0"
author      = "z"
description = "A new Nim project"
license     = "MIT"

srcDir      = "src"
binDir      = "build"          # compiled binaries land in build/, gitignored
bin         = @["__NAME__"]

requires "nim >= 2.0.0"

task test, "Run the invariant + golden tests":
  exec "nim c -r --hints:off tests/test.nim"
