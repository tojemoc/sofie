# ADR 0002: Pre-build wipe scenes on background Caspar channels

**Status:** BG pre-build and PGM routing are implemented in blueprints ([#77](https://github.com/tojemoc/sofie-demo-blueprints/pull/77)); look-slot flips are wipe-gated. Default wipe mode is **OVERLAY**: per-file alpha wipes on PGM **205–208**, with both routes live on **110/111** and route visibility switched by MIXER keyframes. An experimental per-studio `casparcg.hypercomposed.wipeUseStingRouteTransition` flag (default **false**, Studio → CasparCG → Hypercomposed output channels) enables STING for classical `wipes/wipe` only, on canonical route layer **111**, using separate `wipes/wipe_mask` and `wipes/wipe_pm` assets; themed wipes remain overlays. **Requires Caspar ≥4 channels** (≥5 when CAM ingest is enabled). See [`OUTPUT_TOPOLOGY.md`](../integration/OUTPUT_TOPOLOGY.md) and [`DOUBLEBOX-PGM.md`](../integration/DOUBLEBOX-PGM.md).
**Date:** 2026-09-03
**Repos affected:** `tojemoc/sofie-demo-blueprints` (primary), Caspar `caspar.config`,
megarepo docs (`OUTPUT_TOPOLOGY`, `DOUBLEBOX-PGM`)
**Owner:** SPRÁVY playout

## Context

Today DoubleBox, fullscreen SYN/VT, camera, HTML L3Ds, and alpha wipes all live as
**layers on the same PGM channel** (default Caspar ch2). On Take with a wipe piece,
Sofie fires `PLAY`/`CG ADD` for the next scene's layers **at the same time** as the
wipe overlay on PGM layers 205–208.

Those producers have very different, non-deterministic load times:

| Producer | Typical latency on Take |
|----------|-------------------------|
| DeckLink / `dshow://` camera | Already live (~0) |
| PNG / still | Fast decode |
| FFmpeg clip | Open + decode first frames |
| HTML / CEF template | Slowest — load, JS, settle animation |

The wipe motion is a fixed ~2.5s; HTML settles whenever CEF finishes. Result: **elements
pop in mid-wipe** (operators report DoubleBox graphics last). That is two independent
clocks overlapping, not a Caspar bug.

## Decision

Treat story-block wipes as **definite transitions between pre-built scenes**, not as
overlays racing layer loads on PGM:

```text
BG channel A ──Builds doublebox scene──┐
                                       ├──► PGM channel (route + wipe transition)
BG channel B ──Builds fullscreen scene─┘
                                              │
                                              ▼
                                    Persistent overlay layer
                                    (Logo/bug — untouched by the wipe)
```

![Pre-build BG channels → PGM route+wipe → persistent overlay](../integration/wipe-prebuild-bg-channels.png)

1. **Background channels** (no SDI/Screen consumers required) continuously composite the
   *current* and *next* story looks (DoubleBox vs fullscreen SYN/weather/etc.).
2. **PGM** routes already-rendered BG channels and runs the wipe as a per-file alpha
   overlay by default. The optional experimental STING mode wraps the incoming full-channel
   route in a Caspar transition for the classical wipe only.
3. **Persistent overlays** (logo-bug, optionally long-lived L3Ds that must survive the wipe)
   sit on **PGM layers above the routed bus**, never baked into both BG composites.

This is the standard broadcast “build off-air, then punch up” pattern (preview bus /
CG pre-render). Caspar’s transition producer wraps generic producers including
`route://`; asset loading moves **before** the deterministic wipe.

## Consequences

### Positive

- Wipe no longer races CEF / clip cue — pop-in during transition goes away **when** the
  next BG channel is gated ready before the route transition starts.
- One **mandatory** readiness gate per wiped Take: “has the next BG channel settled?”
  instead of coordinating N layers mid-wipe.
- Logo/bug (and similar) survive untouched if kept above the route layer.

### Costs / risks

- **Idle GPU/CPU:** 2–3 channels render full composites continuously (BG A, BG B, PGM).
  No extra *consumers* on BG channels — only render cost. Measure headroom at production
  resolution before locking channel count.
- **Lookahead + ready gate:** Sofie must schedule next-BG build before Take **and** must
  not start the PGM route transition until that BG is settled (playing / CG loaded or
  equivalent). Fixed preroll alone may still punch up **partial** content if CEF/clip
  cue overruns the timer.
- **Mapping churn:** hypercomposed studio gains BG channel ids; DoubleBox FILL/L3D
  targets move from PGM layers to BG channel layers; default wipe overlays move to 205–208.
  The optional classical STING path uses route layer 111 and its mask/overlay media.

### Non-goals (this ADR)

- Changing LED channel 1 allow-list (`bg_loop` + headline ILU).
- Replacing hard cuts (ILU→SYN without wipe in smoke) — those stay cuts unless a wipe
  piece is present.
- Vision-mixer program cuts — still Caspar-only hypercompose.

## Implementation sketch

Canonical handoff for blueprints work:
[`docs/integration/handoffs/blueprints-wipe-route-bg-channels.md`](../integration/handoffs/blueprints-wipe-route-bg-channels.md).

Suggested default channel map (overridable in studio config):

| Role | Default Caspar channel | Consumers |
|------|------------------------:|-----------|
| LED | 1 | Screen / NDI / SDI |
| PGM | 2 | Screen / NDI / SDI |
| BG A (e.g. DoubleBox look) | 3 | none (render only) |
| BG B (e.g. fullscreen look) | 4 | none (render only) |

PGM layer stack (conceptual):

```text
210  Intro / outro (may stay PGM-local or move later)
123  logo-bug / persistent overlays   ◄── above wipe
205–208 per-file alpha wipe overlays (default)
110  route A — always-live route://N (default)
111  route B / canonical route — always-live by default; optional classical STING transition
```

BG A/B reuse today’s DoubleBox / fullscreen layer geometry (110/115/116/118/121), but
addressed on channels 3/4.

## Alternatives considered

1. **Keep overlay wipe on PGM 200; add long preroll on HTML/clips** — still races if Take
   is early; doesn’t guarantee CEF settle before wipe midpoint.
2. **Stinger that covers load** — hides pop-in but still rebuilds under the cover; worse
   for mid-wipe reveals and doesn’t fix asymmetric load.
3. **Second Caspar server** — unnecessary; one server already hosts multiple channels.

## References

- Current topology: [`OUTPUT_TOPOLOGY.md`](../integration/OUTPUT_TOPOLOGY.md)
- Durable ch/layer inventory: [`CASPAR-DURABLE-LAYER-MAP.md`](../integration/CASPAR-DURABLE-LAYER-MAP.md)
- DoubleBox / wipe labels today: [`DOUBLEBOX-PGM.md`](../integration/DOUBLEBOX-PGM.md)
- Buffer notes when compositing HTML+cam on one channel: [`CASPAR-FFMPEG-BUFFERS.md`](../integration/CASPAR-FFMPEG-BUFFERS.md)
