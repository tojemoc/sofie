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

- No new dependency needed — a `setInterval` that wakes up once a minute, compares
  local wall-clock time against a configured `HH:mm`, and only fires once per
  calendar day is simpler to reason about than a cron library for a single daily job.
  (If you'd rather have real cron syntax for future multi-schedule needs, `node-cron`
  is a fine addition — just don't over-engineer a single daily trigger.)
- Settings (extend `ApplicationSettings` in `interfaces.ts` + the settings form under
  `frontend/src/components/settings/`): `dailyTemplateRundownId` (which rundown is
  "today's template" — dropdown of rundowns where `isTemplate === true`) and
  `dailyCloneTime` (`HH:mm`, local server time). Leave the feature inert if either is
  unset.
- On trigger: call the **existing** `mutations.createRundownCopy({ id:
  dailyTemplateRundownId, preserveTemplate: false })` — do not reimplement cloning.
- **Idempotency:** add `sourceTemplateId: string | undefined` and `generatedDate:
  string | undefined` (`YYYY-MM-DD`, local) to the `Rundown` shape in `interfaces.ts`
  and set them on the cloned rundown inside `createRundownCopy` (or a thin wrapper
  around it used only by the scheduler) so a restart or a missed tick can't produce a
  second rundown for the same day — check for an existing rundown with the same
  `sourceTemplateId` + `generatedDate` before cloning.
- Log clearly (`console.info`) on both success and failure — this runs unattended
  overnight/early morning, the log is the only evidence it ran until someone opens RE.

### 2. Frontend: visibility + manual override

File: `frontend/src/components/rundownList/rundownListItem.tsx` (or the template's row
specifically) and wherever the rundown list is rendered.

- On a template rundown's row, show whether it already generated today's rundown
  (`Generated today · <link to the generated rundown>`) or not yet, using the new
  `sourceTemplateId`/`generatedDate` fields.
- Add a "Generate now" button next to it that calls the same clone path on demand —
  this is the manual escape hatch for when the schedule is misconfigured or the
  service restarted past the trigger time; don't make the daily workflow depend on the
  scheduler being perfectly reliable on day one.

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
- Media fields in this view should use the same `MediaPickerField` component (see #4)
  so readiness/duration feedback is present here too, not just in the regular piece
  forms.
- Saving writes back through the existing per-piece `mutations.update` — no new sync
  path, no new API surface beyond what already exists for editing a piece.

### 4. Frontend: readiness-aware file picker

File: `frontend/src/components/rundown/mediaPickerField.tsx` + whatever backend route
backs `fetchRundownMedia` (likely under `backend/src/routes/` — check `lib/mediaApi.ts`
on the frontend for the exact endpoint).

Today this is a pure filesystem listing (`MediaFileEntry` = name/path/duration from a
local scan) with no notion of "is this actually confirmed on the Caspar playout
machine." Once the diagnostics handoff (`re-readiness-diagnostics.md`) lands and
per-piece Core-sourced readiness is reliable and observable:

- Extend `MediaFileEntry` with an optional `ready: boolean` / `reason?: string`,
  populated by cross-referencing the scanned filename against whatever Core/Package
  Manager status data is available for files already in use, or at minimum against the
  same local ingest-root check `mediaReadiness.ts` already does for that exact path.
- Render a small colored dot + tooltip per option in both the `<datalist>` and the
  `<Form.Select>` scanned-folder list, so picking a file for tomorrow's rundown shows
  at a glance whether it's already staged/confirmed, not just "a file with this name
  exists somewhere RE can see."
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
   should not produce two rundowns; different day should).
2. `yarn lint`.
3. Manual: set `dailyCloneTime` a minute in the future, confirm a new dated rundown
   appears automatically without touching the UI; restart the backend mid-day and
   confirm it does **not** duplicate the day's rundown.
4. Manual: open the bulk rewrite view on a freshly generated rundown, change a
   prompter line + an L3D `headline` + an ILU `fileName`, save, then confirm those
   same values show correctly in the normal per-piece form and (once synced) in Sofie's
   own rundown view.
5. Manual: in the picker, confirm a file that's missing on the Caspar box (per Package
   Manager) is visually distinguishable from one that's confirmed staged.

## Out of scope

- Anything under `tojemoc/unopus` branch `backup` or `tojemoc/duopus` — legacy
  vMix/Google-Sheets/Companion control-surface concepts, not applicable to the
  current Sofie-centric architecture. Don't port code from either.
- Changing what `createRundownCopy` / `cloneFromRundownToRundown` actually clone —
  reuse them as-is.
- The readiness/duration diagnostics work itself — see the companion handoff
  `re-readiness-diagnostics.md`; this doc only consumes its output in step 4.
