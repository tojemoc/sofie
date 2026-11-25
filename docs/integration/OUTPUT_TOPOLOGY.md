# Caspar output topology — LED vs PGM

Canonical map of which Sofie / RE sources land on which Caspar channel.
Layer-by-layer inventory (loops, assets, CG, mapping ids):
[`CASPAR-DURABLE-LAYER-MAP.md`](./CASPAR-DURABLE-LAYER-MAP.md).
DoubleBox compose + switching mechanics: [`DOUBLEBOX-PGM.md`](./DOUBLEBOX-PGM.md).

**Code truth:** `blueprints/packages/blueprints/src/base/studio/applyConfig/mappings/casparcg.ts` +
`casparcgLayers.ts`; vMix switching in `helpers/visionMixer.ts` + `helpers/pgmLook.ts`.

---

## Studio type decides the topology

`visionMixer.type` in the studio blueprint config picks one of two topologies:

| `visionMixer.type` | Who switches program | Production status |
|---|---|---|
| `vMix` | vMix PROGRAM/stingers; Caspar renders look feeds + clean GFX | **Current SPRÁVY studio** |
| anything else | Caspar PGM channel routes `route://N` + alpha wipe overlays | Legacy / fallback |

---

## vMix topology (current)

Five numbered roles; channel numbers are studio config
(`casparcg.hypercomposed.{ledChannel,bgChannelA,bgChannelB,pgmChannel}` — production uses
**1 / 2 / 3 / 4**). No CAM ingest channel: the camera is a vMix input.

| Channel | Role | Consumers | What lives here |
|--------:|------|-----------|-----------------|
| **1** | LED wall | Screen / NDI / SDI | `bg_loop`, pod, headline ILU, LED audio bed |
| **2** | Look A feed | NDI → vMix look input A | Full look stack (see layer map) |
| **3** | Look B feed | NDI → vMix look input B | Same stack, `_b` mappings |
| **4** | Clean GFX feed | NDI → vMix `cleanGfxInput`, keyed on Overlay 1 | Headline L3Ds, intro/outro, logo/countup, PGM audio bed |

```text
CasparCG                          vMix
├── 1 LED   ──► consumers         (not wired to vMix)
├── 2 Look A ──► NDI ──────────► input 2 (lookAInput)
├── 3 Look B ──► NDI ──────────► input 3 (lookBInput)
└── 4 Clean GFX ──► NDI ───────► input 4 (cleanGfxInput, Overlay 1)
                                  camera input 1 = moderator cam
                                  vMix PROGRAM = camera | look A | look B
```

vMix input wiring (`vmixProgram.*` studio config): `cameraInput`, `lookAInput`,
`lookBInput`, `cleanGfxInput`, `bedAInput`, `bedCInput`, optional
`lookAFeedInput` / `lookBFeedInput`, `micInput`, `recordingInput`.

**Camera:** lives on layer 1 of the active look input in vMix (fullscreen or
DoubleBox right window composed by vMix DVE). Optional `look{AFeed,BFeed}Input`
puts the Caspar look feed on layer 2 above the camera. Caspar only renders the
look feed content (clips, ILU, db_loop, L3D) — the cam pane itself is a vMix input.

**Audio:** beds are vMix inputs (`bedAInput`, `bedCInput`), not Caspar layer 80
on the look channels — Caspar 80 remains only on LED 1 and clean-GFX 4.

**Switching:** every Take emits one `vmix_me_program` object (look input, or the
raw `cameraInput` when the part has no look media — never a black look feed).
Wiped Takes fire `Stinger1–4` mapped from the wipe file (`wipe`→1, `wipe_sjv`→2,
`wipe_sport`→3, `wipe_pocasie`→4) with a lead PREVIEW so the stinger airs the
incoming input; hard cuts emit `Cut` at the keepalive point. Caspar sees **no**
wipe PLAYs and **no** PGM route layers in this mode.

### Ops: `caspar.config` — 4 channels

```xml
<channels>
  <channel><video-mode>1080p5000</video-mode><!-- 1 LED: consumers --></channel>
  <channel><video-mode>1080p5000</video-mode><!-- 2 Look A: NDI out to vMix --></channel>
  <channel><video-mode>1080p5000</video-mode><!-- 3 Look B: NDI out to vMix --></channel>
  <channel><video-mode>1080p5000</video-mode><!-- 4 Clean GFX: NDI out to vMix --></channel>
</channels>
```

Symptom of a missing channel: `400 ERROR` spam on `PLAY`/`LOADBG`/`CG` for the
highest channel index.

---

## Legacy Caspar-switched topology

`visionMixer.type` ≠ `vMix`: five channels, Caspar does program switching itself.

| Channel | Role | Consumers |
|--------:|------|-----------|
| **1** | LED | yes |
| **2** | PGM | yes — route bus **110/111** + wipe overlays 205–208 + intro 210 + logo 123 + bed 80 |
| **3** | Look A (DoubleBox-semantic) | none — render-only |
| **4** | Look B (Full-semantic) | none — render-only |
| **5** | CAM ingest | none — sole `DECKLINK`/`dshow` open; looks sample via `route://5` |

Program switching: both `route://3` / `route://4` stay live on PGM 110/111 and
MIXER opacity/volume keyframes cut at the air point while an alpha wipe overlays
on **205–208** (one layer per wipe file). Optional experimental
`casparcg.hypercomposed.wipeUseStingRouteTransition` uses a real STING on route
layer 111 for classical `wipes/wipe` only (`wipe_mask` + `wipe_pm` assets).
CAM ingest needs the 5th channel (`casparcg_pgm_camera_ingest`) — never open
`DECKLINK`/`dshow` on 3/4-115 directly.

Retired on vMix studios (mappings deleted): `casparcg_pgm_route*`,
`casparcg_pgm_effects_player*`, `casparcg_pgm_camera_ingest`.

---

## Production allow-list

### LED (channel 1) — only these

| Content | Mapping id | Layer | Path / template |
|---------|------------|------:|-----------------|
| Background loop | `casparcg_clip_player1` | 110 | `loops/bg_loop` (baseline; optional RE `bg-loop`) |
| Headline pod | `casparcg_led_pod_headline` | 112 | `assets/pod_headline` (headlines only) |
| Calibration frame | `casparcg_led_testframe` | 114 | `assets/testframe` (pre-first-Take) |
| Headline / záver ILU | `casparcg_ilu_player` | 115 | `clips/<name>` |
| Optional ILU chrome | `casparcg_graphics_l3d` | 121 | `gfx/headline-fallback` |
| Audio bed / headline SFX | `casparcg_audio_bed` | 80 | `loops/bg_music_{a\|c}`, `assets/headline_sfx` |

**Nothing else on LED.** No intro/znelka, no wipe, no `l3d-*`, no logo, no camera,
no story VT/SYN.

### Look A / B (channels 2 / 3) — story looks

Same layer numbers on both channels; B uses the `*_b` mapping ids.

| Layer | Content | Mapping id (A / B) |
|------:|---------|---------------------|
| 110 | `loops/bg_loop` sticky underlay | `casparcg_look_bg_loop` / `_b` |
| 115 | Camera (legacy route producer; vMix composes cam on the input instead) | `casparcg_pgm_camera` / `_b` |
| 116 | Story ILU (`doublebox-ilu`), weather `assets/bg_pocasie` | `casparcg_pgm_ilu_player` / `_b` |
| 117 | Calibration CAM (pre-first-Take) | `casparcg_look_calib_cam` (B only) |
| 118 | `loops/db_loop` DoubleBox frame | `casparcg_pgm_doublebox_loop` / `_b` |
| 119 | Calibration frame loop (pre-first-Take) | `casparcg_look_calib_frame` (B only) |
| 120 | SYN/VT/weather clip — **vMix only** (moved above db_loop so the frame keys over clip) | `casparcg_clip_player2` / `_b` |
| 121 | L3D HTML (`l3d-*`, `gfx/pocasie`) | `casparcg_graphics_pgm_l3d` / `_b` |

Legacy Caspar-switched looks use clip layer **111** instead of 120 (below CAM).

### PGM / clean GFX (channel 4 vMix, channel 2 legacy) — overlays only

| Layer | Content | Mapping id |
|------:|---------|------------|
| 80 | Audio bed (legacy PGM bed; vMix beds live in vMix) | `casparcg_audio_bed_pgm` |
| 121 | Headline L3Ds (clean GFX) | `casparcg_graphics_headline` |
| 122 | Look-B headline L3D variant | `casparcg_graphics_pgm_l3d` |
| 123 | Logo / countup `assets/countup` | `casparcg_graphics_logo` |
| 210 | Intro / znelka / outro `assets/intro_*`, `assets/outro` | `casparcg_intro_player_pgm` |
| 205–208 | **Legacy only:** alpha wipe overlays | `casparcg_effects_player_pgm*` |
| 110/111 | **Legacy only:** always-live routes | `casparcg_pgm_route*` |

---

## RE piece → target (cheat sheet)

| RE / piece | Caspar target |
|------------|---------------|
| `bg-loop` / baseline loop | LED **1-110** only |
| `headline` ILU | LED **1-115** + optional **1-121** chrome |
| `camera` | vMix: input layer 1 on the look input (no Caspar). Legacy: look **{ch}-115** `route://5` |
| `doublebox-ilu` | look **116** (claimed slot) |
| DoubleBox `db_loop` | look **118** (phase-locked — see `DOUBLEBOX-PGM.md`) |
| `video` / SYN / VT | look **120** (vMix) / **111** (legacy) |
| `l3d-*` story / weather | look **121** CG; `gfx/pocasie` + `assets/bg_pocasie` on **116** |
| `l3d-headline` (headlines) | clean-GFX PGM **121/122** |
| `ilu-zaver` | LED **1-115** windowed + Full-look CAM — never `db_loop` |
| `logo-bug` / countup | PGM **123** |
| `wipe` | vMix: `Stinger1–4` on the Take. Legacy: **205–208** overlay |
| `intro` / `outro` | PGM **210** |

---

## Why “I can’t see the L3D” — check in order

1. **Wrong feed** — story L3Ds ride the look channel feeding vMix; headline L3Ds
   ride the clean-GFX channel. Neither appears on LED.
2. **AMCP fired?** Caspar log shows `CG {2|3}-121 ADD … "gfx/l3d-…"`.
3. **Templates on disk?** `<template-path>/gfx/*.html` from `demo-assets/template/`
   (static files, no build).
4. **Blank data** — `CG OK` means the template loaded; empty `title` still renders nothing.
5. **vMix side** — the look input must be on program or preview; clean GFX needs
   Overlay 1 on.
6. **Package Manager path** — yellow NR badges:
   [`PLAYOUT-NR-AND-MEDIA-PATH.md`](./PLAYOUT-NR-AND-MEDIA-PATH.md).

## Taxonomies (do not mix)

| Name | Meaning |
|------|---------|
| Caspar **channel** | Physical output (1 LED, 2/3 looks, 4 clean GFX) |
| Caspar **layer** | Z-order inside a channel |
| vMix **input** | Program source (camera, look feeds, clean GFX, beds) |
| Sofie **output layer** | WebUI track — not a Caspar channel |
| Sofie **source layer** | Exclusive WithinPart slot in a part |
| Media **folder** | `clips/` `loops/` `wipes/` `assets/` under media-path |
| HTML **clipName** | Template under template-path (`gfx/l3d-syn`) |

## Related

| Doc | Role |
|-----|------|
| [`CASPAR-DURABLE-LAYER-MAP.md`](./CASPAR-DURABLE-LAYER-MAP.md) | Every durable channel/layer + AMCP shape |
| [`DOUBLEBOX-PGM.md`](./DOUBLEBOX-PGM.md) | DoubleBox compose, phase-lock, preview arming, FILL numbers |
| [`SPRAVY-SHOW-FLOW.md`](./SPRAVY-SHOW-FLOW.md) | Show spine — which transition when |
| [`adr/0002-wipe-prebuild-bg-channels.md`](../adr/0002-wipe-prebuild-bg-channels.md) | Why render-only look channels exist |
