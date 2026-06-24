# Handoff: Blueprints agent — wire v2 demo-assets into Sofie

**Copy everything below the line into a new Cursor agent session running in
`tojemoc/sofie-demo-blueprints`.**

---

## Your mission

Implement blueprint integration for the **360 sekúnd / SPRÁVY v2 CasparCG HTML templates**
already merged in `tojemoc/sofie-demo-assets` (PR #3 on `main`). Demo-assets builds and
packages templates; **you own everything that turns Rundown Editor pieces into Caspar
`TEMPLATE` commands.**

**Demo deadline:** Friday — scope to an MVP first (see below), open a PR, run
`yarn test:blueprints` and `yarn lint`.

**Cross-repo context:** the Sofie megarepo (`tojemoc/sofie`) tracks integration status in
`docs/integration/SPRAVY-V2-INTEGRATION.md`. Update that file (or ask the megarepo agent
to update it) when your PR merges.

---

## What demo-assets already delivers (do not reimplement)

Repo: https://github.com/tojemoc/sofie-demo-assets (`main` @ PR #3 merged 2026-06-24)

- **10 HTML templates** with shared `src/shared/caspar-bridge.js`, `tokens.css`, GSAP animations
- **Build:** `yarn build` → `deploy/template-path` + `deploy/media-path`
- **Caspar layout** (`scripts/assemble-caspar.mjs`):

```text
<template-path>/gfx/<name>/<name>.html
```

- **PR #4 (may merge soon):** GitHub pre-release zip per `main` push:
  `sofie-demo-template/` + `sofie-demo-media/`

### Template catalogue — use these exact `clipName` values

| Piece type ID (suggested) | Caspar `TEMPLATE` name (`clipName`) | Payload fields for `data` |
|---------------------------|-------------------------------------|---------------------------|
| `headline` | `gfx/headline` | `iluFile` (string, media path), `source` (string) |
| `l3d-headline` | `gfx/l3d-headline` | `title`, `subtitle` |
| `l3d-mod` | `gfx/l3d-mod` | `name` |
| `l3d-tema` | `gfx/l3d-tema` | `headline` |
| `l3d-syn` | `gfx/l3d-syn` | `name`, `role` |
| `l3d-sjv` | `gfx/l3d-sjv` | `headline` |
| `l3d-sport` | `gfx/l3d-sport` | `headline`, `source` |
| `weather` | `gfx/weather` | `cities` (array of `{ name, temp, condition }`) |
| `outro` | `gfx/outro` | _(empty — play/stop only)_ |
| `logo-bug` | `gfx/logo-bug` | _(empty — play/stop only)_ |

Templates expose `window.play()`, `window.stop()`, `window.update(data)`. Sofie already
emits `TimelineContentCCGTemplate` with `templateType: 'html'`, `name`, `data` — your job
is to set `name` and populate `data` correctly.

### What demo-assets does NOT do

- No Sofie piece types, parsers, or layer mappings
- No hypercomposed studio preset (planned megarepo PR2)
- No real production media (clips are imported manually; dev uses `clips/premiera.mp4`)
- v1 types (`gfx/l3d`, `gfx/strap`, `gfx/ticker`, `gfx/head`) are **removed from build** — stop referencing them for v2

---

## What you must change in blueprints

### 1. `assets/sofie-rundown-editor-piece-types.json`

Add piece type definitions for v2 templates with payload fields matching the table above.
Editors import this JSON into Rundown Editor.

### 2. `packages/blueprints/src/base/showstyle/sofie-editor-parsers/index.ts`

Today:

```typescript
const graphicTypes = ['strap', 'head', 'l3d', 'fullscreen', 'stepped-graphic']
// ...
piece.clipName = 'gfx/' + piece.objectType
```

Extend `graphicTypes` with all v2 IDs. Map `piece.attributes` from RE payload to the
template `data` keys (replace legacy `field0`/`field1` mapping for v2 types). Pass attributes
through unchanged where field names already match (`headline`, `name`, `title`, etc.).

### 3. `packages/blueprints/src/base/showstyle/helpers/graphics.ts`

Today: regex routes ticker/strap/fullscreen; **default → `CasparCGGraphicsLowerThird` (ch3/111)**.

You must:

- Route `logo-bug` → `CasparCGGraphicsLogo` (ch3/113) with `PieceLifespan.OutOnRundownEnd`
- Route fullscreen-style templates (`weather`, `outro`) appropriately
- Ensure `content.data` spreads **all** `object.attributes` (v2 fields), not only
  `name`/`description`/`location`/`text` in `templateData`
- For Friday MVP: single-channel is OK — all GFX on existing lower-third/logo layers

### 4. Layer mappings

Files under `packages/blueprints/src/base/studio/applyConfig/mappings/`.

Current hybrid demo uses ch3 for graphics. **Friday:** keep single-channel; **post-demo:**
map `headline` → LED channel, `l3d-headline` → PGM channel per
`demo-assets/docs/OUTPUT_TOPOLOGY.md`.

### 5. Baseline / rundown start

`logo-bug` should appear at rundown start and persist (`OutOnRundownEnd`). Wire in
`rundown/baseline.ts` or equivalent — layer 113 exists but is unused today.

### 6. `packages/blueprints/src/common/definitions/objects.ts`

Extend `GraphicObjectAttributes` for v2 fields (`headline`, `title`, `subtitle`, `role`,
`iluFile`, `source`, `cities`, …).

### 7. Tests

Add/adjust blueprint unit tests and smoke rundown JSON for at least MVP types.

---

## Friday MVP scope (do this first)

1. `gfx/logo-bug` — baseline
2. `gfx/l3d-tema` — `headline`
3. `gfx/l3d-mod` — `name`
4. `gfx/l3d-headline` — `title`, `subtitle`

**Defer:** `weather`, `l3d-sport`, `headline`+ILU, hypercomposed preset, wipes, v1 types.

---

## Verification steps

1. `cd packages/blueprints && yarn dist` — produce bundle
2. Caspar manual test (before Sofie):

```text
CG 1 ADD 0 "gfx/l3d-tema" 1
CG 1 UPDATE 0 "gfx/l3d-tema" "{\"headline\":\"Test headline\"}"
```

3. Upload bundle to Sofie Core; apply studio config
4. Ingest a test rundown from Rundown Editor with new piece types; take on air

---

## Reference: current v1 wiring (to replace)

| v1 piece | clipName | Layer |
|----------|----------|-------|
| l3d | gfx/l3d | ch3/111 |
| strap | gfx/strap | ch3/112 |
| ticker | gfx/ticker | ch3/110 |
| head | gfx/head | ch3/111 |
| fullscreen | gfx/fullscreen | ch1/110 + VM cut |

---

## Out of scope for your PR

- `tojemoc/sofie-core` code changes
- `tojemoc/unopus` UI work (only export updated `piece-types.json`)
- `tojemoc/sofie-demo-assets` template HTML changes
- Full hypercomposed PR2 (separate follow-up)

---

## Deliverables

1. PR against `tojemoc/sofie-demo-blueprints` `main` (or `vmix-demo-blueprints` if that is
   the active Správy branch — confirm with user)
2. Updated `assets/sofie-rundown-editor-piece-types.json`
3. Brief PR description listing MVP templates wired + test steps
4. Note the exact `pre-<sha>` demo-assets zip used for manual Caspar verification
