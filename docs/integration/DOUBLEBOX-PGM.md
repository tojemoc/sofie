# DoubleBox PGM + LED loop + UVC camera

**Which source → which Caspar channel:** see the canonical
[`OUTPUT_TOPOLOGY.md`](./OUTPUT_TOPOLOGY.md) first. This page is the DoubleBox
compose / FILL / wipe detail.

Target look for **thematic DoubleBox** on PGM (Caspar channel 2), matching the
production still (ILU left / CAM right / tema+bug bar / `bg_loop` behind):

```text
┌────────────────────────────────────────────────────────────┐
│  bg_loop (full-bleed background)                           │
│   ┌──────────────────────────┐  ┌────────────┐             │
│   │  ILU 16:9                │  │  CAM1      │             │
│   │  (clip / headline ILU)   │  │  (UVC/mod) │             │
│   └──────────────────────────┘  └────────────┘             │
│  ┌────────────────────────────────────┬──────────────────┐ │
│  │  thematic title (l3d-tema)         │  360° sekúnd bug │ │
│  └────────────────────────────────────┴──────────────────┘ │
└────────────────────────────────────────────────────────────┘
```

**LED (Caspar channel 1)** production rule: **headline ILU + `loops/bg_loop` only**.
The loop is blueprint **baseline** on layer 110 (not a RE piece) and must never be
displaced by VT/VO/SYN — those play on **PGM ClipPlayer2**. `l3d-mod` / tema / syn /
headline bars are **PGM**. No intro / znelka on LED. Intro overlay plays on
**PGM layer 210** (above wipe 200) — see
[`handoffs/blueprints-intro-pgm-layer.md`](./handoffs/blueprints-intro-pgm-layer.md)
and [`handoffs/blueprints-baseline-bg-loop.md`](./handoffs/blueprints-baseline-bg-loop.md).

**Story ILU on PGM 115 (pending companion CI/deploy):** mapping
`casparcg_pgm_ilu_player` → **PGM channel 2 layer 115** (piece type `doublebox-ilu`)
is documented and implemented on sofie-demo-blueprints
`cursor/doublebox-ilu-cam-crop-3109` / PR
[#59](https://github.com/tojemoc/sofie-demo-blueprints/pull/59). Headline ILU remains
on LED `casparcg_ilu_player` (1-115). **Do not treat end-to-end PGM-115 validation
as complete** until that companion branch has **passing Test + Typecheck/Lint CI**,
a **deployed commit** uploaded to Sofie with **Apply config**, and the Rundown
Editor has **reloaded type manifests** from megarepo `assets/` (Settings →
Connection → Reload type manifests from assets — or equivalent) so `doublebox` /
`doublebox-ilu` definitions are loaded before any DoubleBox Take. Resume the
`PLAY <pgm>-115` smoke check only after those prerequisites.

**Camera / UVC:** studio `casparcg.hypercomposed.pgmCameraProducer` (demo default
`dshow://video=OBS Virtual Camera`) is played on **PGM 2-116** when a part with a
`camera` piece (`camNo: 1` = Camera A) is Taken. Remove the camera piece to keep
DoubleBox without the CAM window. See
[`RE-READINESS-AND-PLAYOUT-UX.md`](./RE-READINESS-AND-PLAYOUT-UX.md) for wipe/order/NR planning.

**CAM aspect (no squish):** before FILL, blueprints apply MIXER CROP that keeps 16:9
and **cuts from the left** into the frame (right portion stays in the tall CAM box).
Do not stretch CAM1 to the box.

**Story ILU piece:** use piece type `doublebox-ilu` (part preset `doublebox`) — not
`headline`. `doublebox-ilu` plays the clip on **PGM 2-115** with DoubleBox left FILL
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
PLAY 2-116 "dshow://video=OBS Virtual Camera"
MIXER 2-116 FILL 0.62 0.08 0.34 0.72
```

3. Sofie studio config (blueprints) can store that producer string and, on camera
   pieces, PLAY it on **PGM camera layer 116** with the DoubleBox FILL (see below).

Device string is machine-local — set it in studio config, do not hardcode in
rundowns.

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
| BG loop | 110 | full frame (no FILL) |
| ILU | 115 | `0.04 0.08 0.55 0.72` |
| CAM1 UVC | 116 | `0.62 0.08 0.34 0.72` |
| `l3d-tema` + bug | 121 / 123 | HTML templates (bottom bar) |
| Wipe | 200 | full frame alpha wipe |
| Intro / znelka | 210 | full frame — above wipe + compose; **PGM only** |

Tune FILL against the real HTML chrome; values above match the attached still
approximately.

**Cutouts / DoubleBox frame media:** you do **not** need a black/white matte. Soft
compose is loop full-bleed on PGM 110 + MIXER FILL for ILU/CAM windows. If design needs
a branded frame (borders/shadows between windows), use a **full-frame PNG or ProRes/Hap
alpha `.mov`** with transparent holes — not a luma mask (this stack is not wired for
luma key). Put that chrome on a layer between 110 and 115/116, or bake it into HTML.

## Wipes (same media, different semantics)

Story-block transitions use alpha wipe files under Caspar media, default
`wipes/wipe` (plus `wipe_sjv` / `wipe_sport` / `wipe_pocasie` where labelled). Sofie
plays them on **PGM layer 200** as a short overlay on **Take into that part** (not a
vision-mixer cut). Empty/0 RE duration defaults to ~2.5s so layer 200 does not cover
the rest of the part after the wipe finishes.

**If wipes never appear:** (1) watch **Caspar channel 2**, not LED; (2) confirm
`PLAY 2-200 "wipes/wipe"` on Take (else `404` → file missing on disk); (3) re-upload
blueprints + Apply studio config so `casparcg_effects_player_pgm` exists.

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
| `casparcg_clip_player2` | PGM 2 | 110 | PGM bg loop (or omit if UVC carries bg) |
| `casparcg_ilu_player` | LED 1 | 115 | Headline ILU MEDIA (+ `gfx/headline-fallback`) |
| `casparcg_pgm_ilu_player` | PGM 2 | 115 | Thematic DoubleBox left ILU (`doublebox-ilu`) |
| `casparcg_intro_player_pgm` | PGM 2 | 210 | Intro / znelka — **never LED** (handoff; may still be LED 200 until remapped) |
| `casparcg_pgm_camera` | PGM 2 | 116 | UVC / CAM1 (FILL + left cover-crop) |
| `casparcg_graphics_pgm_l3d` | PGM 2 | 121 | `l3d-tema` / `l3d-syn` / headline bars |
| `casparcg_graphics_logo` | PGM 2 | 123 | `gfx/logo-bug` (360° sekúnd bug) — **not** on LED |
| `casparcg_effects_player_pgm` | PGM 2 | 200 | Wipes |

Headline / story ILU on LED vs PGM: opening **headline** ILU stays on **LED**
(`casparcg_ilu_player`). Thematic DoubleBox left-window media uses
`casparcg_pgm_ilu_player` on **PGM channel 2 layer 115** via piece type
`doublebox-ilu`. PGM also carries camera FILL + `l3d-tema` + baseline loop
(`casparcg_clip_player2`). The **logo-bug is PGM-only**.

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
2. Confirm OBS Virtual Camera name; test `PLAY 2-116 "dshow://…"` by hand
3. Import megarepo `assets/spravy-v3-smoke-rundown.json` (includes story-block `wipe` pieces)
4. Watch **Caspar channel 2** for wipes + DoubleBox + Intro
5. **Intro on PGM 210 only (pending until companion blueprints remap is deployed):**
   after uploading the `casparcg_intro_player_pgm` bundle and Sofie Apply config,
   Intro take must show `PLAY <pgm>-210 "assets/intro_michal"` and **must not** play
   Intro on LED (`1-200`). Until that branch lands, treat this check as **pending** —
   do not mark smoke Intro routing complete on LED EffectsPlayer 200.
6. **Story ILU on PGM 115 (pending until companion blueprints CI is green + deployed):**
   mapping `casparcg_pgm_ilu_player` → channel 2 layer 115 is specified above. After
   sofie-demo-blueprints PR #59 (or successor) has **passing Test and Typecheck/Lint**,
   the bundle is uploaded + Sofie **Apply config**, **and** RE has **reloaded type
   manifests** from megarepo `assets/` (so `doublebox` / `doublebox-ilu` are loaded),
   a DoubleBox Take must show `PLAY <pgm>-115 "clips/…"` (with FILL + CROP) on
   **channel 2**. Headline parts still use LED `1-115`. Do **not** Take until those
   definitions are loaded. Until the prerequisites land, keep this checklist item
   **pending**.
