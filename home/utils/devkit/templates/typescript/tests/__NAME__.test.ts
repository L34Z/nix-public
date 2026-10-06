/**
 * Invariant + golden checks for __NAME__.
 *
 * The `.js` specifier is the ESM/nodenext convention; tsx resolves it to the
 * `.ts` source. Run via `run test` (node --test through tsx) or:
 *   node --import tsx --test tests/__NAME__.test.ts
 */
import { test } from "node:test";
import { strict as assert } from "node:assert";
import { greet } from "../src/__NAME__.js";

test("greet is deterministic", () => {
  assert.equal(greet("world"), "hello from world");
});

test("greet is bounded by its input", () => {
  assert.ok(greet("z").length > "z".length);
});
