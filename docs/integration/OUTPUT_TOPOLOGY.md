# Caspar output topology — LED vs PGM

**Canonical** map of which Sofie / RE sources land on which Caspar channel.
DoubleBox compose detail: [`DOUBLEBOX-PGM.md`](./DOUBLEBOX-PGM.md).
Integration status / catalogue: [`SPRAVY-V2-INTEGRATION.md`](./SPRAVY-V2-INTEGRATION.md).

**Code truth** (blueprints): `packages/blueprints/src/base/studio/applyConfig/mappings/casparcg.ts` +
`casparcgLayers.ts`, routing in `helpers/graphics.ts` (`PGM_L3D_CLIP_NAMES`).

---

## One picture

One **CasparCG server**, **four channels** (default hypercomposed studio after
sofie-demo-blueprints **#77** + route/cam fixes):

| Role | Caspar channel | Consumers |
|------|----------------:|-----------|
| **LED** | **1** | Screen / NDI / SDI — `bg_loop` + headline ILU + LED audio bed |
| **PGM** | **2** | Screen / NDI / SDI — `route://{3\|4}` + logo/countup/intro + PGM audio bed |
| **DoubleBox (BG A)** | **3** | **none** — cam + ILU + `db_loop` + L3D téma (pre-build look A) |
| **Full (BG B)** | **4** | **none** — SYN / SJV / Sport / Weather / fullscreen cam (pre-build look B) |

```text
CasparCG
├── Channel 1 ──► LED consumer(s)          bg_loop + headline ILU
├── Channel 2 ──► PGM consumer(s)          route://3|4 (+ STING wipe) + overlays + beds
├── Channel 3 ──► (no consumer)            DoubleBox look
└── Channel 4 ──► (no consumer)            Full look (SYN / weather / fullscreen cam)
```

Studio config: `casparcg.hypercomposed.ledChannel` / `pgmChannel` / `bgChannelA` /
`bgChannelB` (defaults **1 / 2 / 3 / 4**).

**Audio:** SYN/ILU play on the BG look; PGM hears them via a **full-channel** route
(`route://N`, never `route://N-0`). Beds duplicate on LED+PGM layer 80. RE `volume` on
video pieces drives clip mixer volume.

**False “Voice Over / ILU can't be found” badges** while Caspar still plays files:
[`PLAYOUT-NR-AND-MEDIA-PATH.md`](./PLAYOUT-NR-AND-MEDIA-PATH.md) (Package Manager folder
must match Caspar `media-path`, e.g. `Y:/360-ingest/sofie-demo-media`).

### Ops: `caspar.config` must declare ≥4 channels

If Caspar logs spam **`400 ERROR`** on every `LOADBG`/`PLAY`/`CG` for **3-*** and
**4-***, add two render-only channels (same `video-mode`, **no** Screen/NDI/SDI
consumers on 3/4), restart Caspar, re-**Apply** studio config. See ADR
[`0002-wipe-prebuild-bg-channels.md`](../adr/0002-wipe-prebuild-bg-channels.md).

---

## Production allow-list

### LED (channel 1) — only these

| Content | Mapping id | Layer | Typical path / template |
|---------|------------|------:|-------------------------|
| Background loop | `casparcg_clip_player1` | 110 | `loops/bg_loop` (baseline; optional RE `bg-loop`) |
| Headline ILU media | `casparcg_ilu_player` | 115 | `clips/<name>` + `gfx/headline-fallback` chrome |

**Nothing else on LED.** No intro/znelka, no wipe, no `l3d-*`, no logo-bug, no camera, no
story VT/SYN fullscreen, no Presenter MOD.

### DoubleBox / Full (channels 3 / 4) — story looks

| Content | Mapping id | Layer | Notes |
|---------|------------|------:|-------|
| SYN / VT / weather BG | `casparcg_clip_player2` / `_b` | 110 | Fullscreen editorial on the active look |
| Camera / UVC | `casparcg_pgm_camera` / `_b` | 115 | `dshow://…` — **no PRELOAD** (one live capture) |
| DoubleBox story ILU | `casparcg_pgm_ilu_player` / `_b` | 116 | Piece type `doublebox-ilu` |
| DoubleBox frame (`db_loop`) | `casparcg_pgm_doublebox_loop` / `_b` | 118 | Alpha cutouts |
| Topic / SYN L3D HTML | `casparcg_graphics_pgm_l3d` / `_b` | 121 | `l3d-tema`, `l3d-syn`, `pocasie`, … |

### PGM (channel 2) — route bus + overlays

| Content | Mapping id | Layer | Notes |
|---------|------------|------:|-------|
| Full-channel route | `casparcg_pgm_route` | 110 | `route://{3\|4}` CUT or STING wipe |
| Logo / countup | `casparcg_graphics_logo` | 123 | `assets/countup` — above route |
| Intro / znelka / outro | `casparcg_intro_player_pgm` | 210 | `assets/intro_*`, `assets/outro` |
| Audio bed | `casparcg_audio_bed_pgm` | 80 | Mirrors LED kolíska |

Legacy LED mappings still exist (`casparcg_effects_player` → LED 200,
`casparcg_graphics_l3d` → LED 121) for non-hypercomposed / unused paths. Hypercomposed
SPRÁVY must not route Intro or PGM L3Ds through them.

---

## RE piece → Caspar (cheat sheet)

| RE / piece | Sofie source layer (typical) | Caspar |
|------------|------------------------------|--------|
| `bg-loop` / baseline loop | — | **LED 1-110 only** (never PGM companion) |
| `headline` ILU (`gfx/headline` + `clips/…`) | ILU | **LED 1-115** |
| `l3d-*` / `l3d-syn` / weather HTML | PGM L3D | **look 3/4-121** (routed to PGM) |
| `doublebox-ilu` | Lower Third | **look 3/4-116** |
| `camera` | Camera | **look 3/4-115** |
| DoubleBox `db_loop` | PGM DoubleBox frame | **look 3/4-118** |
| `video` SYN/VO | Voice Over | **look 3/4-110** |
| `logo-bug` / countup | Logo | **PGM 2-123** |
| `wipe` | PGM Wipe | **PGM 2-110 route STING** |
| `intro` / `outro` | Titles | **PGM 2-210** |
| `weather` | GFX | **look clip 110** + `assets/bg_pocasie` + HTML |

**Sofie WebUI “GFX” vs “PGM” tracks ≠ Caspar channels.** Story looks compose on BG 3/4;
PGM only routes the settled mix.

---

## Why “I can’t see the L3D”

Check in order:

1. **Wrong consumer** — watching LED (ch1). Story L3Ds are on look channels routed to **PGM ch2**.
2. **AMCP fired?** Caspar log should show `CG {3\|4}-121 ADD … "gfx/l3d-…" … 202 CG OK` and
   `PLAY 2-110 route://{3\|4}` (**not** `route://N-0`).
3. **Templates on disk?** `<template-path>/gfx/l3d-headline/l3d-headline.html` (etc.) from
   `demo-assets` `yarn build` → `deploy/template-path`.
4. **Blank HTML / wrong data** — CG OK means Caspar loaded the template; empty `title` /
   missing assets can still look invisible.
5. **Covered** — wipe STING or intro (210) sitting above the route until they clear.
6. **Package Manager path** — yellow NR badges: [`PLAYOUT-NR-AND-MEDIA-PATH.md`](./PLAYOUT-NR-AND-MEDIA-PATH.md).


`INFO 2` (or a Screen consumer with `<channel-index>2</channel-index>`) confirms ch2 is live.

---

## Taxonomies (do not mix)

| Name | What it means | Examples |
|------|---------------|----------|
| Caspar **channel** | Physical output | 1 = LED, 2 = PGM |
| Caspar **layer** | Z-order on that channel | 110 loop/VT, 115 cam, 116 ILU, 118 `db_loop`, 121 L3D, 200 wipe |
| Sofie **output layer** | WebUI track (GFX / PGM / …) | Not the same as Caspar channel |
| Sofie **source layer** | Exclusive WithinPart slot | Lower Third vs PGM L3D |
| Media **folder** | Disk under media-path | `clips/`, `loops/`, `wipes/`, `assets/` |
| HTML **clipName** | Template under template-path | `gfx/l3d-predstavovak` |

WebUI “Lower Third can't be found on the playout system” is Package Manager path verify —
not “Caspar PLAY failed”. See [`assets/README.md`](../../assets/README.md).

---

## Layer stacks (z-order)

### LED channel 1

```text
200  Effects (legacy — do not use for Intro in hypercomposed)
123  (deprecated logo slot — unused; logo is PGM)
122  Strap (legacy)
121  Graphics L3D / headline-fallback chrome
120  Ticker (legacy)
115  Headline ILU  ◄── allow-list
110  bg_loop       ◄── allow-list
100  Clip preview
 80  Audio bed
```

### PGM channel 2

```text
210  Intro / znelka / outro
200  Wipe
123  logo-bug
121  l3d-* HTML
118  db_loop (DoubleBox frame — above cam/ILU)
116  Story ILU (DoubleBox left — above CAM overhang)
115  Camera (DoubleBox right / fullscreen headlines)
110  Fullscreen story GFX / weather (no baseline bg_loop)
```

---

## Related

| Doc | Role |
|-----|------|
| [`DOUBLEBOX-PGM.md`](./DOUBLEBOX-PGM.md) | DoubleBox FILL/CROP, UVC, wipe labels, smoke checklist |
| [`SPRAVY-SHOW-FLOW.md`](./SPRAVY-SHOW-FLOW.md) | Full show spine: headlines → topics → SJV → sport → weather → outro |
| [`SPRAVY-V2-INTEGRATION.md`](./SPRAVY-V2-INTEGRATION.md) | Cross-repo status, template catalogue, deploy |
| [`handoffs/blueprints-intro-pgm-layer.md`](./handoffs/blueprints-intro-pgm-layer.md) | Intro → PGM 210 (never LED) |
| `demo-assets` (when present) | HTML templates + media scaffold; historical path `docs/OUTPUT_TOPOLOGY.md` redirects here |
