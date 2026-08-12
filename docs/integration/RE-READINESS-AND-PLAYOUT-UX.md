# Rundown Editor UX: readiness, duration, wipes, piece order

Planning notes for a follow-up session (Ready/NR + file length + wipe/order control).
Status as of 2026-08-05 after DoubleBox / flat-media / PGM L3D work.

## Mental model (what operators see)

| Surface | What it means today |
|---------|---------------------|
| RE piece list **NR** badge | Local ingest-root `fs.stat` (and Core PM when available) says a media field is missing |
| RE piece **DUR** | Editorial on-air length (seconds) on the piece — **not** always source-file length |
| Sofie WebUI piece status | Package Manager / `PieceStatusCode` from Core |
| LED `bg_loop` | Baseline on Caspar **1-110**. An optional RE `bg-loop` piece plays the same (or alternate) file at **priority 1** and **overrides** the baseline — operators should keep only one active loop on LED, not two simultaneous loops |
| Camera A (`camNo: 1`) | Vision-mixer cut + optional Caspar **2-116** UVC when `pgmCameraProducer` is set |
| Wipe row | PGM **2-200** overlay; `start`/`duration` drive enable, list order does not |

---

## Ready / NOT READY (NR)

### Intended end-state (ADR 0001)

Canonical design: [`docs/adr/0001-re-readiness-from-core-package-manager.md`](../adr/0001-re-readiness-from-core-package-manager.md).

- **Authoritative source:** Sofie Core Package Manager statuses (`PieceStatusCode`), same signal Sofie WebUI uses.
- **RE role:** Peripheral device reads Core via a device-scoped API
  (`peripheralDevice.packageManager.getContentStatusForRundown`), maps to badges.
- **Fallback:** Keep local `fs.stat` when Core/PM is down (hybrid mode).
- **Status of ADR:** **Implemented** (sofie-core `dfc25cc`/`581076c`, unopus
  `40b5d0b` — see the ADR's Implementation section for PR links). What's still
  open is operator-visible diagnostics when the hybrid path silently falls back
  — see [`handoffs/re-readiness-diagnostics.md`](handoffs/re-readiness-diagnostics.md).

### What ships today (unopus)

| Piece | Implementation |
|-------|----------------|
| Backend | `backend/src/background/mediaReadiness.ts` — walks piece types with `mediaPick` / `iluFile`, stats files under `ingestMediaRoot` |
| API | `GET /api/rundowns/:id/readiness` (≈10s poll from UI) |
| UI | `readinessBadge.tsx` → compact **NR** / full **NOT READY**; tooltips from requirement messages |
| Scope | Per media *field* (e.g. `payload.fileName`, `payload.iluFile`), rolled up to piece → part → sidebar |

**Why NR appears on ILU / wipe pieces even when Caspar playout works:**

1. RE may not see the same tree as Windows Caspar / Package Manager
   (`ingestMediaRoot` mismatch, missing SMB, or path with/without `clips/`).
2. Wipe / ILU files may exist for Caspar under `sofie-demo-media/` but not under the
   path RE is configured to scan.
3. Core PM status is preferred when the hybrid path is live (ADR 0001 is
   implemented — see above), but RE has no visible way today to tell whether a
   given badge came from Core PM or the local fs fallback, or why the Core call
   failed if it did — disagreement between Sofie UI and RE badges can still
   happen and is currently silent. See
   [`handoffs/re-readiness-diagnostics.md`](handoffs/re-readiness-diagnostics.md).

**Why Sofie WebUI says “Titles / Lower Third can't be found…” while Take still plays:**

The notification title is the **piece name** (e.g. `gfx/headline | …, clips/HEADLINE1.mov`
or `Intro | assets/intro_michal`); the body uses the Sofie **source layer name**
(`Titles`, `Lower Third`) — not a `gfx/` vs `pgm/` folder category.

Status comes from Package Manager ExpectedPackage verify against the Caspar media
folder (`LOCAL_FOLDER`), **not** from whether the last AMCP `PLAY`/`CG ADD`
succeeded. Common false-positive causes:

| Case | Plays | Warns | Why |
|------|-------|-------|-----|
| Intro / wipe / loop path without extension (`assets/intro_michal`) | Caspar resolves `.mov` | Yes (`Titles` / effects layer) | PM looked up the extensionless path; blueprints now map those to `.mov` via `toPackageManagerPath` |
| Headline ILU (`clips/HEADLINE1.mov`) + L3D HTML (`gfx/l3d-headline`) on one GFX track | Both can play | Usually only the **ILU** piece | Only ILU emits an ExpectedPackage; HTML templates are not media packages |
| HEADLINE3 “won’t PLAY” while 1–2 do (Caspar never gets `PLAY … HEADLINE3`) | File exists | Sofie omitted ILU AMCP | **Bug (fixed in blueprints):** ILU + `l3d-headline` both used Sofie source layer `Lower Third` at start=0; Core `processAndPrune` keeps only one WithinPart piece per source layer (winner by piece `_id`). PGM L3Ds now use source layer `lower_third_pgm` |
| PM down / wrong `casparcgMediaFolder` / no status row yet | Caspar already has files | All ExpectedPackage pieces | Same “can't be found on the playout system” string |

Sofie output rows in the rundown view are **`GFX`** and **`PGM`** (plus Script/Aux).
Many RE piece types (`ILU`, `L3DH`, `L3DT`, camera, wipe, intro, …) collapse onto
those two tracks via source layers (Lower Third / Logo / Titles / Camera / VT / …).

**WebM sibling check** for ILU was removed (prerendered/bypass ILU work); readiness no
longer requires a `.webm` next to the MP4.

### Planning questions for UX

- Should NR mean “missing on Caspar host” only (Core PM), never local Docker fs?
- Badge granularity: per field vs one badge per piece vs per story?
- Empty wipe `fileName` / defaulted `wipes/wipe` — ready if default resolves?
- How to show “copying…” vs “missing” (PM has richer states than ready/not-ready)?

---

## File length / duration reporting

Three different durations exist; conflating them caused operator confusion.

| Field | Unit | Meaning | Who sets it |
|-------|------|---------|-------------|
| Piece **Duration** (RE form / DUR column) | seconds | On-air / enable length for Sofie `expectedDuration` & timeline enable | Editor (manual or ffprobe fill) |
| `payload.sourceDuration` | milliseconds | Source clip length for Sofie VT/VO `content.sourceDuration` | Media picker ffprobe (`backend/.../media.ts`) |
| Part **Duration** | seconds | Part-level expected length (ILU inherit for headline/L3DH) | Editor / presets |

**Picker behaviour (today):** choosing a file via media picker runs ffprobe and can fill
piece duration (seconds) **and** `sourceDuration` (ms). Operators can still override
Duration for editorial timing (e.g. headline ILU = 8s while source is longer).

**Not shown today:** source length as a separate DUR column; Sofie’s hoverscrub /
Package Manager media info in RE.

### Planning questions

- Show two columns: **On air** vs **Source**?
- Auto-fill on-air from source only for VT/SYN, never for GFX/wipe?
- Should wipe DUR default to blueprint `DEFAULT_WIPE_DURATION_MS` (2500) in the RE form
  when left empty, so the column isn’t `00:00` while playout still fires 2.5s?

---

## Wipes: if / when they play

### Playout contract (blueprints)

- Piece type `wipe` → Caspar PGM layer **200** (`casparcg_effects_player_pgm`).
- Timeline enable after ingest (`convertIngestData` scales RE seconds → ms):
  - `start = piece.start * 1000` (seconds → ms; missing start → `0`)
  - `duration = piece.duration * 1000` when `piece.duration > 0`
  - `duration = DEFAULT_WIPE_DURATION_MS` (**2500**) when duration is empty/`0`
- Lifespan: WithinPart — fires on Take into that part.
- File: `payload.fileName` (Caspar path, no extension), default `wipes/wipe`.

### What RE does / doesn’t control

| Control | Today |
|---------|-------|
| Which part gets a wipe | Add wipe piece on that part (smoke does this on story Takes) |
| When within the part | Piece **Start** (offset from Take) — UI exposes it; often left at `00:00` |
| How long | Piece **Duration** (seconds). Non-zero → timeline `duration = piece.duration * 1000` ms. Empty/`00:00` → blueprint `DEFAULT_WIPE_DURATION_MS` (**2500**), not shown as 2.5s in RE |
| Transition label | `payload.transition` (operator label only; same file plays) |
| List order vs other pieces | **Rank / list order ≠ timeline priority** for same start; all start at 0 play together |

**Why it feels uncontrollable:** wipes sit at the bottom of the list with Start/DUR `00:00`,
so it looks like “always on / never timed,” while playout still runs a short PGM overlay
on every Take into that part. Moving the wipe row up/down does not change Caspar order
relative to L3D/camera when starts are equal.

### Planning questions

- First-class “Transition on Take” toggle that creates/removes the wipe piece?
- Show effective wipe length when DUR empty (“default 2.5s”)?
- Separate Transitions section so wipes aren’t mixed with ILU/L3D/Cam rows?
- Drag-reorder that writes `start`/`rank` with sensible defaults?

---

## Piece / story order

- Segment → parts ordered by **part.rank**.
- Within a part, pieces ordered by **piece.rank** (and creation) in the Items table.
- Sofie timeline uses each piece’s **start** (+ blueprints priority on Caspar layers),
  not the visual list order, for simultaneous starts.
- Camera / ILU / L3D / wipe on one ILU story are concurrent layers (different Caspar
  layers), so “order” is mostly editorial readability unless starts differ.

### Planning questions

- Drag-and-drop that adjusts `start` for staggered reveals?
- Locked stack presets (ILU+L3D+Cam+Wipe) vs freeform pieces?
- Hide baseline LED loop from RE (correct — it’s blueprint baseline) but show a
  read-only “LED loop: always on” indicator so operators don’t hunt for a missing piece?

---

## Related production rules (for the same planning session)

| Rule | Implementation |
|------|----------------|
| LED always has `bg_loop` | Baseline `CasparCGClipPlayer1` prio 0; optional RE `bg-loop` **overrides** at prio 1 (one active loop, not two). Editorial VT/VO/SYN on **PGM ClipPlayer2** when hypercomposed so they never steal 1-110 |
| LED graphics allow-list | Headline ILU (+ HTML) on LED; `l3d-tema` / `l3d-syn` / `l3d-headline` / `l3d-mod` on **PGM** |
| Camera visibility | Include/exclude `camera` piece (`camNo: 1` = Camera A). With `pgmCameraProducer` set → `PLAY 2-116 "dshow://…"`. No camera piece → no UVC on that Take |
| Intro | PGM layer 210; never LED |

See also: [`DOUBLEBOX-PGM.md`](./DOUBLEBOX-PGM.md), [`SPRAVY-V2-INTEGRATION.md`](./SPRAVY-V2-INTEGRATION.md), ADR 0001.
