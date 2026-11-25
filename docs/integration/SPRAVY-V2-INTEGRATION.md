# SPRÁVY / 360 sekúnd v2 — cross-repo contract

Working agreement across the Sofie megarepo. Update when demo-assets, blueprints,
rundown-editor, or core wiring changes.

**Last updated:** 2026-11-25

---

## Goal

**Rundown Editor → Sofie Core → Playout Gateway → CasparCG (+ vMix)** driving
v2 HTML templates from `tojemoc/sofie-demo-assets`.

**Hypercomposed (LED ≠ program):** one Caspar renders LED + two look feeds +
clean GFX; **vMix** switches program (look inputs, stingers, clean-GFX overlay).
Legacy fallback: Caspar-switched PGM with `route://` + alpha wipes. Topology:
[`OUTPUT_TOPOLOGY.md`](./OUTPUT_TOPOLOGY.md). Layers:
[`CASPAR-DURABLE-LAYER-MAP.md`](./CASPAR-DURABLE-LAYER-MAP.md). DoubleBox +
switching mechanics: [`DOUBLEBOX-PGM.md`](./DOUBLEBOX-PGM.md). Show spine:
[`SPRAVY-SHOW-FLOW.md`](./SPRAVY-SHOW-FLOW.md).

## Repos

| Repo | Role | Deploy artifact |
|------|------|-----------------|
| `sofie-demo-assets` | Static HTML templates at `template/gfx/*.html` — **no build**; edit HTML directly | copy `template/` → Caspar `<template-path>`, media → `<media-path>` |
| `sofie-demo-blueprints` | `yarn dist` → `*-bundle.js` | upload bundle to Core → **Apply studio config** → **Reset Rundown** |
| `unopus` (Rundown Editor) | Piece/part JSON → ingest; loads type manifests from megarepo `assets/` | `yarn build`; Docker needs `ffmpeg` (ffprobe probes) |
| `sofie-core` | Meteor + playout-gateway | `yarn dev` / `yarn build:packages` |

## Deploy order (full update)

1. `demo-assets`: edit `template/gfx/*`, copy `template/` + media to Caspar paths.
2. `blueprints`: `cd packages/blueprints && yarn dist`, upload bundle in Core WebUI.
3. Core WebUI: **Apply studio config**, then **Reset Rundown** on the active playlist.
4. RE: verify `INGEST_MEDIA_ROOT` = Sofie `ingestMediaFolder` = Caspar `media-path`
   (one shared tree; clips under `<root>/clips/`).
5. `caspar.config`: ≥4 channels (vMix) / ≥5 (legacy + cam ingest); restart Caspar on change.

## Caspar clipName contract

`clipName` = `gfx/<file-name>` — templates are flat files
`template/gfx/<name>.html` (no per-template folder). Sofie sends
`TimelineContentCCGTemplate` with `templateType: 'html'`, `name`, `data`; the
templates expose `window.play() / stop() / update(data)`.

| `clipName` | `update(data)` fields | Lands on |
|------------|----------------------|----------|
| `gfx/headline` | `iluFile`, `source` | LED 115 ILU media |
| `gfx/headline-fallback` | `source` | LED 121 chrome (no text) |
| `gfx/l3d-headline` | `title`, `subtitle` (aliases `headline`/`subline`) | PGM 121/122 clean GFX |
| `gfx/l3d-mod` | `name`, `title` | look 121 |
| `gfx/l3d-tema` | `headline` | look 121 |
| `gfx/l3d-syn` | `name`, `role` (replaces retired `l3d-predstavovak`) | look 121 |
| `gfx/l3d-sjv` | `kicker`, `headline` | look 121 |
| `gfx/l3d-sport` | `kicker` (default `ŠPORT`), `headline` | look 121 |
| `gfx/l3d-odporucanie` | `headline` | look 121 |
| `gfx/pocasie` | `cities` JSON string `[{region,name,temp,…}]`; blueprints map `region`→`BA_temp` etc. | look 121 + `assets/bg_pocasie` on 116 |
| `gfx/ilu-zaver` | `iluFile` | LED 115 windowed (never DoubleBox) |
| `gfx/outro` | — | PGM |
| `gfx/logo-bug` | — | PGM 123, `OutOnRundownEnd` |

**Removed — do not reference:** `gfx/l3d`, `gfx/mod-l3d`, `gfx/head-spravy`,
`gfx/ticker`, `gfx/strap`, `gfx/wipe`, `gfx/head`, `gfx/fullscreen`,
`gfx/l3d-predstavovak` (blueprints coerce old rundowns to `l3d-syn`/`l3d-mod`).

## Media scaffold

```text
<media-path>/
  loops/    bg_loop, db_loop, bg_music_{a,c}
  clips/    ILU, VT, VO, SYN (rundown-specific)
  wipes/    wipe{,_sjv,_sport,_pocasie}  (legacy overlay mode; vMix uses stingers)
  assets/   pod_headline, headline_sfx, testframe, countup, intro_*, outro, bg_pocasie
```

ILU plays via Caspar MEDIA (never CEF `<video>`); PLAY paths are extensionless.
Use H.264 MP4 / ProRes-Hap alpha `.mov` for reliability.

## Timing fields — do not conflate

- **Part Duration** (s) — story length in RE.
- **Piece On air** (s) — piece enable length; empty L3D On air = hold until Take.
- **Sofie `expectedDuration`** (ms) — on-air timeline length after ingest.
- **`payload.sourceDuration`** (ms) — ffprobe media length (VT/VO
  `content.sourceDuration`), independent of On air.
- Video piece fields: `trimIn` / `trimOut` / `volume` (canonical in
  `assets/sofie-rundown-editor-piece-types.json`).

Sofie AUTO appears only where blueprints set `autoNext` (VT / Intro / non-ILU
GFX). ILU parts never autoNext — Start `0`, begin on Take.

## Package Manager / readiness pitfalls

- **False NR badges** = PM folder ≠ Caspar `media-path`:
  [`PLAYOUT-NR-AND-MEDIA-PATH.md`](./PLAYOUT-NR-AND-MEDIA-PATH.md).
- `mediaPackages` edits must be **top-level flat fields**, not the nested object —
  flatten on `cursor/pm-accessor-type-ingest-09c3` or newer.
- `404 PLAY FAILED` on a headline ILU with `CG OK` = `.mp4` missing under
  `<media-path>/clips/` — PM/ingest issue, not a template bug.
- RE ingest root must equal the PM media tree, or both mediaPick and Sofie VID
  pieces fail to resolve.
- Docker RE images need the `ffmpeg` package or ffprobe probes silently null.

## Verify on Caspar (AMCP)

```text
# look probe (channel 2 or 3 — whichever slot was claimed)
CG 2-121 ADD 1 "gfx/l3d-syn" "{\"name\":\"Peter Pellegrini\",\"role\":\"Prezident SR\"}"
CG 4-121 ADD 1 "gfx/l3d-headline" "{\"title\":\"Test\",\"subtitle\":\"sub\"}"
CG 4-123 ADD 1 "gfx/logo-bug"
PLAY 1-115 "clips/headline1"
```

A DoubleBox Take adds `PLAY {2|3}-118 "loops/db_loop" LOOP` + `MIXER {ch}-118
OPACITY 1`; the idle slot reveals `OPACITY 1` at offAir. vMix Takes show no
`wipes/` PLAY and no `route://` — check vMix for the stinger + look inputs.

## Handoffs

| Doc | Purpose |
|-----|---------|
| [`handoffs/blueprints-v2-wiring.md`](handoffs/blueprints-v2-wiring.md) | Blueprints v2 wiring agent prompt |
| [demo-assets `docs/BLUEPRINTS_HANDOFF.md`](https://github.com/tojemoc/sofie-demo-assets/blob/main/docs/BLUEPRINTS_HANDOFF.md) | Template-side contract |
| [`handoffs/re-readiness-diagnostics.md`](handoffs/re-readiness-diagnostics.md) | RE readiness/duration plan |
| [`handoffs/re-daily-template-workflow.md`](handoffs/re-daily-template-workflow.md) | Daily template clone workflow |
