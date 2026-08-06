# Handoff: Rundown Editor — daily template clone + bulk rewrite + readiness-aware picker

**Copy everything below the line into a new Cursor agent session running in
`tojemoc/unopus`.**

---

## Your mission

Turn the existing manual "template rundown → copy" feature into the actual daily
production workflow: the canonical show (blueprints piece/part/segment types + the
`assets/spravy-v3-smoke-rundown.json` shape from the `tojemoc/sofie` megarepo +
`demo-assets` templates) already represents a 1:1 template of a real show. Editors want
that template **cloned automatically every day**, then a **fast way to rewrite only
what actually changes** — prompter text, L3D graphic names (`headline`/`subline`/
`tema`/etc.), and ILU/SYN media filenames — instead of re-authoring the whole rundown
or hunting through per-piece forms one at a time.

**Read this before writing any code — most of the plumbing already exists:**

- `Rundown.isTemplate` already exists (`backend/src/background/interfaces.ts`,
  used throughout `backend/src/background/api/rundowns.ts`).
- Cloning a whole template rundown already works:
  `mutations.createRundownCopy` in `backend/src/background/api/rundowns.ts` — clones
  segments/parts/pieces via `segmentsMutations.cloneFromRundownToRundown`, names the
  result with a date/time suffix (`getNewRundownName` with `fromTemplate: true`).
- Cloning individual template *segments* into an existing rundown already works too:
  `frontend/src/components/rundown/importSegmentModal/` (`ImportSegmentModal.tsx`,
  `templateRundownCard.tsx`) + `cloneSegmentsFromRundownToRundown` in
  `frontend/src/store/segments.ts`.
- The only thing genuinely missing is: (1) doing the whole-rundown clone **on a
  schedule instead of a manual button click**, (2) a **fast bulk-edit surface** for the
  handful of fields that change daily, and (3) making the media picker
  **readiness-aware** instead of a plain filesystem listing.

There is an earlier, abandoned attempt at "daily automation" on
`tojemoc/unopus` branch `backup` (Google Sheets pull/push adapters under
`backend/src/background/adapters/sheets/`) and in the archived `tojemoc/duopus` repo
(Google Sheets + Bitfocus Companion, driving vMix). **Do not resurrect either.** Both
model a spreadsheet-as-source-of-truth workflow built for vMix, which fights the
Sofie-centric architecture this project has since moved to (Core is the sync target,
RE is the ingest device, CasparCG is the playout target — no spreadsheet in the loop).
The only reusable idea from `backup` is the `ImportSegmentModal`/`TemplateRundownCard`
UX pattern, and that's already been ported forward into `main` — build on `main`
directly, don't diff against `backup`.

---

## What to build

### 1. Backend: scheduled daily clone

New file: `backend/src/background/dailyTemplateScheduler.ts`, started from
`backend/src/background/index.ts` (`ControlAPI.init`) alongside `coreHandler.init()`.

- No new dependency needed — a `setInterval` (~1 minute) that evaluates
  "should we generate?" is enough; don't require an exact `HH:mm` equality match
  (a delayed or skipped tick would miss the day). On each wake: compute today's
  `generatedDate` and current local `HH:mm` in `dailyCloneTimezone`; trigger when
  configured `dailyCloneTime` has already passed today and no
  `dailyGenerations` row exists for `(templateId, generatedDate,
  generatingTimezone)` with `status = 'completed'` (or a live
  `in_progress` reservation — see below). The absence of the day's marker for
  the **current** zone is the idempotency gate — not "did this exact minute fire."
  (If you'd rather have real cron syntax for future multi-schedule needs,
  `node-cron` is fine — still use the same "time passed + marker absent" rule.)
- **DST:** interpret wall-clock times with `Intl` / Temporal in
  `dailyCloneTimezone`. Nonexistent spring-forward gap (e.g. `02:30` on a day that
  jumps `02:00→03:00`): treat the trigger as already passed once local time is at
  or after the first valid instant after the gap (run after the gap, same
  `generatedDate`). Repeated fall-back fold (e.g. `02:30` occurs twice): fire at
  most once — the first wall-clock occurrence that satisfies "time has passed"
  for that `generatedDate`; the `dailyGenerations` primary key prevents a second
  run on the repeated hour.
- Settings (extend `ApplicationSettings` in `interfaces.ts` + the settings form under
  `frontend/src/components/settings/`): `dailyTemplateRundownId` (which rundown is
  "today's template" — dropdown of rundowns where `isTemplate === true`),
  `dailyCloneTime` (`HH:mm` in `dailyCloneTimezone`), and `dailyCloneTimezone`
  (IANA, default `Europe/Bratislava`). Leave the feature inert if template id or
  clone time is unset.
- **Validate on settings save and load** (in `backend/src/background/api/settings.ts`
  `create`/`update`/`read` — today those paths do not validate new fields): reject
  `dailyCloneTime` unless it matches `^([01]\d|2[0-3]):[0-5]\d$`; reject
  `dailyCloneTimezone` unless `Intl.supportedValuesOf('timeZone')` includes it (or
  equivalent try/catch around `Intl.DateTimeFormat(..., { timeZone })`). When
  `dailyTemplateRundownId` is set (non-empty), load that rundown via the existing
  rundown read API and **reject** unless it exists **and** `isTemplate === true`
  (deleted ids and non-template rundowns must not persist). On rejection return a
  clear error and do not persist. Keep the documented `Europe/Bratislava` default
  when timezone is omitted; keep inert behavior when template id or clone time is
  unset (do not invent a default clone time). Re-run the same template-id check
  inside `generateDailyRundownIfNeeded` / the scheduler before cloning so a rundown
  deleted or un-templated after settings were saved cannot generate.
- On trigger: call the **existing** `mutations.createRundownCopy({ id:
  dailyTemplateRundownId, preserveTemplate: false })` — do not reimplement cloning.
- **Idempotency must be atomic at insertion time, not a check-then-act read.** A plain
  "does a rundown with this `sourceTemplateId` + `generatedDate` already exist?" read
  followed by a separate create is a race: the scheduler tick and a manual "Generate
  now" click (see #2) could both pass the check before either has inserted, producing
  two rundowns for the same day. Add a dedicated table that owns the uniqueness
  constraint, e.g. in `backend/src/background/db.ts`:

  ```sql
  CREATE TABLE IF NOT EXISTS dailyGenerations (
      sourceTemplateId TEXT NOT NULL,
      generatedDate TEXT NOT NULL,  -- YYYY-MM-DD in generatingTimezone
      generatingTimezone TEXT NOT NULL,  -- IANA zone when this marker was written
      attemptId TEXT NOT NULL,  -- lease / attempt identifier (UUID per attempt)
      idempotencyKey TEXT NOT NULL UNIQUE,  -- durable key stamped on the cloned rundown
      leaseExpiresAt TEXT NOT NULL,  -- ISO-8601 instant; restart-safe lease expiry
      rundownId TEXT,  -- NULL iff status IN ('in_progress','failed'); NOT NULL iff completed
      status TEXT NOT NULL CHECK(status IN ('in_progress', 'completed', 'failed')),
      -- Enforce combinations in app code (SQLite CHECK cannot easily express iff):
      --   in_progress => rundownId IS NULL
      --   completed   => rundownId IS NOT NULL
      --   failed      => rundownId IS NULL (clone never finished or reconcile found none)
      PRIMARY KEY (sourceTemplateId, generatedDate, generatingTimezone)
  );
  ```

  **`generatedDate` format and timezone (canonical, shared everywhere):**
  - Format: `YYYY-MM-DD` (calendar date only — no time component).
  - Timezone: a single configured IANA zone on the **server** (extend
    `ApplicationSettings` with e.g. `dailyCloneTimezone`, default
    `Europe/Bratislava` for this show). Derive the date with one shared helper
    (e.g. `getDailyGeneratedDate(now = new Date()): string` using
    `Intl.DateTimeFormat('en-CA', { timeZone: dailyCloneTimezone, year: 'numeric',
    month: '2-digit', day: '2-digit' }).format(now)` — `en-CA` yields
    `YYYY-MM-DD`). Do **not** use `Date#toISOString().slice(0, 10)` (that is
    always UTC), do **not** use `getFullYear()`/`getMonth()`/`getDate()` (those
    are the process's local TZ and drift if the container TZ changes), and do
    **not** let the browser compute "today" for status lookups.
  - Call that same helper from: the scheduler tick, the manual "Generate now"
    route, the "Generated today?" status lookup, and unit tests (pass a fixed
    `now` / mock the helper). `dailyCloneTime` (`HH:mm`) is interpreted in the
    **same** `dailyCloneTimezone`.
  - **Timezone changes:** persist `generatingTimezone` on every row.
    - **Completed** markers from a previous zone: ignore for the new zone's
      "already generated?" / block decisions (keep `generatingTimezone`-based
      matching — do not migrate dates).
    - **`in_progress` (and `failed`) rows from the previous zone:** must be
      **reconciled or canceled before** the new zone starts generation — do not
      leave them as ignored orphans that could still finish later and attach a
      rundown under the old zone while the new zone also clones. On
      `dailyCloneTimezone` settings change (and at scheduler start if a zone
      mismatch is detected): for each old-zone `in_progress` row, run the same
      reconcile-by-`idempotencyKey` path as restart recovery; if no rundown was
      created, set `status = 'failed'` so the reservation cannot complete under
      the old zone afterward. Only then may the new zone insert its own
      reservation. Unit-test: zone change near midnight with an old-zone
      `in_progress` row — it is canceled/reconciled first; old-zone
      **completed** markers still neither block nor satisfy the new zone.

  Write a single wrapper (e.g. `generateDailyRundownIfNeeded(templateId)` in a new
  `backend/src/background/api/dailyGeneration.ts`) used by **both** the scheduler and
  the manual "Generate now" button — no other path should call
  `createRundownCopy` for the daily-template case. **Eliminate the crash window
  between clone and marker:** do **not** `createRundownCopy` first then hope the
  marker lands. Instead:
  1. Mint `attemptId` (UUID) and a durable `idempotencyKey` (stable for the attempt;
     e.g. `sha256(sourceTemplateId + '|' + generatedDate + '|' + generatingTimezone + '|' + attemptId)`).
     Set `leaseExpiresAt` to now + a fixed lease (e.g. 5–15 minutes) — durable in
     the row, not only in memory. `INSERT` with `status = 'in_progress'`,
     `rundownId = NULL`. Primary-key conflict on `completed` → return that
     `rundownId`. Conflict on live `in_progress` whose lease has **not** expired →
     join/wait on that attempt (do not start a second clone). Conflict on
     `failed` → take the explicit retry transition in step 5 (do not INSERT a
     second PK row — the PK already holds the day).
  2. Call `createRundownCopy`, then **require** both `idempotencyKey` and
     `attemptId` to be persisted on the created rundown (extend
     `createRundownCopy` / post-create `update` to write them on the Rundown —
     e.g. top-level fields or `payload.dailyGeneration = { idempotencyKey,
     attemptId }`). Optional stamping is not enough for restart-safe reconcile.
     Every log line for this attempt must include `attemptId`, `idempotencyKey`,
     and (once known) `rundownId` so clone↔reservation association survives in
     server logs.
  3. On definite clone success: transition `in_progress` → `completed` and set
     `rundownId`. On definite clone failure (thrown error before a rundown id
     exists): only after reconcile finds **no** rundown for this
     `idempotencyKey`, transition `in_progress` → `failed` (`rundownId` stays
     NULL).
  4. **Timeout / unknown clone outcome** (process crash, hung call, unclear
     whether copy committed): **must reconcile before** any transition to
     `failed` or any retry. Look up rundowns by stamped `idempotencyKey` /
     `attemptId`. If found → `in_progress` → `completed` with that `rundownId`.
     If not found and `leaseExpiresAt` is still in the future → leave
     `in_progress` (do not fail yet). If not found and the lease has expired →
     `in_progress` → `failed`, then retry via step 5. Never fail or retry on an
     unknown outcome without that reconcile.
  5. **Retry of a retained `failed` row:** the PK
     `(sourceTemplateId, generatedDate, generatingTimezone)` prevents inserting a
     replacement row, so define an explicit transition **`failed` → `in_progress`**
     on the **same** row: mint a new `attemptId` + `idempotencyKey`, reset
     `leaseExpiresAt`, keep `rundownId = NULL`, set `status = 'in_progress'`, then
     repeat from step 2. Do not delete-and-reinsert as the happy path. Valid
     transitions: `in_progress→completed`, `in_progress→failed`,
     `failed→in_progress`; never `completed→in_progress` /
     `completed→failed`. Unit-test: failure between clone success and marker
     completion; restart with unexpired vs expired lease; timeout/unknown
     requires reconcile; `failed→in_progress` retry without duplicate rundowns;
     "clear in_progress without reconcile" must be impossible by design.

  This table (with reservation + idempotency key + durable lease) is the atomicity
  guarantee — a `sourceTemplateId`/`generatedDate` pair stored only as free-form
  JSON fields on the `Rundown` document (with no DB-level constraint) cannot
  enforce uniqueness by itself, no matter how carefully the check-then-act read is
  written.
- **Per-tick error handling:** wrap each scheduler tick's call to
  `generateDailyRundownIfNeeded` in its own try/catch so a single failure (Core
  unreachable, DB error, bad template id) cannot kill the interval and silently stop
  all future days' generation. On failure, `console.error` including the
  `dailyTemplateRundownId`, the `generatedDate` being attempted, and the thrown
  error's message/stack. On success, `console.info` with the same identifying fields
  plus the resulting `rundownId` — this runs unattended overnight/early morning, the
  log is the only evidence it ran until someone opens RE.

### 2. Frontend: visibility + manual override

File: `frontend/src/components/rundownList/rundownListItem.tsx` (or the template's row
specifically) and wherever the rundown list is rendered.

- On a template rundown's row, show whether it already generated today's rundown
  (`Generated today · <link to the generated rundown>`) or not yet, by looking up
  today's `dailyGenerations` row for that template **in the current
  `dailyCloneTimezone`** with `status = 'completed'` (new small read endpoint, or
  include it in the existing rundown-list payload). Do not treat an old-zone marker
  as "Generated today."
- Add a "Generate now" button next to it that calls a new route wrapping the **same**
  `generateDailyRundownIfNeeded` function the scheduler uses (not a second copy of the
  clone-then-check logic) — this is the manual escape hatch for when the schedule is
  misconfigured or the service restarted past the trigger time. Because uniqueness is
  enforced by the `dailyGenerations` primary key (see #1), clicking it after the
  scheduler already ran today safely returns the existing rundown instead of creating
  a duplicate — don't make the daily workflow depend on the scheduler being perfectly
  reliable on day one.

### 3. Frontend: bulk field-rewrite view

New route, e.g. `frontend/src/routes/rundown/$rundownId/rewrite.tsx`, linked from the
rundown view (a "Daily rewrite" button/tab, most useful right after a scheduled clone
lands).

- Goal: **one screen, one scroll**, not per-piece forms. A table grouped by
  segment → part, one row per piece, showing only the fields editors touch daily:
  prompter/script text, GFX name-ish fields (`headline`, `subline`, `title`, `name`,
  `role`, `tema`, …), and media fields (`fileName`, `iluFile`).
- Make this **data-driven from the type manifests**, not hardcoded per piece type: add
  an optional `dailyEditable: true` flag to the relevant field definitions in the
  megarepo's `assets/sofie-rundown-editor-piece-types.json` (the canonical source per
  this repo's `AGENTS.md` — edit it there, not in a local copy), and have the rewrite
  view render exactly those fields for whatever piece types are present in the cloned
  rundown. This means adding new daily-editable piece types later doesn't require
  touching this view's code.
  - **This edit does not take effect in `unopus` on its own — follow the megarepo
    asset handoff, in order:** (1) land the `dailyEditable` field addition in
    `tojemoc/sofie` (megarepo) `assets/sofie-rundown-editor-piece-types.json`; (2) in
    `unopus`, bump the pinned commit SHA and recompute the SHA-256 checksum(s) that
    `scripts/fetch-sofie-megarepo-assets.sh` verifies — pin + checksum **in the same
    commit**, per
    [`docs/integration/MEGAREPO-ASSETS-FETCH.md`](../MEGAREPO-ASSETS-FETCH.md) in the
    megarepo; (3) re-run the fetch script (or restart the dev container) so
    `SOFIE_MEGAREPO_ASSETS` points at a tree containing the new field; (4) in the
    running RE instance, use Settings' existing "reload manifests" action
    (`reloadManifestsFromAssets` in `backend/src/background/api/settings.ts`) to
    re-import `typeManifests` from the refreshed JSON — the manifest is loaded once at
    process start (`backend/src/background/manifest.ts`) and cached into the
    `typeManifests` table, so editing the megarepo file alone does not update an
    already-running instance.
- Media fields in this view should use the same `MediaPickerField` component (see #4)
  so readiness/duration feedback is present here too, not just in the regular piece
  forms.
- Saving writes back through the existing per-piece `mutations.update`, one call per
  edited piece — no new sync path, no new API surface beyond what already exists for
  editing a piece. Track and show per-piece success/failure in the view (e.g. a
  per-row saved/error indicator) rather than a single all-or-nothing "Saved" toast, and
  offer a retry action for any piece whose update call failed, since a partial failure
  partway through a multi-piece save is the normal failure mode here — only reach for
  an atomic multi-piece transaction if a future requirement genuinely needs all-or-
  nothing semantics (not needed for the daily-rewrite use case as scoped here).
- **Verify:** after step (4) above, open the rewrite view on a rundown containing a
  piece type whose manifest has a `dailyEditable: true` field and confirm that field
  (and only that field, plus the others explicitly flagged) appears as an editable row
  — this is the concrete check that the manifest → RE handoff actually worked end to
  end, not just that the JSON was edited in the megarepo.

### 4. Frontend: readiness-aware file picker

File: `frontend/src/components/rundown/mediaPickerField.tsx` + whatever backend route
backs `fetchRundownMedia` (likely under `backend/src/routes/` — check `lib/mediaApi.ts`
on the frontend for the exact endpoint).

Today this is a pure filesystem listing (`MediaFileEntry` = name/path/duration from a
local scan) with no notion of "is this actually confirmed on the Caspar playout
machine." Once the diagnostics handoff (`re-readiness-diagnostics.md`) lands and
per-piece Core-sourced readiness is reliable and observable:

- Extend `MediaFileEntry` with a tri-state `readiness: 'confirmed' | 'not-confirmed' |
  'unknown'` (plus `reason?: string`) — **not** a plain `ready: boolean`. Reserve
  `'confirmed'`/`'not-confirmed'` exclusively for a real Core/Package Manager answer
  (the file is in use by some piece Core has status for, per the diagnostics handoff's
  per-piece `source: 'core'` data). When there's no Core-sourced status for that exact
  file — e.g. it exists on the scanned folder but isn't referenced by any piece Core
  has evaluated yet — return `'unknown'` with a `reason` like "not yet confirmed by
  Package Manager", never silently reuse the local `fs.stat` existence check
  (`mediaReadiness.ts`'s local path) as a stand-in for `ready: true`/`false`. A file
  merely existing in RE's scanned folder is not the same claim as Package Manager
  having confirmed it on the Caspar media disk, and collapsing the two back into a
  boolean recreates the exact "which source produced this verdict" ambiguity the
  diagnostics handoff (`re-readiness-diagnostics.md`) is trying to eliminate.
- **Aggregation when several Core-evaluated pieces (or several media requirements
  within one piece) reference the same path:**

  **Canonical match key** (one shared helper, used for both listing join and tests):
  1. **Reject first** (return unmatched / `unknown` — do **not** strip or collapse
     separators on these): UNC paths (`//…` or `\\…`) and device/protocol URLs
     (`dshow://…`, `http(s)://…`, etc.). Collapsing `\\` before this check would
     corrupt UNC into a fake relative path.
  2. For remaining paths: replace `\` with `/` only after the reject step; collapse
     duplicate `/`; drop trailing `/`; lower-case (Windows Caspar/PM paths are
     case-insensitive).
  3. **Drive letters:** if the path matches `^[a-z]:/…`, normalize both the path
     and the configured ingest root the same way (trailing `/` stripped). Require
     `path === root` **or** `path.startsWith(root + '/')` before stripping the
     shared root prefix to get the relative key. Paths outside the root stay
     unmatched. Do **not** test whether the full path is a prefix of the ingest
     root (that comparison is backwards and can false-match). Do **not** strip
     `c:` first and hope the remainder matches.
  4. Otherwise (already relative): strip a single leading `/` if present; the
     result is the relative key under the ingest root.
  Align with the existing slash-normalization in `resolveMediaAbsolutePath`
  (`media.ts` / `mediaReadiness.ts`), but do **not** treat absolute resolution
  alone as enough — the join key is the normalized relative form above.

  **Scope:** only aggregate Core verdicts from the **current** RE peripheral
  device's studio response for the **active rundown** whose media listing is being
  built (the rundown id passed into `fetchRundownMedia` / readiness). Do not merge
  statuses from other rundowns, other studios, or stale caches keyed only on
  filename. Piece-level: include every media requirement on pieces in that rundown
  whose normalized path equals the entry's key.

  **Core → MediaFileEntry mapping** (name the fields — don't invent synonyms):
  each Core verdict is a `CorePieceContentStatus` from
  `backend/src/background/coreContentStatus.ts` with:
  - `ready: boolean` — authoritative ready/not-ready flag from Core
    (`true` when Core `statusCode === PieceStatusCode.OK` / `CORE_PIECE_STATUS_OK`
    which is `0`; otherwise `false`)
  - `statusCode: number` — Sofie `PieceStatusCode` (numeric; do not hardcode the
    full enum in RE beyond OK=`0` unless you import the shared type)
  - `reason?: string` — optional operator-facing reason when not ready

  One-way map into `MediaFileEntry.readiness` after collecting all in-scope
  verdicts for the entry's match key (deterministic, no "first match wins"):
  1. If **any** verdict has `ready === false` → `readiness: 'not-confirmed'`.
     For `reason`: take only those not-ready verdicts, **sort by a stable key**
     (e.g. `pieceExternalId` then field id / requirement path, ascending), then
     either pick the first non-empty `reason` in that order, **or** concatenate
     distinct non-empty reasons in that same order (choose one approach and stick
     to it — do not depend on `Map`/`Set` iteration order). If every not-ready
     verdict has an empty/missing `reason`, leave `reason` undefined/empty
     (preserve existing empty-reason behavior).
  2. Else if **at least one** verdict has `ready === true` (and none are false) →
     `readiness: 'confirmed'`.
  3. Else (zero in-scope Core verdicts for that key) → `readiness: 'unknown'`.

  A single piece with two `mediaPick` fields that both normalize to the same key
  (or two pieces sharing one clip) must follow the same rule — one
  `ready === false` requirement blocks a confirmed aggregate. Unit-test: conflict
  (piece A `ready: true` + piece B `ready: false` for the same key →
  `not-confirmed`); stable reason ordering when two not-ready verdicts disagree;
  Windows path variants (`clips\\a.mp4` vs `clips/a.mp4` vs `Clips/A.MP4`); UNC /
  `dshow://` stay unmatched; drive-letter path under ingest root joins, outside
  root does not; and isolation (verdict from another rundown / another device
  must not affect this listing).
- Surface readiness as part of each option's **visible text and accessible name**, not
  only a colored dot — e.g. `clip.mp4 (confirmed)` / `clip.mp4 (not confirmed: <reason>)`
  / `clip.mp4 (not yet confirmed)`. Plain `<option>` elements inside a native
  `<datalist>`/`<select>` cannot carry a separate tooltip or icon that assistive tech
  or keyboard-only users can perceive, so the status must be in the text itself (or in
  the `label` attribute, which browsers also expose as the accessible name) — a dot
  next to the text is not sufficient and untestable with a keyboard alone. If you want
  a richer visual treatment (colored indicator, richer tooltip) build a small custom
  combobox/listbox instead of trying to decorate native `<option>`s, and verify it
  with keyboard-only navigation (arrow keys + Enter, no mouse) and a screen reader
  pass, not just a visual check.
- This is explicitly the "WIP file-picker" referenced in
  `docs/integration/RE-READINESS-AND-PLAYOUT-UX.md` — it was correctly identified as
  blocked on readiness being trustworthy first. Do this step after, not in parallel
  with, the diagnostics handoff.

---

## Suggested order

1. Scheduler + idempotency + manual "Generate now" (independent of everything else,
   ship first).
2. Bulk rewrite view, manifest-driven (`dailyEditable` flag) — independent of
   readiness work, ship second.
3. Readiness-aware picker — do this last, after `re-readiness-diagnostics.md` lands,
   since it depends on trustworthy per-file Core status.

## Verify

1. `yarn test` / add coverage for the idempotency check (same template + same day
   should not produce two rundowns; different day should). Also cover
   `getDailyGeneratedDate`: fixed `now` in `Europe/Bratislava` vs UTC midnight edge
   (e.g. 23:30 UTC on day D must still yield Bratislava's calendar date when that
   zone is ahead), and confirm scheduler + manual + status lookup all use the helper.
   Scheduler: delayed tick after `dailyCloneTime` still generates when the marker is
   absent; restart after trigger time does not duplicate; spring-forward gap and
   fall-back fold each produce exactly one generation for that `generatedDate`.
   Settings: invalid `dailyCloneTime` / `dailyCloneTimezone` rejected on **save and
   load**; `dailyTemplateRundownId` rejected when missing, deleted, or
   `isTemplate !== true` on save, load, and pre-generate. Timezone change: old-zone
   `in_progress` reconciled/canceled before new-zone generation; old-zone
   `completed` ignored for block/satisfy. Reservation: `idempotencyKey` reconcile
   before clear/retry; failure between clone and marker complete + restart must not
   duplicate.
2. `yarn lint`.
3. Manual: set `dailyCloneTime` a few minutes in the future, confirm a new dated
   rundown appears after that time even if the interval wakes late; restart the
   backend mid-day and confirm it does **not** duplicate the day's rundown; if
   practical, also check behavior across a DST transition weekend in a test harness
   with a frozen clock rather than waiting for real DST.
4. Manual: open the bulk rewrite view on a freshly generated rundown, change a
   prompter line + an L3D `headline` + an ILU `fileName`, save, then confirm those
   same values show correctly in the normal per-piece form and (once synced) in Sofie's
   own rundown view. Also verify one piece's save failing (e.g. temporarily stop the
   backend mid-save) leaves the other rows' saved state intact and offers a retry for
   just that row.
5. Manual: in the picker, confirm a file Package Manager has confirmed shows
   `confirmed` and one it reports missing shows `not confirmed: <reason>` in the
   option text itself (not just a color), and that a file with no Core-sourced status
   yet shows `unknown`/`not yet confirmed` rather than being guessed from the local
   scan. Also verify a conflict: the same normalized key referenced by one piece with
   `ready: true` and one with `ready: false` (or two requirements on one piece)
   aggregates to `not-confirmed`, not `confirmed`. Confirm path variants
   (`clips\x.mp4` vs `clips/x.mp4`) join, and that another rundown's Core status for
   the same filename does not leak in. Tab/arrow through the control with no mouse to
   confirm the status is reachable without relying on a tooltip.

## Out of scope

- Anything under `tojemoc/unopus` branch `backup` or `tojemoc/duopus` — legacy
  vMix/Google-Sheets/Companion control-surface concepts, not applicable to the
  current Sofie-centric architecture. Don't port code from either.
- Changing what `createRundownCopy` / `cloneFromRundownToRundown` actually clone —
  reuse them as-is.
- The readiness/duration diagnostics work itself — see the companion handoff
  `re-readiness-diagnostics.md`; this doc only consumes its output in step 4.
