# Handoff: Blueprints — baseline LED loop → `loops/bg_loop`

**Status:** blueprints side **done** —
[sofie-demo-blueprints#58](https://github.com/tojemoc/sofie-demo-blueprints/pull/58)
merged (`LED_BACKGROUND_LOOP_FILE` → `loops/bg_loop`).

**Sofie companion:** this megarepo PR renames smoke + part-type defaults to the
same production media names (`wipes/wipe`, `assets/intro_michal`, `HEADLINE*.mov`,
etc.).

## Layers

| Layer | Path | Notes |
|-------|------|--------|
| **Blueprints baseline** (prio 0) | `loops/bg_loop` on `CasparCGClipPlayer1` / LED 1-110 | Not a smoke RE piece |
| RE optional `bg-loop` piece (prio 1) | part-type default `loops/bg_loop` | Overrides baseline; smoke Intro has **no** `bg-loop` piece |
| Smoke fixture | no `bg-loop` media path | Loop comes from baseline only |

Disk: `loops/bg_loop.mov`.

**AMCP:** `PLAY 1-110 "loops/bg_loop"` (extension omitted).

## Consumer pin + checksums (same change)

Canonical pin and per-file SHA-256 map:
[`docs/integration/MEGAREPO-ASSETS-FETCH.md`](../MEGAREPO-ASSETS-FETCH.md).

Bump **in the same consumer commit**:

1. **unopus** — `PINNED_SOFIE_ASSETS_REF` + every `EXPECTED_SHA256[…]` entry
2. **sofie-demo-blueprints** — prepend that SHA to `REFS=(…)` in
   `scripts/fetch-sofie-megarepo-assets.sh` (and any wipe/default constants still
   on old names)

Do **not** leave consumer pins on mutable `main` / `cursor/…` refs.
