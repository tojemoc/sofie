# Handoff: Blueprints — Intro overlay on PGM (not LED)

**Branch already pushed:** `cursor/intro-pgm-layer-5448` on
`tojemoc/sofie-demo-blueprints` (open a PR to `develop` from that branch —
cloud agent could push but not create the PR).

**Sofie companion:** https://github.com/tojemoc/sofie/pull/17
(`assets/spravy-v3-smoke-rundown.json` + docs).

**Open PR:** https://github.com/tojemoc/sofie-demo-blueprints/pull/new/cursor/intro-pgm-layer-5448

---

## Problem (from Caspar / Softie)

1. **Intro plays on LED today.** `playLayer: 'effects'` maps to
   `CasparCGLayers.CasparCGEffectsPlayer` → **LED channel, layer 200**.
   Production rule: **Intro must never play on LED.** LED is reserved for
   **headlines + `loops/360_loop` only**.
2. **Intro must sit above everything on PGM** (camera, ILU when remapped, L3Ds,
   logo-bug, and story-block wipes). Wipe already uses PGM layer **200**
   (`CasparCGPgmEffectsPlayer`). Intro needs a **higher** PGM layer (**210**).

Smoke fixture (sofie megarepo `assets/spravy-v3-smoke-rundown.json`) now uses:

- piece type `intro`, `fileName: "wipes/360s_ZNELKA.mov"`, duration 12s
- **no** `bg-loop` piece on the Intro part (baseline loop still covers LED)
- **no** wipe on HEADLINE / Intro parts (story-block wipes unchanged)

## Code on `cursor/intro-pgm-layer-5448`

- `PgmChannelLayers.IntroOverlay = 210`
- `CasparCGPgmIntroPlayer = 'casparcg_intro_player_pgm'` → PGM channel
- `layeredVideoCasparLayer('effects')` → `CasparCGPgmIntroPlayer`
- Tests updated; `yarn test:blueprints` **57 passed** with
  `SOFIE_MEGAREPO_ASSETS` = sofie `assets/`

After sofie #17 merges, bump `scripts/fetch-sofie-megarepo-assets.sh` `REFS`.

## Verify

```bash
yarn test:blueprints && yarn lint
cd packages/blueprints && yarn dist
```

Upload bundle → Softie → **Apply config** → re-ingest smoke.

**AMCP on Intro take:** `PLAY <pgm>-210 "wipes/360s_ZNELKA" …`  
**Must not** play intro on LED (`PLAY 1-200 …`).

## Out of scope

Headline `404 PLAY FAILED` for `spravy/…/clips/headline1` — path is correct; the
file is missing from the Caspar media folder. See
`docs/integration/SPRAVY-V2-INTEGRATION.md`.
