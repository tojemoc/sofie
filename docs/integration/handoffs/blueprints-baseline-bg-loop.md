# Handoff: Blueprints — baseline LED loop → `loops/bg_loop`

**Sofie companion:** megarepo branch `cursor/smoke-media-rename-3ed7` updates
smoke + part-type defaults to production media names on the Win10 Caspar box.

## Where `360_loop` lives today

| Layer | Path | Notes |
|-------|------|--------|
| **Blueprints baseline** (prio 0) | hard-coded `loops/360_loop` on `CasparCGClipPlayer1` / LED 1-110 | **Not** a smoke RE piece — always on when a rundown is active |
| RE optional `bg-loop` piece (prio 1) | part-type default was `loops/360_loop` | Overrides baseline; smoke Intro has **no** `bg-loop` piece |
| Smoke fixture | no `bg-loop` media path | Loop comes from baseline only |

Caspar / disk today: `loops/bg_loop.mov` (no `360_loop.*`).

## Required blueprints change

In `sofie-demo-blueprints`, replace baseline clip name:

```text
loops/360_loop  →  loops/bg_loop
```

Search for `360_loop` in studio baseline / hypercomposed LED clip player setup
and tests. After change: `yarn test:blueprints` + `yarn dist`, upload bundle,
**Apply Configuration**.

**AMCP expectation:** idle/active LED shows `PLAY 1-110 "loops/bg_loop"` (extension
omitted), not `360_loop`.

## Already done in sofie megarepo

- `assets/sofie-rundown-editor-part-types.json` — optional `bg-loop` default → `loops/bg_loop`
- `assets/spravy-v3-smoke-rundown.json` — intro/wipes/clips renamed to on-disk names
- Docs / `assets/README.md` — media layout updated

Consumer pin/checksum bump (unopus / blueprints fetch scripts) after this merges.
