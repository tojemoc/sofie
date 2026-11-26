# DoubleBox compose + look switching

Which source → which channel: [`OUTPUT_TOPOLOGY.md`](./OUTPUT_TOPOLOGY.md).
Every durable layer: [`CASPAR-DURABLE-LAYER-MAP.md`](./CASPAR-DURABLE-LAYER-MAP.md).
This page is the DoubleBox compose, the A/B slot mechanics, and camera wiring.

```text
DoubleBox look (claimed slot's channel)
┌────────────────────────────────────────────────────────────┐
│  db_loop frame (118, alpha cutouts; bg baked in)           │
│   ┌──────────────────────────┐  ┌────────────┐             │
│   │  ILU 16:9 (layer 116)    │  │  CAM pane  │             │
│   │                          │  │  (vMix DVE │             │
│   └──────────────────────────┘  │  layer 1)  │             │
│  ┌───────────────────────────────┴──────────┐              │
│  │  topic L3D (121)            360° bug     │              │
│  └──────────────────────────────────────────┘              │
└────────────────────────────────────────────────────────────┘
```

**LED rule:** headline ILU + `loops/bg_loop` only (baseline layer 110, plus pod /
testframe / headline SFX). No `l3d-*`, no intro, no db_loop, no story VT on LED.

---

## A/B slot ping-pong (vMix)

Two identical look channels (A=ch2, B=ch3) feed vMix look inputs. The generated
`LookSlotSequence` gives every look-bearing Take the **idle** slot — the
opposite of the last claim — so the incoming look always LOADBGs off-air before
the vMix stinger airs it. Non-look parts (Remote / Titles / DVE) `peek()` the
last slot as a stable underlay.

Generation-time slot claims remap the `*_b` layers; runtime arming sees the real
next part (`onSetAsNext`) and also handles cross-segment / re-next cases.

## db_loop phase-lock

`loops/db_loop` (layer 118) is only ever opacity-switched, never EMPTY/paused:

| Situation | Object |
|-----------|--------|
| DoubleBox part, claimed slot | `MIXER …-118 OPACITY 1` at Take (start 0) |
| DoubleBox part, other slot | `OPACITY 1` at the outgoing part's offAirMs — frame stays dressed while off-air |
| Non-frame look part, claimed slot | `*_db_loop_hold` piece, `OPACITY 0` — stale reveals can't linger on air |
| Next part owns frame, current part armed | idle-preview `OPACITY 1` on the idle slot at `offAirMs + 1500` |

`db_loop` is `OutOnSegmentEnd` on DoubleBox parts only, so DB→SYN→DB inside a
tema keeps the frame; it dies with the segment — SJV / Šport / Počasie /
ZAVER+AVIZO never keep a stray frame. Production file may be `dp_loop.mov` —
place/symlink as `loops/db_loop`.

**ZAVER+AVIZO is never a DoubleBox.** An active `gfx/ilu-zaver` object vetoes
`isDoubleBoxLook` (stray `doublebox` rawType / `doublebox-ilu` objects cannot
resurrect the shell) and `parseGraphicsFromObjects` drops the stray object.

## Idle preview arm (off-air channel prep)

`armIdleLookPreviewForNext` runs at `onSetAsNext` on the current part's dormant
`look_idle_preview` piece and pushes, at `offAirMs + 1500` ms on the idle
channel:

1. `playing:false`, `volume:0` clones of the next part's clip/ILU media
   (media-identical to the Take object → hot `RESUME`, no producer swap).
2. The vMix look-INPUT clone (camera pre-positioned off-air).
3. `loops/db_loop` `OPACITY 1` when the next part owns the frame.
4. `gfx/pocasie` template with **empty data** — CEF warm-load (~5 s cold);
   the Take then CG UPDATEs into the real template instead of re-ADD.
5. A mute-then-unmute pair on the look input's audio bridge so lingering clip
   audio can't leak onto the program bus during the delay.

Clears the arm would cover are moved from `offAirMs` to the same delayed point;
originals stash on the piece and restore on re-arm / re-next / cancel.

## Pocasie warm-load + replay

`gfx/pocasie` is the slowest template (~5 s CEF + cascade). Mechanics:

- Preview arm puts the template on the idle channel with `data: {}`.
- The Take's own template object enters at `start 0` (keeps the armed template
  alive — a later start would CG STOP and cold re-ADD).
- A `_replay` object at `wipeDurationMs` (`wipe_pocasie` = real 2000 ms) CG
  UPDATEs with the data — the cascade unrolls **after the wipe ends**, on air.
- Same-slot weather→weather Takes keep the template fully live (no re-warm).

## FILL geometry (tune to graphics)

| Region | Layer | FILL `x y xScale yScale` |
|--------|------:|---------------------------|
| Story ILU (DoubleBox left) | look 116 | `0.0219 0.0769 0.6802 0.6824` |
| CAM DoubleBox pane | vMix look-input layer 1 (DVE) | ~80% width, right edge stuck (vMix-side config) |
| CAM fullscreen (headlines/MOD/ZAVER) | vMix look-input layer 1 | full frame |
| `db_loop` frame | look 118 | full frame alpha |
| Headline ILU (LED) | LED 115 | `0.08 0.15 0.62 0.73` (bypass OFF); `0 0 1 1` (bypass ON) |

Soft compositing needs no luma matte: `db_loop` full-frame alpha + MIXER FILL /
vMix DVE crop for the windows.

---

## Camera wiring

### vMix (current)

The moderator camera is a vMix input (`vmixProgram.cameraInput`), placed on
layer 1 of the active look input — fullscreen or the DoubleBox right window via
vMix DVE. Optional `lookAFeedInput`/`lookBFeedInput` put the Caspar look feed on
layer 2 above the camera (feed mode). **No Caspar ingest channel, no
`route://`, no DeckLink/dshow in AMCP.**

### Legacy Caspar-switched

`casparcg.hypercomposed.pgmCameraProducer` (e.g. `dshow://video=OBS Virtual
Camera` or `DECKLINK DEVICE 1 FORMAT 1080p5000`) opens once on CAM ingest ch5
(`casparcg_pgm_camera_ingest` layer 10). Looks sample it:

```text
PLAY 5-10 DECKLINK DEVICE 1 FORMAT 1080p5000     ← must include DEVICE
PLAY 3-115 route://5                             ← looks only ever route
MIXER 3-115 FILL 0.2 0.1 0.8 0.8                 ← DoubleBox pane
```

| Symptom | Cause | Action |
|---------|-------|--------|
| `404 PLAY FAILED` for a DeckLink string | Old bundle treats it as MEDIA | Upload blueprints ≥#89, Apply config, **Reset Rundown** |
| `DECKLINK 1` without `DEVICE` | Unpatched `casparcg-connection` | Rebuild playout-gateway (Yarn patch), restart |
| `Could not enable video input` | Second `PLAY … DECKLINK` on a look channel | Route via ch5 only |
| `400` on `5-*` | `caspar.config` <5 channels | Add render-only ch5, restart Caspar |
| Producer string edit won't stick | It's in studio config DB, not the bundle | Edit in WebUI Studio settings, save, Reset Rundown |

DShow capture drops (`real-time buffer too full`): patch Caspar `rtbufsize=100M`
or drop OBS Virtual Camera to 720p — see
[`CASPAR-FFMPEG-BUFFERS.md`](./CASPAR-FFMPEG-BUFFERS.md).

---

## Wipes — same files, different semantics

| Mode | Mechanism |
|------|-----------|
| vMix | vMix stingers: `wipe`→Stinger1, `wipe_sjv`→2, `wipe_sport`→3, `wipe_pocasie`→4. Lead PREVIEW selects the incoming look first (stingers air whatever sits in Preview). No Caspar wipe PLAYs. |
| Legacy default | Alpha overlay per file on PGM 205–208 (`LOADBG` then hot `PLAY`); routes 110/111 cut via MIXER opacity/volume keyframes |
| Legacy STING trial | `wipeUseStingRouteTransition` — classical `wipes/wipe` STINGs on route 111 with `wipe_mask`+`wipe_pm` |

Wipe labels record direction (`ILU TO SYN`, `Double Box`, `Spravy JV`, …) — the
file may still be the default `wipe`. Zero/empty RE duration defaults ~2.5 s;
`wipe_pocasie` is capped at its real 2000 ms.

**If wipes never appear:** vMix mode → check the stinger fired (vMix, not Caspar
log) and the look NDI feeds; legacy → watch PGM ch2, confirm hot `PLAY 2-20x`
(no filename = warm) and `route://N` full-channel routes.

## Smoke checklist

1. Media on disk: `loops/db_loop`, `loops/bg_loop`, `assets/intro_*`,
   `assets/outro`, `assets/bg_pocasie`, `assets/countup`, `wipes/*` (legacy mode).
2. Templates: `<template-path>/gfx/*.html` from `demo-assets/template/` (no build).
3. `caspar.config`: ≥4 channels (vMix) / ≥5 (legacy with cam ingest).
4. DoubleBox Take: `PLAY {look}-118 "loops/db_loop"` + `OPACITY 1` on the claimed
   slot; ILU on 116; L3D CG on 121; `MIXER {other}-118 OPACITY 1` at offAir.
5. ZAVER Take: LED `1-115` plays the avízo; **no** `*-118` opacity changes, no
   look-ILU copy.
6. Weather Take: `gfx/pocasie` CG UPDATE at wipe end (2000 ms), not under the wipe.
7. Prep a DoubleBox next: idle channel shows `OPACITY 1` db_loop during the
   preview window — no pop at the Take's wipe.
8. Intro plays on PGM 210 only, never LED.
