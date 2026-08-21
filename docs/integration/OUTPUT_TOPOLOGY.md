# Caspar output topology — LED vs PGM

**Canonical** map of which Sofie / RE sources land on which Caspar channel.
DoubleBox compose detail: [`DOUBLEBOX-PGM.md`](./DOUBLEBOX-PGM.md).
Integration status / catalogue: [`SPRAVY-V2-INTEGRATION.md`](./SPRAVY-V2-INTEGRATION.md).

**Code truth** (blueprints): `packages/blueprints/src/base/studio/applyConfig/mappings/casparcg.ts` +
`casparcgLayers.ts`, routing in `helpers/graphics.ts` (`PGM_L3D_CLIP_NAMES`).

---

## One picture

One **CasparCG server**, two **channels** (default hypercomposed studio):

| Consumer | Caspar channel | What operators see |
|----------|----------------|--------------------|
| **LED** (wall / studio screen) | **1** | Background loop + opening headline ILUs only |
| **PGM** (program / OBS / SDI) | **2** | Full compose: DoubleBox, L3Ds, camera, wipe, intro, logo-bug |

```text
CasparCG
├── Channel 1 ──► LED consumer(s)     Screen / NDI / SDI for ch1
└── Channel 2 ──► PGM consumer(s)     Screen / NDI / SDI for ch2
```

A second Caspar host is **not** required. If L3D / wipe / intro look “missing”, open the
**channel 2** consumer — channel 1 will never show them by design.

Studio config overrides: `casparcg.hypercomposed.ledChannel` / `pgmChannel` (defaults 1 / 2).

---

## Production allow-list

### LED (channel 1) — only these

| Content | Mapping id | Layer | Typical path / template |
|---------|------------|------:|-------------------------|
| Background loop | `casparcg_clip_player1` | 110 | `loops/bg_loop` (baseline; optional RE `bg-loop`) |
| Headline ILU media | `casparcg_ilu_player` | 115 | `clips/<name>` + `gfx/headline-fallback` chrome |

**Nothing else on LED.** No intro/znelka, no wipe, no `l3d-*`, no logo-bug, no camera, no
story VT/SYN fullscreen, no Presenter MOD.

### PGM (channel 2) — everything else

| Content | Mapping id | Layer | Notes |
|---------|------------|------:|-------|
| PGM bg loop | `casparcg_clip_player2` | 110 | Baseline companion loop |
| DoubleBox story ILU | `casparcg_pgm_ilu_player` | 115 | Piece type `doublebox-ilu` (FILL + crop) |
| Camera / UVC | `casparcg_pgm_camera` | 116 | e.g. `dshow://video=OBS Virtual Camera` |
| DoubleBox frame (`db_loop`) | `casparcg_pgm_doublebox_loop` | 118 | `loops/db_loop` alpha cutouts — WithinPart on DoubleBox Takes |
| PGM L3D HTML | `casparcg_graphics_pgm_l3d` | 121 | `gfx/l3d-headline`, `l3d-predstavovak`, `l3d-odporucanie`, `l3d-syn`, `l3d-mod`, `l3d-sjv`, `l3d-sport` |
| Logo-bug | `casparcg_graphics_logo` | 123 | `gfx/logo-bug` — PGM only |
| Alpha wipe | `casparcg_effects_player_pgm` | 200 | `wipes/wipe` on Take into part |
| Intro / znelka / outro | `casparcg_intro_player_pgm` | 210 | `assets/intro_*`, `assets/outro` — above wipe; **never LED** |
| Weather / fullscreen story GFX | `casparcg_clip_player2` | 110 | `weather` bypass / fullscreen — must not displace LED 110 |

Legacy LED mappings still exist (`casparcg_effects_player` → LED 200,
`casparcg_graphics_l3d` → LED 121) for non-hypercomposed / unused paths. Hypercomposed
SPRÁVY must not route Intro or PGM L3Ds through them.

---

## RE piece → Caspar (cheat sheet)

| RE / piece | Sofie source layer (typical) | Caspar |
|------------|------------------------------|--------|
| `bg-loop` / baseline loop | — | **LED 1-110** (+ PGM 2-110 baseline) |
| `headline` ILU (`gfx/headline` + `clips/…`) | Lower Third | **LED 1-115** (+ fallback CG on LED 121) |
| `l3d-headline` / `l3d-predstavovak` / `l3d-odporucanie` / `l3d-mod` / `l3d-syn` / `l3d-sjv` / `l3d-sport` | PGM L3D (`lower_third_pgm`) | **PGM 2-121** |
| `doublebox-ilu` | Lower Third | **PGM 2-115** |
| `camera` | Camera | **PGM 2-116** |
| DoubleBox `db_loop` (blueprint WithinPart) | PGM DoubleBox loop | **PGM 2-118** |
| `logo-bug` | Logo | **PGM 2-123** |
| `wipe` | — | **PGM 2-200** |
| `intro` / `outro` | Titles | **PGM 2-210** |
| `weather` / fullscreen | GFX | **PGM 2-110** |

**Sofie WebUI “GFX” vs “PGM” tracks ≠ Caspar channels.** PGM L3Ds stay on the Sofie **GFX**
output track (so they are not flattened with Camera) while Caspar still plays them on
**channel 2**. See blueprints PR for `lower_third_pgm` → OutputLayer.Gfx.

---

## Why “I can’t see the L3D”

Check in order:

1. **Wrong consumer** — watching LED (ch1). L3Ds are **PGM ch2 layer 121** only.
2. **AMCP fired?** Caspar log should show `CG 2-121 ADD … "gfx/l3d-…" … 202 CG OK`.
   - If you only see `CG 2-121` and **no** `PLAY 1-115` on a HEADLINE that should have both:
     Sofie pruned ILU vs L3D on one source layer (fixed by separate `lower_third_pgm`).
   - If **no** `CG 2-121` at all: bundle / ingest / piece not on the timeline.
3. **Templates on disk?** `<template-path>/gfx/l3d-headline/l3d-headline.html` (etc.) from
   `demo-assets` `yarn build` → `deploy/template-path`.
4. **Blank HTML / wrong data** — CG OK means Caspar loaded the template; empty `title` /
   missing assets can still look invisible.
5. **Covered** — wipe (200) or intro (210) sitting above 121 until they clear.

`INFO 2` (or a Screen consumer with `<channel-index>2</channel-index>`) confirms ch2 is live.

---

## Taxonomies (do not mix)

| Name | What it means | Examples |
|------|---------------|----------|
| Caspar **channel** | Physical output | 1 = LED, 2 = PGM |
| Caspar **layer** | Z-order on that channel | 110 loop, 115 ILU, 116 cam, 118 `db_loop`, 121 L3D, 200 wipe |
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
116  Camera (DoubleBox right / fullscreen headlines)
115  Story ILU (DoubleBox left)
110  bg loop / fullscreen story GFX
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
