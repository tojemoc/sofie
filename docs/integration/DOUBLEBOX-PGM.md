# DoubleBox PGM + LED loop + UVC camera

**Which source → which Caspar channel:** see the canonical
[`OUTPUT_TOPOLOGY.md`](./OUTPUT_TOPOLOGY.md) first. This page is the DoubleBox
compose / FILL / wipe detail.

Target look for **thematic DoubleBox** on a **BG look channel** (3 or 4), routed to
PGM (Caspar channel 2) via `route://`, matching the production still (ILU left / CAM
right / tema+bug bar / `db_loop` frame with bg baked in):

```text
┌────────────────────────────────────────────────────────────┐
│  db_loop frame (bg baked in; LED still has bg_loop)        │
│   ┌──────────────────────────┐  ┌────────────┐             │
│   │  ILU 16:9 (layer 116)    │  │  CAM1      │             │
│   │  (above CAM overhang)    │  │  (115 UVC) │             │
│   └──────────────────────────┘  └────────────┘             │
│  ┌────────────────────────────────────┬──────────────────┐ │
│  │  thematic title (l3d-predstavovak) │  360° sekúnd bug │ │
│  └────────────────────────────────────┴──────────────────┘ │
└────────────────────────────────────────────────────────────┘
```

**LED (Caspar channel 1)** production rule: **headline ILU + `loops/bg_loop` only**.
The loop is blueprint **baseline** on layer 110 (not a RE piece) and must never be
displaced by VT/VO/SYN — those play on **BG look** channels (3/4). `l3d-predstavovak` /
`l3d-mod` / `l3d-syn` / headline bars are on the **look**, then routed to PGM. No intro /
znelka on LED. Intro overlay plays on **PGM layer 210** (above the route on 110) — see
[`handoffs/blueprints-intro-pgm-layer.md`](./handoffs/blueprints-intro-pgm-layer.md)
and [`handoffs/blueprints-baseline-bg-loop.md`](./handoffs/blueprints-baseline-bg-loop.md).

**Story ILU on look 116:** mapping
`casparcg_pgm_ilu_player` → **BG channel 3/4 layer 116** (piece type `doublebox-ilu`)
sits **above** CAM (115) so the left window covers CAM overhang without cropping the camera.
Headline ILU remains on LED `casparcg_ilu_player` (1-115). PGM hears the mix via
`PLAY 2-110 route://{3|4}` (`layer: null` — full channel, never `route://N-0`).

**Camera / UVC:** studio `casparcg.hypercomposed.pgmCameraProducer` (e.g.
`dshow://video=OBS Virtual Camera`):

- **Headlines / post-intro MOD** → PGM 2-115 **fullscreen** (FILL `0 0 1 1`)
- **DoubleBox** → PGM 2-115 under ILU (116) and `db_loop` (118), ~**80%** width, right edge stuck to
  the screen right (`FILL 0.2 0.1 0.8 0.8`). ILU covers CAM left overhang — no CAM cover-crop.

`db_loop` is **WithinPart** on DoubleBox Takes only (not Intro) so SYN / weather stay
fullscreen. Production file may be named `dp_loop.mov` — place/symlink as `loops/db_loop`.

**Story ILU piece:** use piece type `doublebox-ilu` (part preset `doublebox`) — not
`headline`. `doublebox-ilu` plays the clip on **PGM 2-116** with DoubleBox left FILL
+ center cover-crop and **no** `gfx/headline-fallback` chrome. Headline ILU stays on
LED for the opening block only.

## Getting CAM into Caspar (OBS Virtual Camera → UVC)

Yes. Caspar can PLAY a webcam/UVC device as a media producer on the PGM channel.

### Recommended path (clean CAM into the right box)

1. OBS (or any cam app) exposes **OBS Virtual Camera** (or another UVC device) with the
   moderator feed (no need to bake the LED into OBS if Caspar does DoubleBox).
2. On the Caspar host (Windows), confirm the device name, e.g. in PowerShell /
   GraphEdit, or try AMCP:

```text
PLAY 2-115 "dshow://video=OBS Virtual Camera"
MIXER 2-115 FILL 0.2 0.1 0.8 0.8
```

3. Sofie studio config (blueprints) can store that producer string and, on camera
   pieces, PLAY it on **PGM camera layer 115** with the DoubleBox FILL (see below).

Device string is machine-local — set it in studio config, do not hardcode in
rundowns.

**DShow buffer drops:** If Caspar logs `real-time buffer … too full (102% of size:
3041280 [rtbufsize parameter])`, FFmpeg’s default ~3 MiB capture buffer is too small
for 1080p virtual camera under compositing load. Raising `<consumers><screen><buffer-depth>`
in `caspar.config` only smooths **output** — it does not fix capture drops. Patch the
Caspar server to set `rtbufsize=100M` for `dshow://` inputs, or lower OBS Virtual
Camera to 720p. See [`CASPAR-FFMPEG-BUFFERS.md`](./CASPAR-FFMPEG-BUFFERS.md).

### OBS “finished look” shortcut

If you want a quick preview before Sofie owns the full compose:

1. Caspar ch1 Screen/NDI → OBS (LED = `bg_loop`).
2. OBS stacks mod footage on top → **Start Virtual Camera**.
3. Caspar ch2 PLAYs that UVC as a **base** layer; Sofie still overlays PGM wipe /
   tema / ILU as they land.

Prefer the recommended path for production; the shortcut is fine for lighting/look
checks.

### FILL geometry (starting point — tune to graphics)

| Region | Layer (PGM ch2) | FILL `x y xScale yScale` |
|--------|-----------------|---------------------------|
| Story VT / weather | 110 | full frame (no FILL) — **not** baseline `bg_loop` |
| CAM1 UVC (DoubleBox) | 115 | `0.2 0.1 0.8 0.8` (under ILU + `db_loop`) |
| ILU | 116 | `0.0219 0.0769 0.6802 0.6824` (above CAM) |
| CAM1 UVC (headlines/MOD) | 115 | `0 0 1 1` fullscreen |
| `db_loop` frame | 118 | full frame alpha cutouts |
| topic L3D + bug | 121 / 123 | HTML templates on **BG look** 121; logo/bug on **PGM 123** (above route) |
| Story wipe | **PGM 110** | `PLAY 2-110 route://{3\|4}` + STING (`wipes/wipe…`) — **not** overlay 200 |
| Intro / outro | 210 | full frame — above route; **PGM only** |

Tune FILL against the real HTML chrome; values above match the attached still
approximately.

**Cutouts / DoubleBox frame media:** you do **not** need a black/white matte. Soft
compose is `db_loop` full-frame on PGM **118** + MIXER FILL for ILU/CAM windows
(115/116). If design needs a branded frame (borders/shadows between windows), use a
**full-frame PNG or ProRes/Hap alpha `.mov`** with transparent holes — not a luma mask
(this stack is not wired for luma key). That chrome is `db_loop` on 118 (or bake it
into HTML); do not put a background loop on PGM 110.

## Wipes (same media, different semantics)

Story-block transitions use alpha wipe files under Caspar media, default
`wipes/wipe` (plus `wipe_sjv` / `wipe_sport` / `wipe_pocasie` where labelled).

**Shipped (sofie-demo-blueprints [#77](https://github.com/tojemoc/sofie-demo-blueprints/pull/77)):**
looks pre-build on **BG channels 3/4**; PGM takes
`PLAY 2-110 route://{3|4}` with STING (wipe file as mask/overlay). Logo stays on
**PGM 123** above the route. Empty/0 RE wipe duration still defaults to ~2.5s for the
transition length. See [`adr/0002-wipe-prebuild-bg-channels.md`](../adr/0002-wipe-prebuild-bg-channels.md)
and [`OUTPUT_TOPOLOGY.md`](./OUTPUT_TOPOLOGY.md).

**Legacy:** overlay `PLAY 2-200 "wipes/wipe"` while cold-starting on PGM — compatibility
only; migrated story wipes must not use layer 200.

**If wipes never appear:** (1) watch **Caspar channel 2**, not LED; (2) confirm
`PLAY 2-110 route://{3|4}` with STING on Take (not `route://N-0`); (3) Caspar
`caspar.config` has **≥4 channels**; (4) re-upload blueprints + Apply studio config.

The **label** records direction (file may still be the default wipe):

| Label | Meaning |
|-------|---------|
| `BLANK` | No wipe (HOLD / cold open) |
| `Headline 1..3` | Into headline ILUs |
| `Intro` | Into intro overlay |
| `Double Box` | Into thematic DoubleBox (ILU+CAM+tema) |
| `ILU TO SYN` / `SYN TO ILU` | DoubleBox ↔ full SYN videoclip |
| `ILU TO SYN CLUSTER` | Into a SYN cluster after DoubleBox |
| `SYN TO ILU TEMA` / `ILU TO ILU TEMA` | Into DoubleBox / tema-framed ILU |
| `SYN TO SYN` | SYN → SYN |
| `Spravy JV` / `Spravy JV NEXT` | SJV block |
| `Sport` / `Sport NEXT` | Šport block |
| `Pocasie` / `Zaver` / `OUTRO` | Closing sequence |

Smoke rundown pieces use piece type `wipe` with `fileName: wipes/wipe` (or a
labelled variant) and `transition: <label>` for operators.

## Blueprint / mapping notes

| Sofie mapping id | Channel | Layer | Role |
|------------------|---------|-------|------|
| `casparcg_clip_player1` | LED 1 | 110 | LED `bg_loop` |
| `casparcg_clip_player2` / `_b` | BG 3 / 4 | 110 | Story VT / weather on look (no baseline `bg_loop`) |
| `casparcg_pgm_route` | PGM 2 | 110 | Full-channel `route://{3\|4}` (+ STING wipe) |
| `casparcg_ilu_player` | LED 1 | 115 | Headline ILU MEDIA (+ `gfx/headline-fallback`) |
| `casparcg_pgm_camera` / `_b` | BG 3 / 4 | 115 | UVC / CAM1 (FILL on DoubleBox look) |
| `casparcg_pgm_ilu_player` / `_b` | BG 3 / 4 | 116 | Thematic DoubleBox left ILU (`doublebox-ilu`) |
| `casparcg_intro_player_pgm` | PGM 2 | 210 | Intro / znelka — **never LED** |
| `casparcg_graphics_pgm_l3d` / `_b` | BG 3 / 4 | 121 | `l3d-predstavovak` / `l3d-odporucanie` / `l3d-syn` / headline bars |
| `casparcg_graphics_logo` | PGM 2 | 123 | `gfx/logo-bug` / countup — **above route; not on LED** |
| `casparcg_effects_player_pgm` | PGM 2 | 200 | Legacy overlay wipe only (story wipes use route STING) |

Headline / story ILU on LED vs look: opening **headline** ILU stays on **LED**
(`casparcg_ilu_player`). Thematic DoubleBox left-window media uses
`casparcg_pgm_ilu_player` on the **BG look** (ch 3/4 layer 116) via piece type
`doublebox-ilu`. Looks also carry camera FILL + `l3d-predstavovak`; PGM only
**routes** the settled mix on layer 110. Baseline `bg_loop` is **LED-only**.
The **logo-bug is PGM-only** (layer 123).

### `bg-loop` folder structure

```text
<casparcgMediaFolder>/loops/bg_loop.<ext>
```

Piece payload: `{ "fileName": "loops/bg_loop" }` (Caspar PLAY omits extension).
RE piece type `bg-loop` uses `mediaPick` subdir `loops` so the picker opens that
folder; the stored path still includes `loops/…`. Blueprints baseline must use the
same basename (see [`handoffs/blueprints-baseline-bg-loop.md`](./handoffs/blueprints-baseline-bg-loop.md)).

## Smoke checklist

1. Put wipe file at `sofie-demo-media/wipes/wipe.*` (and optional
   `wipe_sjv` / `wipe_sport` / `wipe_pocasie`) and Intro disk asset at
   `sofie-demo-media/assets/intro_michal.mov`
   (PLAY path `assets/intro_michal`)
2. Confirm OBS Virtual Camera name; test `PLAY 2-115 "dshow://…"` by hand
3. Import megarepo `assets/spravy-v3-smoke-rundown.json` (includes story-block `wipe` pieces)
4. Watch **Caspar channel 2** for `route://` + STING wipes + Intro; confirm looks on **3/4**
5. **Activate (Rehearsal):** LED shows `PLAY 1-110 "loops/bg_loop"`; PGM must **not** play
   `bg_loop` on ClipPlayer2.
6. **Intro on PGM 210 only:** Intro take must show `PLAY <pgm>-210 "assets/intro_michal"` and
   **must not** play Intro on LED (`1-200`).
7. **Post-intro MOD:** camera on look channel 115 — not `bg_loop` on PGM.
8. **Story ILU on look 116 above CAM:** DoubleBox Take must show `PLAY {3|4}-116 "clips/…"`
9. **Wiped Take:** AMCP shows `PLAY 2-110 route://{3|4}` (full channel, **not** `route://N-0`) with STING; logo on `2-123` uninterrupted
   and CAM on **115** (ILU z-order above CAM). Headline parts still use LED `1-115`.
