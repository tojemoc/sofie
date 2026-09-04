# Handoff: Wipe via pre-built BG channels + PGM `route://` transition

**Status:** Implemented in **`tojemoc/sofie-demo-blueprints` [#77](https://github.com/tojemoc/sofie-demo-blueprints/pull/77)**
(merged). Use this doc for **ops verification** and follow-up hardening — not as a greenfield
build plan. Architecture: megarepo
[`docs/adr/0002-wipe-prebuild-bg-channels.md`](../../adr/0002-wipe-prebuild-bg-channels.md).

## Goal (shipped)

Stop racing wipe vs HTML/clip load on PGM. Pre-compose the **outgoing** and **incoming**
story looks on background Caspar channels; on Take with a wipe, PGM only **routes** the
settled composite and runs the wipe as a STING transition. Logo-bug stays on PGM
**above** the routed layer so it is not wiped away.

```text
BG A (doublebox) ──┐
                   ├──► PGM: route + wipe transition ──► persistent overlay (logo/bug)
BG B (fullscreen) ─┘
```

Sketch (megarepo): `docs/integration/wipe-prebuild-bg-channels.png`.

## CasparCG build (documented production)

| Item | Value |
|------|--------|
| Documented server line | **CasparCG 2.4.x** (see [`CASPAR-FFMPEG-BUFFERS.md`](../CASPAR-FFMPEG-BUFFERS.md) — stock 2.4.x + optional `dshow` `rtbufsize` patch) |
| Studio box | Windows playout host under `C:\casparcg\` (Package Manager `worker.exe` co-located) |
| Required channels | **≥4** in `caspar.config` (1 LED, 2 PGM, 3 BG A, 4 BG B; 3/4 render-only) |
| Route AMCP | `PLAY 2-110 route://{3\|4}` — **full channel** (`layer: null` in blueprints) |
| Wipe AMCP | STING on that route (`maskFile` / `overlayFile` = wipe media under `wipes/`) |

If a site runs a different Caspar build, record the exact version string from the Caspar
console banner here before signing off STING timing.

## Channel map (live defaults)

| Config key | Default | Role |
|------------|--------:|------|
| `casparcg.hypercomposed.ledChannel` | 1 | LED allow-list |
| `casparcg.hypercomposed.pgmChannel` | 2 | route bus + persistent overlays |
| `casparcg.hypercomposed.bgChannelA` | 3 | pre-build look A (e.g. DoubleBox) |
| `casparcg.hypercomposed.bgChannelB` | 4 | pre-build look B (e.g. fullscreen SYN/VT) |

### Layer ownership

**BG A / BG B** (same relative layers, per look):

| Layer | DoubleBox look (typical A) | Fullscreen look (typical B) |
|------:|----------------------------|-----------------------------|
| 110 | — / clear | SYN / VT / weather clip |
| 115 | CAM FILL (DoubleBox) | CAM fullscreen or clear |
| 116 | `doublebox-ilu` | clear |
| 118 | `db_loop` | clear |
| 121 | topic L3Ds inside the wiped scene | SYN L3D if it should wipe with scene |

**PGM:**

| Layer | Content |
|------:|---------|
| 110 | `route://{bg}` (full BG channel composite) + STING wipe transition |
| 123 | logo-bug / countup — **always above route** |
| 210 | Intro / outro — above route |

**Legacy only:** `casparcg_effects_player_pgm` (200) overlay wipe while a look still
cold-starts on PGM. Migrated story-block wipes must not use 200.

## Critical: full-channel route serialization (`layer: null`)

Full-channel PGM routes **must** serialize with **`layer: null`** (not omitted, not `0`).

| Mapping | Required | Forbidden |
|---------|----------|-----------|
| PGM full-channel route (`CasparCGPgmRoute` / both BG A and BG B targets) | `content.layer: null` → AMCP `route://N` | missing/`0` → `route://N-0` (empty layer → **black PGM**) |
| Non-full-channel mappings (clip/cam/ILU/L3D on a specific layer) | Keep explicit layer numbers (110/115/…) | Do not force `null` |

Blueprints reference: `packages/blueprints/src/base/showstyle/helpers/pgmLook.ts`
(`createPgmRouteTimelineObject` — comment documents the `route://N-0` failure mode).
Unit coverage: `pgmLook.spec.ts` asserts `layer: null` for routes to **both** BG channels.

### WP1 / WP4 checklist (post-merge hardening)

- **WP1:** Studio mappings keep BG A/B mirrors; PGM route mapping remains the only
  full-channel route producer. Re-validate after any TSR / casparcg-state upgrade that
  `layer: null` still emits `route://N` for channels **3 and 4**.
- **WP4:** Tests must cover:
  - route timeline objects for BG A **and** BG B both use `layer: null`;
  - wiped Take contains `route://{bg}` + STING and does **not** also PLAY overlay wipe on 200;
  - non-route pieces still use numeric layers (regression).

## Smoke test: `route://3` → `route://4`

Run on the studio box with ≥4 Caspar channels and a fresh blueprint bundle (#77+).

1. Activate smoke rundown; logo-bug on air (`PLAY 2-123 …`).
2. Take into a **DoubleBox** look so PGM shows `PLAY 2-110 route://3` (or whichever slot
   is A) — confirm AMCP is **`route://3`**, not `route://3-0`.
3. Take with a **wipe** into a **fullscreen SYN** look that ping-pongs to the other BG
   (`PLAY 2-110 route://4` + STING).
4. Pass criteria:
   - **No black frame** on PGM during the transition (rules out `route://N-0` and empty BG).
   - **No channel overlap** — only one of ch3/ch4 is the routed source; the idle BG may
     rebuild but must not fight the on-air route.
   - **Logo intact** — `2-123` keeps playing through the STING; bug does not blink off.
5. Capture Caspar log timestamps for the `PLAY 2-110 route://…` pair and any `2-200` (must
   be absent for that Take).

## Sofie / timeline reminders

1. **Lookahead / ready gate:** next BG must be settled before the route STING starts.
2. **Ping-pong:** while PGM routes from A, build next look on B; do not rebuild the on-air BG.
3. **Hard cuts:** parts without a wipe piece keep CUT route switch (still `layer: null`).

## Verify (commands)

1. `cd packages/blueprints && yarn test` — include `pgmLook` / wipe route specs.
2. Caspar log on wiped Take: `PLAY 2-110 route://{3|4}` with STING; CG ADD for next look on
   BG **before** transition; no parallel `PLAY … 2-200` wipe for that Take.
3. Operator: no mid-wipe pop-in of DoubleBox HTML; logo stays up; `route://3` → `route://4`
   smoke above passes.

## References

- ADR: [`docs/adr/0002-wipe-prebuild-bg-channels.md`](../../adr/0002-wipe-prebuild-bg-channels.md)
- Topology / ops XML: [`OUTPUT_TOPOLOGY.md`](../OUTPUT_TOPOLOGY.md)
- DoubleBox FILL + wipe labels: [`DOUBLEBOX-PGM.md`](../DOUBLEBOX-PGM.md)
- Buffers: [`CASPAR-FFMPEG-BUFFERS.md`](../CASPAR-FFMPEG-BUFFERS.md)
- Code: `helpers/pgmLook.ts`, `CasparCGPgmRoute`, wipe piece path in blueprints
