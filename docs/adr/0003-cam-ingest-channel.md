# ADR 0003: DeckLink / live CAM ingest on a dedicated Caspar channel

**Status:** Implemented in blueprints (`camIngestChannel`, default **5**).
**Date:** 2026-09-14
**Repos affected:** `tojemoc/sofie-demo-blueprints` (primary), Caspar `caspar.config`,
megarepo docs (`OUTPUT_TOPOLOGY`, `DOUBLEBOX-PGM`)
**Owner:** SPRÁVY playout

## Context

Hypercomposed SPRÁVY places story looks on BG channels **3** and **4**. Camera pieces
previously opened `pgmCameraProducer` (DeckLink / `dshow://`) directly on look layer
**115**. DeckLink (and a single Virtual Camera) can only `EnableVideoInput` / open capture
**once**. Baseline warm on `3-115` plus Full/headline Takes on `4-115` produced:

```text
PLAY 3-115 DECKLINK DEVICE 1 FORMAT 1080P5000   ← OK
…
PLAY 4-115 DECKLINK DEVICE 1 FORMAT 1080P5000   ← Could not enable video input
```

Fighting that with CLEAR/EMPTY races between looks is fragile under wipe keepalive.

The PC has headroom for another render-only channel.

## Decision

1. **Channel 5** (studio `casparcg.hypercomposed.camIngestChannel`, default **5**) is a
   render-only **CAM ingest** helper. Rundown baseline opens DeckLink / dshow **once**
   there (`casparcg_pgm_camera_ingest`, layer **10**).
2. Look A/B camera layers (`3-115` / `4-115`) PLAY MEDIA **`route://5`** (full channel)
   with the DoubleBox / fullscreen FILL — they never emit `DECKLINK` or `dshow://`.
3. `caspar.config` must declare **≥5** channels (channel 5 needs no consumer).

```text
CasparCG
├── 1 LED
├── 2 PGM          route://{3|4} + overlays
├── 3 DoubleBox    CAM = route://5 + FILL
├── 4 Full         CAM = route://5 + FILL
└── 5 CAM ingest   sole DECKLINK / dshow PLAY
```

## Consequences

### Positive

- One `EnableVideoInput` for the show; looks can both show CAM without fighting the card.
- Wipe pre-build on the idle look can include CAM via `route://5` without a second open.

### Costs

- Caspar must allocate a fifth 1080p50 channel (GPU/CPU). Measure headroom.
- Ops must extend `caspar.config` or Sofie `PLAY 5-…` / `route://5` returns **400**.

### Non-goals

- Changing LED allow-list or PGM route semantics.
- Using `route://5-10` unless a future need requires layer-scoped sampling (full-channel
  `route://5` is enough while ingest holds a single fullscreen producer).

## References

- Topology: [`OUTPUT_TOPOLOGY.md`](../integration/OUTPUT_TOPOLOGY.md)
- DoubleBox / DeckLink notes: [`DOUBLEBOX-PGM.md`](../integration/DOUBLEBOX-PGM.md)
- Wipe BG channels: [`0002-wipe-prebuild-bg-channels.md`](./0002-wipe-prebuild-bg-channels.md)
