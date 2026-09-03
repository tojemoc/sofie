# Handoff: Wipe via pre-built BG channels + PGM `route://` transition

Copy this into a Cursor agent session on **`tojemoc/sofie-demo-blueprints`**.
Architecture decision: megarepo
[`docs/adr/0002-wipe-prebuild-bg-channels.md`](../../adr/0002-wipe-prebuild-bg-channels.md).

## Goal

Stop racing wipe vs HTML/clip load on PGM. Pre-compose the **outgoing** and **incoming**
story looks on background Caspar channels; on Take with a wipe, PGM only **routes** the
settled composite and runs the wipe as a transition. Logo-bug (and similar) stay on PGM
**above** the routed layer so they are not wiped away.

```text
BG A (doublebox) ──┐
                   ├──► PGM: route + wipe transition ──► persistent overlay (logo/bug)
BG B (fullscreen) ─┘
```

Sketch (megarepo): `docs/integration/wipe-prebuild-bg-channels.png`.

## Why (operator symptom)

DoubleBox HTML is last to appear mid-wipe because CEF load is slower than DeckLink /
images / many clips. Overlay wipe on PGM 200 does not wait for those producers.

## Target channel map

Extend hypercomposed studio (keep LED=1, PGM=2):

| Config key (proposed) | Default | Role |
|-----------------------|--------:|------|
| `casparcg.hypercomposed.ledChannel` | 1 | unchanged |
| `casparcg.hypercomposed.pgmChannel` | 2 | route bus + persistent overlays |
| `casparcg.hypercomposed.bgChannelA` | 3 | pre-build look A (e.g. DoubleBox) |
| `casparcg.hypercomposed.bgChannelB` | 4 | pre-build look B (e.g. fullscreen SYN/VT) |

BG channels: **no Screen/NDI/SDI consumers** in `caspar.config` (render only).

### Layer ownership after change

**BG A / BG B** (same relative layers as today’s PGM compose, per look):

| Layer | DoubleBox look (typical A) | Fullscreen look (typical B) |
|------:|----------------------------|-----------------------------|
| 110 | — / clear | SYN / VT / weather clip |
| 115 | CAM FILL (DoubleBox) | CAM fullscreen or clear |
| 116 | `doublebox-ilu` | clear |
| 118 | `db_loop` | clear |
| 121 | topic L3Ds that belong *inside* the wiped scene | SYN L3D if it should wipe with scene |

**PGM:**

| Layer | Content |
|------:|---------|
| 110 (or dedicated route layer) | `route://{bg}` (full BG channel composite) + wipe transition |
| 123 | `gfx/logo-bug` — **always above route** |
| 210 | Intro / outro — decide: PGM-local (above wipe) vs own path; keep above route |

**Remove / stop using for story wipes:** treating `casparcg_effects_player_pgm` (200) as a
standalone alpha overlay that plays *while* other PGM layers cold-start. Keep mapping for
compat if needed, but story-block wipe pieces should drive the **route transition**.

## Sofie / timeline requirements

1. **Lookahead:** before a wiped Take into part N, the *next* BG channel must already
   hold part N’s composite. Use piece `prerollDuration` / part prepare, or a sticky
   “next look” baseline that updates on the upcoming part while current is on-air.
   Preroll alone is **not** the readiness gate (see below).
2. **Ping-pong:** while PGM routes from A, build next look on B; after Take, swap. Do not
   rebuild the on-air BG channel under the route.
3. **Ready gate (required for no-pop-in):** do **not** start the PGM route transition
   until the next BG channel reports settled (layers playing / CG loaded, or an
   equivalent Sofie readiness signal). Fixed preroll without that signal can still punch
   up a partially loaded composite. Gate Take or auto-delay the wipe until ready.
4. **Hard cuts:** parts without a wipe piece keep today’s cut semantics (instant route
   switch or continue building on PGM if not yet migrated).

## Blueprint work packages

### WP1 — Studio mappings + config

- Add `bgChannelA` / `bgChannelB` to hypercomposed studio config schema + `applyConfig`
  Caspar mappings (mirror today’s PGM camera/ILU/db_loop/L3D layer defs onto BG channels).
- Add PGM route layer mapping (TSR Caspar media/route content).
- Document `caspar.config` channel count (≥4) for ops.

### WP2 — Scene builders

- Factor “emit DoubleBox stack” / “emit fullscreen stack” helpers so they target a
  **channel parameter** (BG A/B), not hard-coded PGM.
- Part adapters (DoubleBox, VO/SYN, weather, …) schedule **next** look onto the idle BG
  channel with preroll; keep **current** look on the routed channel.

### WP3 — Wipe = route transition

- Wipe piece / `playLayer: 'wipe'`: the **route transition from the next BG replaces**
  overlay-only `PLAY` of wipe media on PGM layer **200**. One Take must not fire both a
  route wipe and a layer-200 overlay (that would be two wipes). Generate timeline that:
  - ensures next BG is built **and ready**,
  - `PLAY` PGM `route://{bg}` from next BG **with** transition (wipe media / MIXER
    TRANSITION as supported by your Caspar build),
  - leaves logo on 123 untouched.
- Retain PGM layer **200** only for explicitly **non-migrated** compatibility paths
  (legacy overlay wipe while a look still cold-starts on PGM). Migrated story-block
  wipes must not use 200.
- Preserve RE labels (`ILU TO SYN`, `Double Box`, …) as operator metadata; map labelled
  wipe files (`wipes/wipe_sjv`, …) into the route transition where applicable.

### WP4 — Tests + smoke

- Unit: mappings for ch3/ch4; wipe timeline contains `route://{bg}` + transition, and
  does **not** also PLAY overlay wipe on 200 for the same Take.
- Extend smoke expectations: wiped Takes do not cold-start HTML on the routed channel at
  transition start; transition waits for BG ready.
- Manual: Take DoubleBox → SYN with wipe — L3D/db_loop must not pop mid-wipe; logo-bug
  continuous.

## Out of scope

- LED topology changes.
- Rewriting all RE piece types.
- Measuring GPU headroom (ops / Ondro on studio box) — flag if 4 channels @ 1080p50 hurt.

## Verify

1. `yarn test:blueprints` / wipe + DoubleBox specs updated.
2. Caspar log on wiped Take: route/transition on PGM; CG ADD for next look appeared on BG
   channel **and** ready gate passed **before** transition start (timestamps); no parallel
   `PLAY … 2-200` wipe for that Take.
3. Operator check: no mid-wipe pop-in of DoubleBox HTML; logo stays up.

## References

- ADR: [`docs/adr/0002-wipe-prebuild-bg-channels.md`](../../adr/0002-wipe-prebuild-bg-channels.md)
- Today: `OUTPUT_TOPOLOGY.md`, `DOUBLEBOX-PGM.md`, `helpers/clips.ts` wipe path,
  `CasparCGPgmEffectsPlayer`
