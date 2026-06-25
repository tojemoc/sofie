# SPRÁVY / 360 sekúnd v2 — cross-repo integration log

Living document for agents working across the Sofie megarepo. Update this file when
demo-assets, blueprints, rundown-editor, or core integration status changes.

**Last updated:** 2026-06-24

---

## Goal

End-to-end demo: **Rundown Editor → Sofie Core → Playout Gateway → CasparCG** driving
v2 HTML templates from `tojemoc/sofie-demo-assets`.

**Near-term demo target (Friday):** one Caspar, single-channel LED stack, 3–4 templates,
imported H.264 clips. Full hypercomposed (LED≠PGM, wipes, all 10 templates) is **post-demo**.

---

## Repo status snapshot

| Repo | Branch / PR | Status |
|------|-------------|--------|
| `tojemoc/sofie-demo-assets` | `main` @ `85c706b` | **PR #3 merged** — 10 v2 HTML templates + `assemble-caspar.mjs` |
| `tojemoc/sofie-demo-assets` | [PR #4](https://github.com/tojemoc/sofie-demo-assets/pull/4) | **Open** — CI/CD, pre-releases (`sofie-demo-assets-pre-<sha>.zip`), Docker image |
| `tojemoc/sofie-demo-blueprints` | `main` | **Not wired** — still v1 piece types (`l3d`, `strap`, `ticker`, `head`, `fullscreen`) |
| `tojemoc/sofie-demo-blueprints` | `vmix-demo-blueprints` | vMix registry work; **no v2 Caspar template wiring** |
| `tojemoc/unopus` (Rundown Editor) | `main` | Built-in manifests; **no v2 piece types** |
| `tojemoc/sofie-core` | — | No template-specific code; Playout Gateway is transport only |

---

## Demo-assets contract (source of truth for blueprints)

### Build & deploy

```bash
cd demo-assets
yarn build   # → deploy/template-path + deploy/media-path
```

After PR #4 merges, each push to `main` produces a GitHub **pre-release** zip:

- `sofie-demo-template/` → Caspar `<template-path>`
- `sofie-demo-media/` → Caspar `<media-path>`

Pin the `pre-<sha>` tag you tested; do not assume `latest`.

### Caspar template paths

`scripts/assemble-caspar.mjs` lays out:

```text
<template-path>/
  js/ css/ img/ …          # shared webpack bundles
  gfx/
    headline/headline.html
    l3d-headline/l3d-headline.html
    l3d-mod/l3d-mod.html
    l3d-tema/l3d-tema.html
    l3d-syn/l3d-syn.html
    l3d-sjv/l3d-sjv.html
    l3d-sport/l3d-sport.html
    weather/weather.html
    outro/outro.html
    logo-bug/logo-bug.html
```

**Blueprint `clipName` / Caspar `TEMPLATE` name must be:** `gfx/<folder>` (e.g. `gfx/l3d-tema`).

### Caspar control API

All templates use `src/shared/caspar-bridge.js`:

- `window.play()` — intro animation (Promise)
- `window.stop()` — outro animation (Promise)
- `window.update(data)` — parse Sofie payload, optional stop/update/play

Sofie sends `TimelineContentCCGTemplate` with `templateType: 'html'`, `name`, `data`.
The bridge accepts JSON objects and XML-wrapped JSON from Caspar.

### Template catalogue (v2 spec)

| Spec | Folder | `clipName` | `update({ ... })` fields | Notes |
|------|--------|------------|--------------------------|-------|
| T01 | `headline` | `gfx/headline` | `iluFile`, `source` | ILU video block + source pill; **intended CH2 LED** |
| T04b | `l3d-headline` | `gfx/l3d-headline` | `title`, `subtitle` | Text bars; **intended CH1 PGM overlay** |
| T03 | `l3d-mod` | `gfx/l3d-mod` | `name` | Presenter MOD lower third |
| T04 | `l3d-tema` | `gfx/l3d-tema` | `headline` | Thematic doublebox bar |
| T05 | `l3d-syn` | `gfx/l3d-syn` | `name`, `role` | SYN name/role L3D |
| T06 | `l3d-sjv` | `gfx/l3d-sjv` | `headline` | SJV segment bar (static badge text in template) |
| T07 | `l3d-sport` | `gfx/l3d-sport` | `headline`, `source` | ŠPORT bar; JS timer logo↔counter at 100/200/300s |
| T08 | `weather` | `gfx/weather` | `cities[]` (`name`, `temp`, `condition`) | Full-frame; `condition` = icon key |
| T09 | `outro` | `gfx/outro` | _(none)_ | Hardcoded URL in template |
| T10 | `logo-bug` | `gfx/logo-bug` | _(none)_ | Persistent bug; needs `OutOnRundownEnd` lifespan |

### v2 design decisions (already implemented in templates)

- Frame 01 split: ILU on `headline` (CH2), text on `l3d-headline` (CH1) — **blueprints must coordinate**
- Bar backgrounds: solid `rgba(8, 16, 40, 0.82)` — no `backdrop-filter`
- SPORT counter: approach A (client-side timer on `play()`)
- Placeholders: `public/assets/logo-360.svg`, weather icons in `public/icons/`
- Old v1 templates (`l3d`, `wipe`, `ticker`, `strap`) remain in `src/` but are **not** in `vue.config.js`

### Media scaffold

```text
<media-path>/
  loops/     # e.g. 360_loop.mp4
  clips/     # ILU, VT, VO (e.g. clips/premiera.mp4)
  wipes/     # alpha wipe media (not wired in blueprints yet)
  assets/    # pip-frame.png, etc.
```

**Production media still missing** — demo must import/transcode clips. Use H.264 MP4 for
reliability. Dev autoplay on `headline` uses `iluFile: 'clips/premiera.mp4'`.

### Still open on demo-assets side (not blocking blueprint spec)

- Real media files and production logo SVG
- Weather map city positions vs `mapa.mov`
- Font files (Inter/InterBold) — currently Avenir/system fallback
- PR #4 merge + first verified pre-release zip on demo Caspar
- Optional: remove legacy v1 template sources

---

## Blueprints work required

See **`docs/integration/handoffs/blueprints-v2-wiring.md`** for the copy-paste agent prompt.

### Critical path files (`sofie-demo-blueprints`)

| File | Change |
|------|--------|
| `assets/sofie-rundown-editor-piece-types.json` | Add v2 piece types + payload schemas |
| `packages/blueprints/src/base/showstyle/sofie-editor-parsers/index.ts` | Extend `graphicTypes`; map RE payload → template `data` |
| `packages/blueprints/src/base/showstyle/helpers/graphics.ts` | Route `clipName` → Caspar layer; pass full `attributes` as `data` |
| `packages/blueprints/src/base/studio/layers.ts` | Possibly new layer enums |
| `packages/blueprints/src/base/studio/applyConfig/mappings/` | Channel/layer mappings |
| `packages/blueprints/src/base/rundown/baseline.ts` | `logo-bug` on rundown start |
| `packages/blueprints/src/common/definitions/objects.ts` | Extend `GraphicObjectAttributes` |

### Current v1 behaviour to replace/extend

- Parser: `clipName = 'gfx/' + piece.objectType` for `['strap','head','l3d','fullscreen','stepped-graphic']`
- Graphics: regex routes ticker/strap/fullscreen; **everything else → ch3 layer 111**
- Piece payloads: `name`/`description`/`text`/`location` — **not** v2 field names

### Friday MVP scope (recommended)

Wire **first**, test on Caspar **before** Sofie:

1. `gfx/logo-bug` — baseline, `CasparCGGraphicsLogo`, `OutOnRundownEnd`
2. `gfx/l3d-tema` — `headline` field
3. `gfx/l3d-mod` — `name` field
4. `gfx/l3d-headline` — `title`, `subtitle`

Defer: `weather`, `l3d-sport`, `headline`+ILU pair, hypercomposed multi-channel, wipes.

### Post-demo (PR2)

- `hypercomposed` studio preset per `demo-assets/docs/OUTPUT_TOPOLOGY.md`
- CH1 LED vs CH2 PGM mappings
- Wipe template + segment transitions
- Full 10-template coverage

---

## Rundown Editor

- No template rendering; stores `pieceType` + payload only
- Import piece types from blueprints JSON after blueprints PR lands
- Built-in `l3d` manifest uses `name`+`title`; blueprints JSON uses `name`+`description` — **align on import**
- Minimal RE changes for Friday; avoid UI rework

---

## Sofie Core / Playout Gateway

- No code changes for new template names
- Upload new blueprint bundle → apply studio config → verify Playout Gateway + Caspar subdevice
- `packageContainers.casparcg0.folderPath` hardcoded `c:/casparcg/media` — fix or symlink on Linux demo host

---

## Verification checklist

```text
[ ] yarn build in demo-assets; inspect deploy/template-path/gfx/*/
[ ] Copy zip to Caspar; AMCP: CG <ch> ADD 0 "<clipName>" 1
[ ] CG <ch> UPDATE 0 "<clipName>" "{\"headline\":\"test\"}"
[ ] Blueprints dist bundle uploaded to Core
[ ] Studio config applied; mappings show expected layers
[ ] RE rundown ingested; take fires correct template + data
[ ] logo-bug survives across parts until rundown end
```

---

## Agent handoffs

| Handoff | Path |
|---------|------|
| Blueprints v2 wiring | `docs/integration/handoffs/blueprints-v2-wiring.md` |
| This log | `docs/integration/SPRAVY-V2-INTEGRATION.md` |
