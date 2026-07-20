# SPRÁVY / 360 sekúnd v2 — cross-repo integration log

Living document for agents working across the Sofie megarepo. Update this file when
demo-assets, blueprints, rundown-editor, or core integration status changes.

**Last updated:** 2026-07-20

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
| `tojemoc/sofie-demo-blueprints` | `develop` | v2 Caspar templates wired (`gfx/l3d-*`, headline ILU, logo-bug baseline) |
| `tojemoc/sofie-demo-blueprints` | `cursor/intro-overlay-bg-loop-4790` | **Open** — Intro overlay (EffectsPlayer 200) + controllable `bg-loop` piece; ILU smoke L3Ds |
| `tojemoc/unopus` (Rundown Editor) | `main` | Readiness, media picker, ILU/GFX presets |
| `tojemoc/unopus` (Rundown Editor) | `cursor/intro-overlay-bg-loop-4790` | **Open** — Intro / BG-loop part+piece types in toolbar manifests |
| `tojemoc/sofie-core` | — | No template-specific code; Playout Gateway is transport only |

---

## Intro overlay vs BG loop (2026-07-20)

Operators need **absolute control** over two different Caspar layers:

| Item | RE part / piece | Caspar layer | Role |
|------|-----------------|--------------|------|
| **Intro overlay** | Part `Intro` + piece `intro` | EffectsPlayer **200** | Alpha/video that plays **on top of** headlines, camera, L3Ds |
| **Background loop** | Piece `bg-loop` (optional on Intro; addable elsewhere) | ClipPlayer1 **110** | LED `loops/360_loop` behind camera — visible in Softie, not only baseline |

**Why GFX + video failed:** GFX parts require a graphic object. A video-only GFX part produced Softie Invalid **"No graphic object"**. Use the **Intro** toolbar button instead (or add an `intro` piece). Blueprints also recover video-only GFX parts as Intro overlays so existing smoke attempts keep working after bundle upload.

**Baseline:** `loops/360_loop` remains on ClipPlayer1 at priority 0 as a safety net. A `bg-loop` piece plays the same (or alternate) file at priority 1 with `OutOnRundownEnd` so operators can see/control it.

### Headline L3Ds (why only `l3d-syn` seemed to work)

- **Field mapping** is fine: RE `headline`/`subline` → Caspar `title`/`subtitle` (and templates also accept the RE names).
- **Bug:** `l3d-headline` was routed to Caspar **channel 2 (PGM)** while `l3d-syn` / `l3d-tema` / `l3d-mod` play on **channel 1 (LED)**. Watching LED made headline L3Ds look “missing”. Fixed: all L3Ds use LED lower-third (layer 121) until hypercomposed LED≠PGM is live.
- **demo-assets:** you need the v2 HTML set on Caspar (`gfx/l3d-tema.html`, `gfx/l3d-mod.html`, `gfx/l3d-headline.html`, `gfx/l3d-syn.html`, …). If only `l3d-syn` was copied, rebuild/deploy demo-assets: `yarn build` → copy `deploy/template-path` to Caspar `<template-path>`.

Smoke rundown restores operator intro clips (`introMichal.mov` on Intro + Intro 2nd attempt) and the custom ILU-1 L3D (`fico v bruseli?`).

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
reliability. Dev autoplay on `headline` uses `iluFile: 'clips/premiera.mp4'`. CEF maps
`.mp4`/`.mov` → `.webm` sibling at runtime; **both files must exist on ingest**.

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
- **RE readiness from Core (ADR 0001):** `peripheralDevice.packageManager.getContentStatusForRundown` +
  hybrid fs fallback in Rundown Editor — see `docs/adr/0001-re-readiness-from-core-package-manager.md`

---

## Rundown Editor (`tojemoc/unopus`)

- No template rendering; stores `pieceType` + payload only
- Import piece types from blueprints JSON after blueprints PR lands
- Built-in `l3d` manifest uses `name`+`title`; blueprints JSON uses `name`+`description` — **align on import**

### Merged (PR #32, `6e1f08a`)

- **Media readiness:** `GET /api/rundowns/:id/readiness` — evaluates `mediaPick` fields + WebM
  sibling for `iluFile`; polls every 10s via `RundownReadinessProvider`
- **Story sidebar:** columnar list (Status | Type | Story | Dur) with READY/NOT READY badges
- **Theming:** dark default + light option; semantic `--re-*` tokens; ThemeToggle in navbar/login
- **Rebrand:** Unopus (navbar breadcrumb)

Key files: `backend/src/background/mediaReadiness.ts`, `frontend/src/hooks/useRundownReadiness.ts`,
`RundownReadinessContext.tsx`, `sidebar/partRow.tsx`, `readinessBadge.tsx`, `theme/tokens.scss`

### Open branch: `cursor/quick-story-toolbar-cc55`

PR #32 left per-row `PartTypeButtons` with absolute positioning from the old layout, causing
complete overlap with the new story table. Fix moves a **single** quick-add strip (ILU, SYN, Cam,
VO, …) into the blue timing bar; `usePartInsertTarget` inserts after the open story (or at
segment end). Compare: https://github.com/tojemoc/unopus/compare/main...cursor/quick-story-toolbar-cc55

### ILU architecture (cross-repo)

- **Layer contract (LED channel):** Softie studio mapping id (= `CasparCGLayers` enum value) → Caspar layer. Parenthetical names are `LedChannelLayers` shorthand only.
  - `casparcg_clip_player1` (`CasparCGClipPlayer1`) → layer **110** (alias `ClipPlayer`) — LED background loop / VT fullscreen only; **never** apply MIXER FILL here
  - `casparcg_ilu_player` (`CasparCGIluPlayer`) → layer **115** (alias `IluPlayer`) — headline ILU MEDIA with FILL `0.08 / 0.15 / 0.62 / 0.73` (matches HTML `#ilu-slide`)
  - `casparcg_graphics_l3d` (`CasparCGGraphicsLowerThird`) → layer **121** (alias `GraphicsLowerThird` / “LowerThird”) — HTML graphics templates (`gfx/headline`, etc.)
- **Bug (2026-07-15):** FILL landed on `1-110` and scaled the bg loop. Fix branch:
  `tojemoc/sofie-demo-blueprints` → `cursor/ilu-fill-dedicated-layer-09c3`
  (compare: https://github.com/tojemoc/sofie-demo-blueprints/compare/develop...cursor/ilu-fill-dedicated-layer-09c3)
- **demo-assets:** preferred path is ILU `<video>` via WebM sibling in template; Caspar MEDIA+FILL is the fallback path (`iluFallback` / media-layer mode)
- **Operator:** after uploading the new blueprint bundle, **re-apply studio config** so Softie mapping `casparcg_ilu_player` (`CasparCGIluPlayer`) → Caspar layer **115** exists (ILU MEDIA + FILL `0.08 / 0.15 / 0.62 / 0.73`)

---

## Sofie Core / Playout Gateway

- No code changes for new template names
- Upload new blueprint bundle → apply studio config → verify Playout Gateway + Caspar subdevice
- Package Manager connects to Core at `coreHost:corePort` (look for `Core Connected!` / `studioId`)

### Package Manager misconfig (not a Core disconnect)

Symptoms that look like “PM cannot connect” but Core is up:

1. Nested Sofie `mediaPackages` object **does not persist in Settings** (edits vanish). Fixed by flattening to top-level fields on `cursor/pm-accessor-type-ingest-09c3`. After uploading that bundle + refresh: edit **Ingest media folder** (and **CasparCG media folder** if separate) as plain strings — do **not** use the nested “Media package containers” object. **Source of truth** is the shared media tree both Package Manager and Rundown Editor read: Softie studio `ingestMediaFolder` must match RE `INGEST_MEDIA_ROOT` / Settings → Ingest media root (clips live under `<root>/spravy/<rundownId>/clips/`). Examples: Windows `c:/casparcg/sofie-demo-media`; Docker-mounted `/app/ingest`. Then Apply Configuration. Until the new blueprints are uploaded, you cannot save that nested field in the UI.
2. `getAccessorStaticHandle: Accessor type is undefined` — ExpectedPackage source accessors lacked `type`; also on `cursor/pm-accessor-type-ingest-09c3`. After upload, re-apply studio config and re-ingest/reset the rundown so packages regenerate.

### Rundown Editor ingest scan vs Softie VID pieces (2026-07-15)

Symptoms:
- Softie fails regenerating VO/VT/SYN parts with a `video` (VID) piece when **File name** is empty — blueprints called `stripExtension(undefined)` and threw.
- RE mediaPick was **select-only**; with missing `spravy/<rundownId>/clips/` under `INGEST_MEDIA_ROOT` (often `/app/ingest` in Docker) you could not type a Caspar/PM-relative path. The warning showed only the relative folder next to “Ingest root: …” which looked nonsensical.

Fixes:
- Blueprints `cursor/vid-clip-props-harden-09c3`: require a non-empty path; Invalid “Video clip is missing file name”; treat duration as already ms after editor convert; content fallback to VT for video pieces.
- RE `cursor/media-picker-freetext-09c3`: free-text path (+ datalist/scan picker), show **absolute** scan folder, **Create scan folder** button.

Ops: mount media at the configured ingest root so both RE readiness and Softie Package Manager see `spravy/<id>/clips/*.mp4`, or type any path relative to that same media tree.

---

## Verification checklist

```text
[ ] yarn build in demo-assets; inspect deploy/template-path/gfx/*/
[ ] Copy zip to Caspar; AMCP: CG <ch> ADD 0 "<clipName>" 1
[ ] CG <ch> UPDATE 0 "<clipName>" "{\"headline\":\"test\"}"
[ ] Blueprints dist bundle uploaded to Core
[ ] Studio config applied; Softie mappings: casparcg_clip_player1 (CasparCGClipPlayer1)→110, casparcg_ilu_player (CasparCGIluPlayer)→115, casparcg_graphics_l3d (CasparCGGraphicsLowerThird)→121
[ ] Headline with ILU: AMCP shows MIXER FILL 0.08 / 0.15 / 0.62 / 0.73 on 1-115 (casparcg_ilu_player) only; loop keeps PLAY on 1-110 (casparcg_clip_player1)
[ ] RE rundown ingested; take fires correct template + data
[ ] logo-bug survives across parts until rundown end
```

---

## Agent handoffs

| Handoff | Path |
|---------|------|
| Blueprints v2 wiring | `docs/integration/handoffs/blueprints-v2-wiring.md` |
| This log | `docs/integration/SPRAVY-V2-INTEGRATION.md` |
