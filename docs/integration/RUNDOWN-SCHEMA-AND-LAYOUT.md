# Rundown schema and layout — how a story gets to air

End-to-end map of the data model from the Rundown Editor to CasparCG. Read this
before touching ingest payloads, piece types, or timing.

## The five layers

```
Rundown Editor (unopus)                Sofie Core                       Playout
┌─────────────────────┐   ingest DDP   ┌──────────────────┐   TSR     ┌──────────┐
│ SQLite JSON docs    │ ─────────────► │ Rundown/Segment/ │ ────────► │ CasparCG │
│ rundowns            │  dataRundown   │  Part/Piece      │ timeline  │ (vMix)   │
│ segments/parts/     │  Create/Update │  + Blueprint     │ objects   │          │
│ pieces/typeManifests│                │  bundle output   │           │          │
└─────────────────────┘                └──────────────────┘           └──────────┘
```

| Layer | Shape | Id rule |
|-------|-------|---------|
| RE | `rundowns/segments/parts/pieces` tables; each row = id + `document` JSON blob | RE `id` == Sofie `externalId` (1:1, only for `sync=true`) |
| RE | `typeManifests` — piece/part/segment **type** definitions from megarepo `assets/` | PK `(id, entityType)` — `intro` exists as both part and piece type |
| Core ingest | `SofieIngest{Segment,Part}` with `payload` = RE-mutated doc | `externalId` is the join key everywhere |
| Blueprint | `PartProps` / `SegmentProps` intermediate → `BlueprintResult{Part,Piece}` | Part `type` decides adapter; pieces normalized to `objectType` |
| Playout | TSR `TimelineObject`s on Sofie layer ids → Caspar channels/layers | mapping tables in `casparcgLayers.ts` |

## RE → Core ingest payload (the contract)

RE calls `coreMethods.dataRundown{Create,Update,Delete}` /
`data{Segment,Part}{Create,Update,Delete}` with "mutated" documents
(`mutateRundown` in `backend/src/background/api/rundowns.ts`). The shared
sync predicate in both `sendRundownDiffToCore` and `playoutLockService`'s
SQL is **`document.sync` truthy AND `document.isTemplate` falsy** — a rundown
with no `isTemplate` field at all still syncs (absent counts as
not-a-template; only a truthy `isTemplate` excludes it). That same predicate
is what `playoutLockService` polls for on-air locks.

Piece/part fields as they cross the wire:

| RE field | → ingest | Units / notes |
|----------|----------|---------------|
| `start` | `piece.objectTime` | **seconds** → blueprints `× 1000` (ms) |
| `duration` | `piece.duration` | **seconds** → `× 1000` ms (`(d ?? 0) * 1000`); `0`/empty = open-ended for most pieces — **except `wipe`**, which falls back to blueprint `DEFAULT_WIPE_DURATION_MS` (2 500 ms stinger overlay), matching RE-READINESS' "~2.5 s" default |
| `pieceType` | `piece.objectType` | RE type id (`headline`, `l3d-syn`, `wipe`, `video`, `camera`, …) — **reused as a Sofie object-type discriminator, then overwritten** by the parser |
| `payload.*` | `piece.attributes.*` | passthrough bag; `adlib: true` marks adlibs |
| `attributes.cutPoint` | `attributes.cutPoint` | **already ms** (into the wipe file) — the one field NOT in seconds |
| `attributes.fileName` | `piece.clipName` | flat `clips/…`, `wipes/…`, `loops/…`, `assets/…` Caspar paths |
| `part.autoNext` | `part.autoNext` | boolean; only when `durationMode === 'auto'` |
| `part.duration` | `part.duration` | seconds → `part.expectedDuration` ms |

## Blueprint ingest → parts (dispatch)

`getSegment` → `convertIngestData` (`sofie-editor-parsers/index.ts`):

1. Segment type from `payload.type` (`opening|headlines|story|normal`), fallback name heuristic.
2. Per piece: `logo-bug` objectTypes are dropped (countup handles it); `Graphic`/`Video` get `clipName`; RE graphic type ids (`isRundownEditorGraphicPieceType`, 13 types) → `clipName = gfx/<type>` **except `weather` → `gfx/pocasie`**; layered video types (`intro|bg-loop|wipe|outro`) → `ObjectType.Video` + `playLayer`.
3. Part adapter picked by **regex on `part.type`**, in order: `doublebox|ilu` (camera if a cam piece exists, else gfx), `syn`→VO, `cam`, `dve`, `gfx`, `vo`, `^(vt|full|package|vid|sot|clip|video)$`→VT, then content fallbacks (main video→VT, layered only→LayeredVideo, else `invalid`).

Mutations happen **in place** on the ingest payload (`piece.objectType` is
overwritten from the RE type id to `graphic|video|camera`) — ingest payloads
are not immutable in this codebase.

Retired/legacy coercions: `l3d-predstavovak` → `l3d-syn` (`l3d-mod` in Opening
segments); `headline`+`iluFile` on a DoubleBox part → `doublebox-ilu`;
`spravy/<id>/clips/…` iluFile paths → flat `clips/<file>`.

## Layout: how a part becomes a look

`generateParts` (`part-adapters/index.ts`) assigns each part a physical
**look slot** (Caspar BG channel A=3 or B=4) by ping-ponging off the previous
claim (`lookSlots.claimIdle()`) so every Take composites on the idle channel;
editorial **kind** (`doublebox|full`) is independent of slot. Non-look parts
(Remote/Titles/DVE/Invalid), floats/skips, and parts with an outro overlay
peek but don't claim. Intro claims idle but overlays on PGM 210.

`finalizeHypercomposedPart` (`helpers/pgmLook.ts`, 2.6k lines — read before
editing) then rewrites the pieces: wipe overlays (205–208, one layer per wipe
file), `route://` PGM cuts at `airCutMs`, keepalives/postrolls for hard cuts,
L3D EMPTY→ADD offsets, idle-look preview arms, and the vMix-program variant of
all of the above. Every magic constant is documented in that file — the timing
budget (cover window, latency, leads/lags) is calibrated to a 1080p50 Caspar
and `wipe.mov` (cover = source frames 19–20 @25fps = 760–840 ms timeline).

`syncIngestUpdateToPartInstance` copies `autoNext`/`expectedDuration` from
re-ingested parts onto live PartInstances; Core (`fix/playout #41`) then marks
the timeline dirty so a stale auto-next boundary can't fire.

## Files that own each concern

| Concern | File |
|---------|------|
| RE piece/part/segment type manifests | megarepo `assets/sofie-rundown-editor-*.json` |
| Ingest TS types (copied — keep in sync) | `blueprints/src/code-copy/rundown-editor/index.ts` |
| Part-type dispatch + piece normalization | `…/sofie-editor-parsers/index.ts` |
| RE graphic/layered piece-type lists | `…/common/definitions/rundownEditorTypes.ts` |
| Look slot ping-pong, wipe/route timing | `…/helpers/pgmLook.ts` |
| Wipe constants + cutPoint/airCut math | `…/helpers/clips.ts` |
| Caspar layer numbers + mappings | `…/studio/applyConfig/mappings/casparcg*.ts` |
| On-air locks (RE) | `…/background/playoutLockService.ts` + `presence.ts` |
| Piece readiness (Core ↔ RE) | core `api/integration/rundownContentStatus.ts` ↔ RE `mediaReadiness.ts` |
| New Core peripheral APIs | core `api/integration/rundown{PlayoutState,PartSettings,PartAutoNext}.ts` |

Caspar channel/layer inventory: [`CASPAR-DURABLE-LAYER-MAP.md`](CASPAR-DURABLE-LAYER-MAP.md).
Show flow per block: [`SPRAVY-SHOW-FLOW.md`](SPRAVY-SHOW-FLOW.md).
