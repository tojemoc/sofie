# Caspar durable channel / layer map

Canonical inventory of every durable Sofie → CasparCG address used by
hypercomposed SPRÁVY / 360 sekúnd. Topology:
[`OUTPUT_TOPOLOGY.md`](./OUTPUT_TOPOLOGY.md). DoubleBox / switching mechanics:
[`DOUBLEBOX-PGM.md`](./DOUBLEBOX-PGM.md).

**Code truth:** `blueprints/packages/blueprints/src/base/studio/applyConfig/mappings/casparcg.ts`
(`getCasparCGMappings`) + `casparcgLayers.ts` (`LedChannelLayers`,
`BgChannelLayers`, `PgmChannelLayers`) + showstyle helpers.

AMCP address = `{channel}-{layer}` (e.g. `PLAY 2-120 "clips/x"`). MEDIA paths are
extensionless under Caspar `media-path`; HTML templates under `template-path`
as `gfx/<name>`.

Two topologies exist — **vMix** (current: LED 1, look A 2, look B 3, clean GFX 4)
and **legacy Caspar-switched** (LED 1, PGM 2, look A 3, look B 4, CAM ingest 5).
Studio config `casparcg.hypercomposed.*` may remap channel numbers; layer numbers
are stable.

---

## Channel 1 — LED (both modes)

| Layer | Mapping id | Payload | When |
|------:|------------|---------|------|
| 80 | `casparcg_audio_bed` | `loops/bg_music_{a\|c}` LOOP + `assets/headline_sfx` hits | Baseline/segment beds; headline Take stings |
| 100 | `casparcg_clip_player_preview` | — | Softie preview only |
| 110 | `casparcg_clip_player1` | `loops/bg_loop` LOOP | Always (baseline) |
| 112 | `casparcg_led_pod_headline` | `assets/pod_headline` | Headlines segment |
| 114 | `casparcg_led_testframe` | `assets/testframe` | Pre-first-Take calibration |
| 115 | `casparcg_ilu_player` | `clips/<headline>` / `clips/<zaver>` | Headline ILU; ilu-zaver avízo (PRELOAD lookahead so the Take is hot) |
| 120–122 | `casparcg_graphics_ticker` / `_strap` / `_l3d` | — | Legacy; only `121 gfx/headline-fallback` chrome used |
| 123 | `casparcg_graphics_logo` (LED) | — | Deprecated — logo is PGM 123 |
| 200 | `casparcg_effects_player` | — | **Do not use** (legacy KEYER bug) |
| 990 | `casparcg_debug_label_led` | — | Optional burn-in |

**LED must not carry:** wipe, intro/outro, `l3d-*`, logo-bug, camera, story SYN.

```text
990 debug      200 legacy   121 fallback chrome   115 ILU   114 testframe
112 pod        110 bg_loop  100 preview            80 bed
```

---

## Channels 2 / 3 — Look A / B (vMix)

Render-only feeds into vMix look inputs. Same layers both channels; B uses `*_b`.

| Layer | Mapping id (A / B) | Payload | Notes |
|------:|---------------------|---------|-------|
| 110 | `casparcg_look_bg_loop` / `_b` | `loops/bg_loop` LOOP | Sticky underlay — never CLEAR (shows through transparent cam pane) |
| 115 | `casparcg_pgm_camera` / `_b` | `route://` or EMPTY | Legacy cam producer slot; vMix composes cam on the look input |
| 116 | `casparcg_pgm_ilu_player` / `_b` | `clips/<ilu>` (`doublebox-ilu`), `assets/bg_pocasie` | Story ILU / weather map — below db_loop |
| 117 | `casparcg_look_calib_cam` (B) | `route://` | Pre-first-Take calibration CAM |
| 118 | `casparcg_pgm_doublebox_loop` / `_b` | `loops/db_loop` LOOP | Phase-locked — see below |
| 119 | `casparcg_look_calib_frame` (B) | `loops/db_loop` | Pre-first-Take calibration frame |
| 120 | `casparcg_clip_player2` / `_b` | `clips/<syn/vt>` | **vMix clip layer** — above db_loop (opaque clip covers the frame where they overlap; DoubleBox clips are FILL-windowed inside it, so no overlap) |
| 121 | `casparcg_graphics_pgm_l3d` / `_b` | `CG ADD 1 "gfx/l3d-*"` / `gfx/pocasie` | Story L3Ds |
| 990 | `casparcg_debug_label_{a,b}` | — | Optional |

Look compose layers use lookahead **NONE** — PRELOAD would replace on-air
producers under the wipe.

```text
990 debug   121 L3D   120 SYN/VT clip   119 calib frame   118 db_loop
117 calib cam   116 ILU/bg_pocasie   115 cam   110 bg_loop
```

### db_loop phase-lock (vMix)

`loops/db_loop` is never EMPTY/paused on 118 — only opacity changes:

- DoubleBox part **claims** its slot at Take: `MIXER {ch}-118 OPACITY 1` at start 0.
- Its other slot reveals at the **offAirMs** of the outgoing part (frame stays up
  while that channel is off-air).
- A non-frame look part re-asserts `OPACITY 0` on **its own** claimed slot
  (`*_db_loop_hold` piece) so a stale reveal can't linger on air.
- The **idle preview** (`armIdleLookPreviewForNext`, runtime `onSetAsNext`) pushes
  `OPACITY 1` on the idle slot when the next part owns the frame — the off-air
  channel is dressed through prep, and the Take diffs to zero AMCP.

### Idle preview arm (runtime)

A dormant `look_idle_preview` piece sits on every playable part. At `onSetAsNext`
it arms `offAirMs + 1500` ms clones of the **next** part's real look media on the
idle channel: clip/ILU `playing:false` + `volume:0`, the vMix INPUT clone, the
db_loop reveal above, and a warm `gfx/pocasie` template with empty data (CEF
preload so the Take is a CG UPDATE, not a cold re-ADD). Clears it would cover are
moved from `offAirMs` to the same point; originals are stashed on the piece and
restored on re-arm/re-next.

---

## Channel 4 — PGM / clean GFX (vMix)

Feeds vMix `cleanGfxInput` keyed on Overlay 1. Only persistent overlays here —
no routes, no wipes, no cam.

| Layer | Mapping id | Payload | When |
|------:|------------|---------|------|
| 80 | `casparcg_audio_bed_pgm` | `loops/bg_music_{a\|c}` | PGM-side bed mirror |
| 121 | `casparcg_graphics_headline` | `gfx/l3d-headline`, `gfx/l3d-mod` | Headline L3Ds + MOD nameplate (clean GFX) |
| 122 | — | — | Declared (`PgmChannelLayers.GraphicsLowerThirdB`), never mapped |
| 123 | `casparcg_graphics_logo` | `assets/countup` LOOP + opacity | Logo/countup — above everything |
| 210 | `casparcg_intro_player_pgm` | `assets/intro_*`, `assets/outro` | Intro/znelka/outro — never LED |
| 990 | `casparcg_debug_label_pgm` | — | Optional |

---

## vMix objects (not Caspar)

vMix switching is TSR objects on `VMixLayers` mappings, not AMCP:

| Object | Purpose |
|--------|---------|
| `vmix_me_program` | One per Take — look input or raw `cameraInput` |
| `vmix_me_preview` | Lead PREVIEW before stingers (Stinger1–4 ignore transition input) |
| `vmix_look_input_{a,b}` | Look input layer config (cam layer 1, feed layer 2) |
| `vmix_look_input_{a,b}_audio` | Look input mute/unmute to buses `M,A` |
| `vmix_bed_{a,c}` / `*_audio` | Kolíska beds as vMix inputs |
| `vmix_overlay_graphics` | Overlay 1 = clean GFX feed |
| `vmix_mic_audio` | Moderator mic ramp-down during wipes/SYN |
| `vmix_recording` | PGM record control |

Stingers: `wipe`→Stinger1, `wipe_sjv`→Stinger2, `wipe_sport`→Stinger3,
`wipe_pocasie`→Stinger4 (`vmixStingerForWipeFile`). Stinger transition
`duration` = wipe duration; `wipe_pocasie` is capped at its real 2000 ms.

---

## Legacy channels (Caspar-switched mode only)

### Channel 2 — PGM (legacy)

| Layer | Mapping id | Payload |
|------:|------------|---------|
| 80 | `casparcg_audio_bed_pgm` | bed mirror |
| 110 / 111 | `casparcg_pgm_route_a` / `casparcg_pgm_route` | `route://3` / `route://4` always-live, MIXER cut |
| 123 | `casparcg_graphics_logo` | `assets/countup` |
| 205–208 | `casparcg_effects_player_pgm{,_sjv,_sport,_pocasie}` | `wipes/wipe*` — one layer per file so PRELOAD can't evict |
| 210 | `casparcg_intro_player_pgm` | `assets/intro_*` / `assets/outro` |

### Channels 3 / 4 — looks (legacy)

Same as vMix look stack except clip is layer **111** (`BgChannelLayers.ClipPlayer`,
below CAM) not 120.

### Channel 5 — CAM ingest (legacy)

| Layer | Mapping id | Payload |
|------:|------------|---------|
| 10 | `casparcg_pgm_camera_ingest` | `PLAY 5-10 DECKLINK DEVICE 1 FORMAT 1080P5000` / `dshow://` |

Opened once; looks sample via `PLAY {3|4}-115 route://5`. Never a second
`PLAY … DECKLINK` — the dual-open fails `EnableVideoInput`.

---

## Durable media inventory

| PLAY path | Channels / layers | Role |
|-----------|-------------------|------|
| `loops/bg_loop` | 1-110 always; look 110 sticky | Baseline underlay |
| `loops/db_loop` | look 118 | DoubleBox alpha frame (aka `dp_loop` on disk) |
| `loops/bg_music_{a,c}` | 1-80 (+ 2/4-80 legacy) | Kolíska beds (a=main, c=Šport) |
| `wipes/wipe{,_sjv,_sport,_pocasie}` | legacy PGM 205–208 | Alpha wipe overlays (vMix uses stingers instead) |
| `assets/pod_headline` | 1-112 | Headline pod underlay |
| `assets/headline_sfx` | 1-80 / PGM 80 | Headline sting hit |
| `assets/testframe` | 1-114 | Pre-first-Take calibration |
| `assets/countup` | PGM 123 | Logo + countup |
| `assets/intro_*` / `assets/outro` | PGM 210 | Znelka / outro overlays |
| `assets/bg_pocasie` | look 116 | Weather map under `gfx/pocasie` |
| `clips/*` | LED 115 (headline/zaver); look 116 (ILU); look 120/111 (SYN/VT) | Rundown-specific |

## Durable HTML templates (CG `ADD 1 "gfx/<name>"`)

| Template | Look | Role |
|----------|------|------|
| `gfx/l3d-headline` | clean-GFX 4-121 | Headline bars |
| `gfx/l3d-tema` | look 121 | Topic line |
| `gfx/l3d-syn` | look 121 | SYN name/role strap |
| `gfx/l3d-mod` | clean-GFX 4-121 | Presenter MOD nameplate |
| `gfx/l3d-sjv` / `gfx/l3d-sport` | look 121 | SJV / Šport bars |
| `gfx/l3d-odporucanie` | look 121 | End tip |
| `gfx/pocasie` | look 121 | Weather HTML (warm-loads via idle preview) |
| `gfx/headline-fallback` | LED 121 (optional) | ILU chrome only |
| `gfx/outro` / `gfx/logo-bug` / `gfx/source` | PGM | Overlays |

---

## Example vMix Take (DoubleBox on look B)

```text
PLAY   3-118 "loops/db_loop" LOOP                 ← claimed slot, MIXER OPACITY 1
LOADBG 3-120 "clips/syn_x"  (playing:false)       ← idle preview armed earlier
CG     3-121 ADD 1 "gfx/l3d-tema" 1 {…}
(vmix) PROGRAM input 3 Stinger1 + lead PREVIEW    ← stinger airs input 3
MIXER  2-118 OPACITY 1                            ← other slot revealed at offAir
```

No `wipes/` PLAYs, no `route://` PGM layers — vMix owns the transition.

## Related

| Doc | Role |
|-----|------|
| [`OUTPUT_TOPOLOGY.md`](./OUTPUT_TOPOLOGY.md) | Topology + ops `caspar.config` |
| [`DOUBLEBOX-PGM.md`](./DOUBLEBOX-PGM.md) | Compose geometry, cam, phase-lock detail |
| [`SPRAVY-SHOW-FLOW.md`](./SPRAVY-SHOW-FLOW.md) | Show spine |
