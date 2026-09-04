# SPRÁVY / 360 sekúnd v2 — cross-repo integration log

Living document for agents working across the Sofie megarepo. Update this file when
demo-assets, blueprints, rundown-editor, or core integration status changes.

**Last updated:** 2026-08-31

---

## Goal

End-to-end demo: **Rundown Editor → Sofie Core → Playout Gateway → CasparCG** driving
v2 HTML templates from `tojemoc/sofie-demo-assets`.

**Near-term demo target (August 14, 2026):** one Caspar, single-channel LED stack, 3–4 templates,
imported H.264 clips. Full hypercomposed (LED≠PGM, wipes, all 10 templates) is **post-demo**.

**LED vs PGM (canonical — planned / pending):** [`OUTPUT_TOPOLOGY.md`](./OUTPUT_TOPOLOGY.md) —
target is LED = headline ILU + `bg_loop` only; L3Ds / intro / wipe / camera / logo-bug on
**Caspar channel 2**. Two-channel CH1/CH2 mapping is **not yet deployed**; the August 14 demo
remains single-channel. DoubleBox compose detail:
[`DOUBLEBOX-PGM.md`](./DOUBLEBOX-PGM.md).

---

## Repo status snapshot

| Repo | Branch / PR | Status |
|------|-------------|--------|
| `tojemoc/sofie-demo-assets` | `cursor/cleanup-v2-graphics-bc1a` / [PR #34](https://github.com/tojemoc/sofie-demo-assets/pull/34) | **v2-only templates** — legacy v1 stubs removed; Bauplan/Diform fonts; see [`demo-assets/docs/BLUEPRINTS_HANDOFF.md`](https://github.com/tojemoc/sofie-demo-assets/blob/main/docs/BLUEPRINTS_HANDOFF.md) |
| `tojemoc/sofie-demo-assets` | [PR #4](https://github.com/tojemoc/sofie-demo-assets/pull/4) | CI/CD, pre-releases (`sofie-demo-assets-pre-<sha>.zip`), Docker `ghcr.io/tojemoc/sofie-demo-assets` |
| `tojemoc/sofie-demo-blueprints` | `cursor/spravy-v2-caspar-wire-d6ac` | v2 Caspar clipNames wired; v1 routes removed; `gfx/source` on PGM L121 |
| `tojemoc/unopus` (Rundown Editor) | `cursor/kubo-unopus-rundown-ux-1ddf` | Full-width status rows, compact rundown, GFX preview stubs, presence lock chips, SYN trim timing |
| `tojemoc/sofie-core` | `cursor/kubo-take-previous-pause-clock-1ddf` | **Take Previous**, **Pause/Resume clock** (časovka freeze + stop VT/VO) |

---

## Intro overlay vs BG loop (2026-07-22)

Operators need **absolute control** over two different Caspar layers / channels:

| Item | RE part / piece | Caspar target | Role |
|------|-----------------|---------------|------|
| **Intro overlay** | Part `Intro` + piece `intro` | **PGM** IntroOverlay **210** (above wipe 200) | Full-frame znelka / alpha — **never on LED** |
| **Background loop** | Piece `bg-loop` (optional) + baseline | LED ClipPlayer1 **110** | LED `loops/bg_loop` |

**LED allow-list (channel 1):** **headline ILU** + **`bg_loop` only**.
`l3d-mod` (Presenter MOD) and other L3Ds are **PGM** — see Headline L3Ds below.
**Intro / znelka must not appear on LED.** See handoff
[`handoffs/blueprints-intro-pgm-layer.md`](./handoffs/blueprints-intro-pgm-layer.md)
(current blueprints still map `playLayer: 'effects'` → LED layer 200 — remapping required).

**Why GFX + video failed:** GFX parts require a graphic object. A video-only GFX part produced Sofie Invalid **"No graphic object"**. Use the **Intro** toolbar button instead (or add an `intro` piece). Blueprints also recover video-only GFX parts as Intro overlays so existing smoke attempts keep working after bundle upload.

**Baseline:** `loops/bg_loop` remains on ClipPlayer1 at priority 0 as a safety net. A `bg-loop` piece plays the same (or alternate) file at priority 1 with `OutOnRundownEnd` so operators can see/control it. Smoke Intro no longer carries an explicit `bg-loop` piece. Blueprints still hard-code the baseline basename — see [`handoffs/blueprints-baseline-bg-loop.md`](./handoffs/blueprints-baseline-bg-loop.md).

### Headline ILU `404 PLAY FAILED`

Caspar log pattern:

```text
CG 1-121 ADD 1 "gfx/headline-fallback" …   → 202 CG OK
PLAY 1-115 "clips/headline1" … → 404 PLAY FAILED
```

Path convention is correct (`clips/<name>` without extension for PLAY).
**404 means the file is not on the Caspar media disk** under
`<casparcgMediaFolder>/clips/headline1.mp4` (Package Manager
copy / ingest). Place or ingest the MP4s; Sofie cannot invent media. CG OK only means
the HTML template loaded — the companion ILU PLAY still needs the file.

### Headline L3Ds (LED vs PGM)

- **Field mapping** is fine: RE `headline`/`subline` → Caspar `title`/`subtitle` (templates also accept the RE names). ILU presets include `l3d-headline`; re-upload blueprints and re-ingest if Sofie still omits them.
- **`l3d-headline` / `l3d-tema` / `l3d-syn` / `l3d-mod` are on PGM (Caspar channel 2)** by design. LED allow-list is **headline ILU + `bg_loop` only** — if you only watch the LED consumer, those L3Ds look “missing”.
- **Sofie source layers:** LED headline ILU stays on `Lower Third`. PGM L3Ds use `PGM L3D` (`lower_third_pgm`) — a **separate source layer** on the **GFX** output track (PGM output is `isFlattened` with Camera). Caspar still plays them on channel 2. They must not share one Sofie source layer — Core keeps only one WithinPart piece per layer at the same start (otherwise HEADLINE3 can lose `PLAY 1-115` while only `CG 2-121 gfx/l3d-headline` fires).
- **How to look at PGM:** open the Caspar **channel 2** consumer (screen / NDI / SDI for ch2), not channel 1. Studio mapping id `casparcg_graphics_pgm_l3d` → ch2 layer 121. Confirm with AMCP e.g. `INFO 2` or a second Screen consumer bound to `<channel-index>2</channel-index>`.
- **demo-assets:** v2 HTML must exist on Caspar (`gfx/l3d-headline.html`, etc.). Rebuild with `yarn build` and copy `deploy/template-path` if needed.
- **`gfx/headline-fallback` (LED 1-121) is chrome only** — transparent ILU window + optional `source` pill. It does **not** render the ILU `text` field; headline copy on PGM comes from **`gfx/l3d-headline` on channel 2 layer 121**. If fallback frame shows but words do not, check PGM ch2 (not LED) for `gfx/l3d-headline`, and redeploy templates after `demo-assets` fixes.
- **`gfx/l3d-headline` invisible while `l3d-tema` / `l3d-mod` work:** fixed in `demo-assets` — `play()` must set bar transform to `x: 0` before `gsap.from` (otherwise bars stay off-screen at `-1200px` even when AMCP returns `202 CG OK`). Rebuild `yarn build`, copy `deploy/template-path/gfx/l3d-headline/` to Caspar, restart or `CG … STOP` + Take again.
- **Piece Duration → Part Duration in RE:** backend `syncStoryDurationsForPart` may set
  unset **part** duration from the longest child On air (or trimmed source). It does
  **not** force piece On air from ffprobe, and does **not** auto-fill empty L3D On air
  from the part (empty L3D = hold until Take). Cleared durations persist via JSON
  merge-patch `null`. See unopus branch `cursor/fix-duration-probe-and-on-air-5c12`.
- **Timing (not AUTO):** three durations must not be conflated (see [`RE-READINESS-AND-PLAYOUT-UX.md`](./RE-READINESS-AND-PLAYOUT-UX.md)):
  - **Part Duration** (seconds) — story-level expected length in the Rundown Editor.
  - **Piece On air** (seconds) — enable length for Sofie timeline; **empty L3D On air**
    means hold until Take (not inherited from part). Media picker may seed On air from
    ffprobe; editorial overrides stick.
  - **Sofie `expectedDuration`** (milliseconds after ingest conversion) — the on-air timeline enable length Sofie uses at playout.
  - **`payload.sourceDuration`** (milliseconds) — separate from on-air timing; maps to VT/VO `content.sourceDuration` (media clip length from ffprobe using format/stream + frame-count heuristics, not the Dur column).
  Sofie **AUTO** only appears when blueprints set `autoNext` (VT / Intro / non-ILU GFX). ILU parts (with or without camera) do **not** autoNext — leave Start at `0` so they begin on Take.
- **RE Ready/NR, DUR, wipe timing, piece order:** planning notes in
  [`RE-READINESS-AND-PLAYOUT-UX.md`](./RE-READINESS-AND-PLAYOUT-UX.md) (ADR 0001 for Core PM readiness).

## Muster smoke rundown (2026-07-22)

`assets/spravy-v3-smoke-rundown.json` (sofie megarepo `assets/`) mirrors the
production muster spine:

| Segment | Parts |
|---------|--------|
| HEADLINES | HEADLINE1–3 (ILU + L3D horný/dolný + cam A); **no** wipe pieces |
| INTRO | Intro overlay (`assets/intro_michal`, disk `….mov`) on **PGM**; Mod L3D Gabriela Kajtárová (**PGM**) + logo-bug (PGM); **no** bg-loop piece, **no** wipe |
| Téma 1–4 | Téma GFX + ILU/SYN patterns (cams A/P/M); named ILUs use PGM `l3d-headline` |
| SPRÁVY JEDNOU VETOU | `l3d-sjv` + 4× ILU with citácia |
| ŠPORT | `l3d-sport` + 3× ILU with citácia |
| POČASIE | `weather` fullscreen |
| ZÁVER + AVIZO | ILU avízo, SYN, closing ILU, `outro` |

Clip paths are placeholders under `clips/`. Camera letters:
**A→1**, **P→2**, **M→3**.

Wipes: piece type `wipe`, file `wipes/wipe` (or labelled `wipe_sjv` / `wipe_sport` / `wipe_pocasie`), play on **PGM** (see DOUBLEBOX-PGM.md).
Smoke rundown includes story-block wipe pieces with a `transition` label
(`ILU TO SYN`, `Double Box`, …) — not on HEADLINES / Intro.

## Kubo studio tasks (2026-08-25)

Operator list items assigned to Kubo, landed as sibling-repo PRs (this megarepo tracks docs + piece-type fields):

| Area | Change |
|------|--------|
| Grafika | v2 “novú” Caspar templates already imported into blueprints; Intro plays as **video** on `pgm_intro` (UI label Intro, not Titles) |
| Grafika | Wipes set `ignoreMediaObjectStatus` so missing Package Manager objects do not block PLAY |
| Playout | SYN/VO/VT `trimIn` / `trimOut` (seconds) + `volume` on video pieces; on-air duration is source length minus trims |
| Zvuk | Clip mixer volume; Koliska bed starts at 1.0 for 4s then ducks to 0.45 |
| Flow | Sofie **Pause clock** / **Resume clock** / **Take Previous** — časovka freezes at `timings.pausedAt`; pause also stops VT/VO clips |
| Unopus | Full-width story/piece rows colored by ready/NR; compact headings; GFX preview stubs; row lock chips when another user has the row focused |

Video piece payload fields (megarepo `assets/sofie-rundown-editor-piece-types.json`): `trimIn`, `trimOut`, `volume`.

**Out of scope (Ondro / studio):** HTML graphic production, casomierka pips, wall broadcast, FFMPEG record, podcast mix minus music.

---

## Demo-assets contract (source of truth for blueprints)

**Canonical handoff:** [`tojemoc/sofie-demo-assets` → `docs/BLUEPRINTS_HANDOFF.md`](https://github.com/tojemoc/sofie-demo-assets/blob/main/docs/BLUEPRINTS_HANDOFF.md) (branch `cursor/cleanup-v2-graphics-bc1a` or later `main` after PR #34 merge).

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
  js/ css/ img/ fonts/ …     # shared webpack bundles + brand fonts
  gfx/
    headline/headline.html
    headline-fallback/headline-fallback.html
    source/source.html
    l3d-headline/l3d-headline.html
    l3d-predstavovak/l3d-predstavovak.html
    l3d-mod/l3d-mod.html
    l3d-tema/l3d-tema.html
    l3d-syn/l3d-syn.html
    l3d-sjv/l3d-sjv.html
    l3d-sport/l3d-sport.html
    l3d-odporucanie/l3d-odporucanie.html
    weather/weather.html
    outro/outro.html
    logo-bug/logo-bug.html
```

**Removed — do not reference:** `gfx/l3d`, `gfx/mod-l3d`, `gfx/head-spravy`, `gfx/ticker`, `gfx/strap`, `gfx/wipe`, `gfx/head`, `gfx/fullscreen`.

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
| T01 | `headline` | `gfx/headline` | `iluFile`, `source` | ILU MEDIA on **LED ch1 L115** (not HTML video) |
| T01b | `headline-fallback` | `gfx/headline-fallback` | `source` | ILU chrome overlay; **LED ch1 L121** only |
| T01c | `source` | `gfx/source` | `source` | Standalone source pill; **PGM ch2 L121** |
| T04b | `l3d-headline` | `gfx/l3d-headline` | `title`, `subtitle` | RE aliases `headline`/`subline`; **PGM ch2 L121** |
| T03a | `l3d-predstavovak` | `gfx/l3d-predstavovak` | `name`, `title` | Guest/topic nameplate; **PGM ch2** |
| T03 | `l3d-mod` | `gfx/l3d-mod` | `name`, `title` | Presenter MOD (Intro); **PGM ch2** |
| T04 | `l3d-tema` | `gfx/l3d-tema` | `headline` | Thematic doublebox bar; **PGM ch2** |
| T05 | `l3d-syn` | `gfx/l3d-syn` | `name`, `role` | SYN name/role L3D; **PGM ch2** |
| T06 | `l3d-sjv` | `gfx/l3d-sjv` | `kicker`, `headline` | SJV segment bar; **PGM ch2** |
| T06b | `l3d-odporucanie` | `gfx/l3d-odporucanie` | `headline` | Avízo / CTA (no kicker); **PGM ch2** |
| T07 | `l3d-sport` | `gfx/l3d-sport` | `kicker` *(default `ŠPORT`)*, `headline` | ŠPORT bar; **PGM ch2** |
| T08 | `weather` | `gfx/weather` | `cities[]` (`name`, `temp`, `condition`) | Full-frame on **PGM**; `condition` = icon key |
| T09 | `outro` | `gfx/outro` | _(none)_ | Hardcoded URL; **PGM** |
| T10 | `logo-bug` | `gfx/logo-bug` | _(none)_ | Persistent bug on **PGM logo layer**; `OutOnRundownEnd`; alias `gfx/logo-bug-kubo` |

### v2 design decisions (already implemented in templates)

- Frame 01 split: ILU on `headline` (**LED ch1**), text on `l3d-headline` (**PGM ch2**) — see [`OUTPUT_TOPOLOGY.md`](./OUTPUT_TOPOLOGY.md)
- Bar backgrounds: solid `rgba(8, 16, 40, 0.82)` — no `backdrop-filter`
- SPORT counter: approach A (client-side timer on `play()`)
- Placeholders: `public/assets/logo-360.svg`, weather icons in `public/icons/`
- Old v1 templates (`l3d`, `mod-l3d`, `head-spravy`, `ticker`, `strap`, `wipe`, `head`, `fullscreen`) **removed from demo-assets build** (PR #34)

### Media scaffold

```text
<media-path>/
  loops/     # e.g. bg_loop.mov — bg-loop / baseline LED loop
  clips/     # ILU, VT, VO (e.g. clips/premiera.mp4)
  wipes/     # alpha wipe media (piece type `wipe` → PGM layer 200)
  assets/    # pip-frame.png, etc.
```

**Production media still missing** — demo must import/transcode clips. Use H.264 MP4 for
reliability. Dev autoplay on `headline` uses `iluFile: 'clips/premiera.mp4'`. ILU plays via Caspar MEDIA (not CEF `<video>`); place the `.mp4`/`.mov` master on the Caspar media disk — **no WebM sibling required**.

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
| **Megarepo** `assets/sofie-rundown-editor-piece-types.json` | Add v2 piece types + payload schemas (canonical) |
| `packages/blueprints/src/base/showstyle/sofie-editor-parsers/index.ts` | Extend `graphicTypes`; map RE payload → template `data` |
| `packages/blueprints/src/base/showstyle/helpers/graphics.ts` | Route `clipName` → Caspar layer; pass full `attributes` as `data` |
| `packages/blueprints/src/base/studio/layers.ts` | Possibly new layer enums |
| `packages/blueprints/src/base/studio/applyConfig/mappings/` | Channel/layer mappings |
| `packages/blueprints/src/base/rundown/baseline.ts` | `logo-bug` on rundown start |
| `packages/blueprints/src/common/definitions/objects.ts` | Extend `GraphicObjectAttributes` |

### Current v2 behaviour (2026-08-31)

- Parser: RE graphic piece types → `clipName = 'gfx/' + pieceType` (see `rundownEditorTypes.ts`)
- Graphics: PGM L3D set routes to `casparcg_graphics_pgm_l3d` (ch2 L121); LED ILU uses `headline-fallback` on ch1 L121
- v1 spreadsheet remaps (`gfx/l3d`, `gfx/strap`, …) **removed**
- Piece payloads: canonical field names per table above; blueprints `getTemplateAttributes` maps RE aliases

### Deploy assets to Caspar

After `yarn build` in demo-assets (or CI pre-release zip / Docker image):

1. Copy `deploy/template-path/*` → Caspar `<template-path>`
2. Copy `deploy/media-path/*` → Caspar `<media-path>`
3. Upload new blueprint bundle → **Apply studio config** in Sofie Core WebUI

### Verification AMCP (Caspar Client)

```text
CG 2-121 ADD 1 "gfx/l3d-tema" "{\"headline\":\"Test\"}"
CG 2-121 ADD 1 "gfx/l3d-predstavovak" "{\"name\":\"Peter Pellegrini\",\"title\":\"Prezident SR\"}"
CG 2-121 ADD 1 "gfx/l3d-mod" "{\"name\":\"Gabriela Kajtárová\",\"title\":\"moderátorka\"}"
CG 2-121 ADD 1 "gfx/source" "{\"source\":\"TASR\"}"
CG 2-123 ADD 1 "gfx/logo-bug"
PLAY 1-115 "clips/headline1"
CG 1-121 ADD 1 "gfx/headline-fallback" "{\"source\":\"TASR\"}"
```

### Post-demo (PR2)

- `hypercomposed` studio preset per [`OUTPUT_TOPOLOGY.md`](./OUTPUT_TOPOLOGY.md)
- CH1 LED vs CH2 PGM mappings
- Wipe template + segment transitions
- Full 10-template coverage
- **RE readiness from Core (ADR 0001):** `peripheralDevice.packageManager.getContentStatusForRundown` +
  hybrid fs fallback in Rundown Editor — see `docs/adr/0001-re-readiness-from-core-package-manager.md`

---

## Rundown Editor (`tojemoc/unopus`)

- No template rendering; stores `pieceType` + payload only
- Type manifests load from megarepo `assets/` (not from this repo)
- Standalone CI/Docker fetch pins sofie commit SHA + SHA-256 checksums — see
  [`MEGAREPO-ASSETS-FETCH.md`](MEGAREPO-ASSETS-FETCH.md) / [unopus #45](https://github.com/tojemoc/unopus/pull/45)
- Built-in `l3d` manifest uses `name`+`title`; megarepo JSON uses `name`+`description` — **align on import**

### Merged (PR #32, `6e1f08a`)

- **Media readiness:** `GET /api/rundowns/:id/readiness` — evaluates `mediaPick` fields (no WebM
  sibling); polls every 10s via `RundownReadinessProvider`. Media picker probes clip duration via
  ffprobe and pulls it into piece/part duration on save.
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

- **Layer contract (LED channel):** Sofie studio mapping id (= `CasparCGLayers` enum value) → Caspar layer. Parenthetical names are `LedChannelLayers` shorthand only.
  - `casparcg_clip_player1` (`CasparCGClipPlayer1`) → layer **110** (alias `ClipPlayer`) — LED background loop / VT fullscreen only; **never** apply MIXER FILL here
  - `casparcg_ilu_player` (`CasparCGIluPlayer`) → layer **115** (alias `IluPlayer`) — headline ILU MEDIA with FILL `0.08 / 0.15 / 0.62 / 0.73` (matches HTML `#ilu-slide`)
  - `casparcg_graphics_l3d` (`CasparCGGraphicsLowerThird`) → layer **121** (alias `GraphicsLowerThird` / “LowerThird”) — HTML graphics templates (`gfx/headline`, etc.)
- **Bug (2026-07-15):** FILL landed on `1-110` and scaled the bg loop. Fix branch:
  `tojemoc/sofie-demo-blueprints` → `cursor/ilu-fill-dedicated-layer-09c3`
  (compare: https://github.com/tojemoc/sofie-demo-blueprints/compare/develop...cursor/ilu-fill-dedicated-layer-09c3)
- **demo-assets:** HTML headline templates are overlay-only (no WebM/`<video>`). ILU always plays via Caspar MEDIA on layer 115.
- **ILU prerendered/bypass** (`iluPrerendered`; legacy `iluFallback` = ON):
  - **OFF** — full-frame 16:9 `.mp4` with MIXER CROP (cover) + FILL `0.08 / 0.15 / 0.62 / 0.73` + `gfx/headline-fallback` chrome
  - **ON** — pre-rendered alpha `.mov`, FILL `0 0 1 1`, no HTML chrome
- **Operator:** after uploading the new blueprint bundle, **re-apply studio config** so Sofie mapping `casparcg_ilu_player` (`CasparCGIluPlayer`) → Caspar layer **115** exists

---

## Sofie Core / Playout Gateway

- No code changes for new template names
- Upload new blueprint bundle → apply studio config → verify Playout Gateway + Caspar subdevice
- Package Manager connects to Core at `coreHost:corePort` (look for `Core Connected!` / `studioId`)

### Package Manager misconfig (not a Core disconnect)

Symptoms that look like “PM cannot connect” but Core is up:

1. Nested Sofie `mediaPackages` object **does not persist in Settings** (edits vanish). Fixed by flattening to top-level fields on `cursor/pm-accessor-type-ingest-09c3`. After uploading that bundle + refresh: edit **Ingest media folder** (and **CasparCG media folder** if separate) as plain strings — do **not** use the nested “Media package containers” object. **Source of truth** is the shared media tree both Package Manager and Rundown Editor read: Sofie studio `ingestMediaFolder` must match RE `INGEST_MEDIA_ROOT` / Settings → Ingest media root (clips live under `<root>/clips/`). Examples: Windows `c:/casparcg/sofie-demo-media`; Docker-mounted `/app/ingest`. Then Apply Configuration. Until the new blueprints are uploaded, you cannot save that nested field in the UI.
2. `getAccessorStaticHandle: Accessor type is undefined` — ExpectedPackage source accessors lacked `type`; also on `cursor/pm-accessor-type-ingest-09c3`. After upload, re-apply studio config and re-ingest/reset the rundown so packages regenerate.

### Rundown Editor ingest scan vs Sofie VID pieces (2026-07-15)

Symptoms:
- Sofie fails regenerating VO/VT/SYN parts with a `video` (VID) piece when **File name** is empty — blueprints called `stripExtension(undefined)` and threw.
- RE mediaPick was **select-only**; with missing `clips/` under `INGEST_MEDIA_ROOT` (often `/app/ingest` in Docker) you could not type a Caspar/PM-relative path. The warning showed only the relative folder next to “Ingest root: …” which looked nonsensical.

Fixes:
- Blueprints `cursor/vid-clip-props-harden-09c3`: require a non-empty path; Invalid “Video clip is missing file name”; treat duration as already ms after editor convert; content fallback to VT for video pieces.
- RE `cursor/media-picker-freetext-09c3`: free-text path (+ datalist/scan picker), show **absolute** scan folder, **Create scan folder** button.

Ops: mount media at the configured ingest root so both RE readiness and Sofie Package Manager see `clips/*.mp4`, or type any path relative to that same media tree.

---

## Verification checklist

```text
[ ] yarn build in demo-assets; inspect deploy/template-path/gfx/*/
[ ] Copy zip to Caspar; AMCP: CG <ch> ADD 0 "<clipName>" 1
[ ] CG <ch> UPDATE 0 "<clipName>" "{\"headline\":\"test\"}"
[ ] Blueprints dist bundle uploaded to Core
[ ] Studio config applied; Sofie mappings: casparcg_clip_player1 (CasparCGClipPlayer1)→110, casparcg_ilu_player (CasparCGIluPlayer)→115, casparcg_graphics_l3d (CasparCGGraphicsLowerThird)→121
[ ] Sofie mappings: casparcg_graphics_pgm_l3d (CasparCGGraphicsPgmLowerThird) → channel 2, layer 121
[ ] Take ILU / GFX with l3d-headline: AMCP shows CG/TEMPLATE on 2-121 (casparcg_graphics_pgm_l3d), not on LED 1-121
[ ] Headline ILU (bypass OFF): AMCP shows PLAY + MIXER CROP/FILL on 1-115 (casparcg_ilu_player) + CG headline-fallback; loop keeps PLAY on 1-110
[ ] Headline ILU (bypass ON): AMCP shows PLAY + FILL 0 0 1 1 on 1-115 only (no HTML chrome)
[ ] RE rundown ingested; take fires correct template + data
[ ] logo-bug survives across parts until rundown end
```

---

## Rundown Editor: readiness/duration diagnostics + daily template workflow (2026-08-05)

Follow-up planning session on
[`RE-READINESS-AND-PLAYOUT-UX.md`](RE-READINESS-AND-PLAYOUT-UX.md). Key finding: ADR
0001 (`docs/adr/0001-re-readiness-from-core-package-manager.md`) is **already
code-complete** on both `sofie-core` main
(`peripheralDevice.packageManager.getContentStatusForRundown`) and `unopus` main
(`backend/src/background/coreContentStatus.ts` hybrid consumer), and the piece
`externalId` contract between RE and blueprints checks out correctly end-to-end. The
operator-reported "readiness/duration doesn't work across the Windows Caspar/PM box →
Alpine LXC" problem is therefore most likely a **silent-failure/observability gap**,
not a missing feature — every failure mode (Core disconnected, RE peripheral device
not attached to a studio, Package Manager down/misconfigured) collapses into the same
unlabeled local-fs fallback today.

Separately, the "editor experience" ask (clone the canonical template — blueprints +
piece/part/segment types + `assets/spravy-v3-smoke-rundown.json` + demo-assets —
automatically every day, then bulk-edit only prompter text / L3D names / ILU-SYN
filenames) turns out to be **mostly already built** in `unopus` main
(`Rundown.isTemplate`, `mutations.createRundownCopy`, `ImportSegmentModal`) — just
manual, with no scheduling and no bulk-edit surface. The abandoned `unopus` `backup`
branch (Google Sheets adapters) and archived `duopus` repo (Sheets + Bitfocus
Companion, vMix-era) are explicitly **not** reusable — spreadsheet-as-source-of-truth
fights the current Sofie-centric (Core-as-sync-target) architecture.

See the two handoffs below for the concrete, file-level plan.

---

## Agent handoffs

| Handoff | Path |
|---------|------|
| Blueprints v2 wiring | [`docs/integration/handoffs/blueprints-v2-wiring.md`](handoffs/blueprints-v2-wiring.md) |
| Demo-assets canonical handoff | [`tojemoc/sofie-demo-assets` → `docs/BLUEPRINTS_HANDOFF.md`](https://github.com/tojemoc/sofie-demo-assets/blob/main/docs/BLUEPRINTS_HANDOFF.md) |
| RE readiness/duration diagnostics | [`docs/integration/handoffs/re-readiness-diagnostics.md`](handoffs/re-readiness-diagnostics.md) |
| RE daily template workflow (clone + bulk rewrite + readiness-aware picker) | [`docs/integration/handoffs/re-daily-template-workflow.md`](handoffs/re-daily-template-workflow.md) |
| This log | [`docs/integration/SPRAVY-V2-INTEGRATION.md`](SPRAVY-V2-INTEGRATION.md) |
