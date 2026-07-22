# DoubleBox PGM + LED loop + UVC camera

Target look for **thematic DoubleBox** on PGM (Caspar channel 2), matching the
production still (ILU left / CAM right / tema+bug bar / `360_loop` behind):

```text
┌────────────────────────────────────────────────────────────┐
│  360_loop (full-bleed background)                          │
│   ┌──────────────────────────┐  ┌────────────┐             │
│   │  ILU 16:9                │  │  CAM1      │             │
│   │  (clip / headline ILU)   │  │  (UVC/mod) │             │
│   └──────────────────────────┘  └────────────┘             │
│  ┌────────────────────────────────────┬──────────────────┐ │
│  │  thematic title (l3d-tema)         │  360° sekúnd bug │ │
│  └────────────────────────────────────┴──────────────────┘ │
└────────────────────────────────────────────────────────────┘
```

**LED (Caspar channel 1)** for this look: **`loops/360_loop` only** — no ILU, no L3Ds,
no camera. The wall is the abstract background; PGM carries the editorial compose.

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

1. Caspar ch1 Screen/NDI → OBS (LED = `360_loop`).
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
| Wipe | 200 | full frame, on top |

Tune FILL against the real HTML chrome; values above match the attached still
approximately.

## Wipes (same media, different semantics)

All story-block transitions use the **same alpha wipe** file under Caspar media, e.g.
`wipes/360_wipe` (place the production ProRes/H.264+alpha under
`sofie-demo-media/wipes/`). Sofie plays it on **PGM layer 200**.

The wipe does not change; the **label** records direction:

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

Smoke rundown pieces use piece type `wipe` with `fileName: wipes/360_wipe` and
`transition: <label>` for operators; playout always uses the same file on PGM.

## Blueprint / mapping notes

| Sofie mapping id | Channel | Layer | Role |
|------------------|---------|-------|------|
| `casparcg_clip_player1` | LED 1 | 110 | LED `360_loop` only (for this look) |
| `casparcg_clip_player2` | PGM 2 | 110 | PGM bg loop (or omit if UVC carries bg) |
| `casparcg_ilu_player` | PGM 2* | 115 | ILU in left window (*move off LED when LED is loop-only) |
| `casparcg_pgm_camera` | PGM 2 | 116 | UVC / CAM1 |
| `casparcg_graphics_pgm_l3d` | PGM 2 | 121 | `l3d-tema` / headline bars |
| `casparcg_graphics_logo` | PGM 2 | 123 | `gfx/logo-bug` (360° sekúnd bug) — **not** on LED |
| `casparcg_effects_player_pgm` | PGM 2 | 200 | Wipes |

\*Today ILU still maps to LED in demo blueprints for the older “LED carries gfx”
mode. DoubleBox PGM requires remapping ILU (+ tema) onto channel 2 — tracked with
the wipe/camera work in blueprints. The **logo-bug is already PGM-only**.

### `bg-loop` folder structure

```text
<casparcgMediaFolder>/loops/360_loop.<ext>
```

Piece payload: `{ "fileName": "loops/360_loop" }` (Caspar PLAY omits extension).
RE piece type `bg-loop` uses `mediaPick` subdir `loops` so the picker opens that
folder; the stored path still includes `loops/…`.

## Smoke checklist

1. Put wipe file at `sofie-demo-media/wipes/360_wipe.*`
2. Confirm OBS Virtual Camera name; test `PLAY 2-116 "dshow://…"` by hand
3. Import megarepo `assets/spravy-v3-smoke-rundown.json` (includes `wipe` pieces)
4. Watch **Caspar channel 2** for wipes + DoubleBox; channel 1 should stay loop-only
   once LED-only mode is applied
