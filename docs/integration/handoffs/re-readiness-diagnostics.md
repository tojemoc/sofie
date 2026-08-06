# Handoff: Rundown Editor — make the readiness/duration pipeline observable

**Copy everything below the line into a new Cursor agent session running in
`tojemoc/unopus`.** A small, optional follow-up section at the end targets
`tojemoc/sofie-core` — only do that part if you confirm it's actually needed (see
Step 5).

---

## Your mission

Operators report that **READY/NOT READY badges and durations don't reliably reflect
reality** across the real deployment topology: Windows 10 box running CasparCG + CCG
Media Scanner + Package Manager, talking DDP to Sofie Core / Rundown Editor / Playout
Gateway running in Docker on an Alpine LXC. Badges sit on NOT READY (or silently show
stale/wrong state) with no indication of *why*, and nobody can tell whether a given
badge came from the authoritative Package Manager status or a same-container filesystem
guess.

**Important — read this before writing any code:** the "obvious" fix (ADR
[`docs/adr/0001-re-readiness-from-core-package-manager.md`](../../adr/0001-re-readiness-from-core-package-manager.md))
is **already implemented and merged** on both sides:

- `sofie-core` `main`: `peripheralDevice.packageManager.getContentStatusForRundown`
  (`meteor/server/api/integration/rundownContentStatus.ts`,
  `meteor/server/api/peripheralDevice.ts`, `packages/shared-lib/src/peripheralDevice/methodsAPI.ts`)
  reuses `checkPieceContentStatusAndDependencies` — the exact same computation Sofie's
  own WebUI uses.
- `unopus` `main`: `backend/src/background/coreContentStatus.ts` calls that method;
  `backend/src/background/mediaReadiness.ts` already prefers the Core-reported status
  per piece and falls back to local `fs.stat` only when Core is unavailable or errors.
- The `externalId` contract holds end-to-end: RE's local `piece.id` is exported as
  `MutatedPiece.id` (`backend/src/background/api/pieces.ts`), blueprints set
  `Piece.externalId = object.id` for graphics/clips
  (`sofie-demo-blueprints/packages/blueprints/src/base/showstyle/helpers/graphics.ts`
  and `.../helpers/clips.ts`), and Core returns `pieceExternalId` from that same field
  — so `coreStatuses.get(piece.id)` in `mediaReadiness.ts` does match. **Do not
  "re-fix" this ID matching — it's already correct.**

**Do not rebuild ADR 0001.** Your job is a thin, additive **observability and
hardening layer** on top of it, because right now every failure mode in that chain —
Core disconnected, RE's peripheral device not attached to a studio, the method call
throwing, Package Manager itself down or misconfigured on the Windows box — collapses
into the exact same silent behavior: `fetchCoreContentStatusForRundown` returns `null`,
`console.warn`s to a log nobody is watching, and RE falls back to the local filesystem
check with no visible trace of what happened or why. That's what makes this "the most
troubling part" to debug on real hardware you can't just SSH into from here — give the
humans on the studio floor a screen that tells them exactly where the chain breaks.

---

## What to build

### 1. Backend: stop collapsing every failure into `null`

File: `backend/src/background/coreContentStatus.ts`

Change `fetchCoreContentStatusForRundown` to return a discriminated result instead of
`Map | null`:

```ts
export type CoreContentStatusResult =
	| { source: 'core'; statuses: Map<string, CorePieceContentStatus> } // may be empty
	| { source: 'core-disconnected' }
	| { source: 'core-error'; error: string }
```

Keep the existing `CoreConnectionStatus.CONNECTED` short-circuit and the
`callMethodRaw` try/catch, just don't discard the reason. **Do not add a distinct
`core-empty` source.** Today's `getContentStatusForRundown`
(`rundownContentStatus.ts`) returns `{ rundownExternalId, pieces: [] }` both when the
rundown isn't found on Core (not synced yet) *and* when the rundown exists but every
piece was filtered out for lacking a resolvable `sourceLayer` — these are very
different problems (one is "wait for sync," the other is a real showstyle/sourceLayer
misconfiguration) and the current method response can't tell them apart. Model this
honestly: `source: 'core'` with an empty `statuses` map just means "Core answered with
zero piece statuses," nothing more. Don't label it as "not synced" in any UI copy —
if you want a real distinction, note it as an open follow-up (a lightweight
rundown-existence signal would need a small Core-side addition, not a client-side
guess) rather than asserting a meaning the current API can't back up.

### 2. Backend: thread the result through readiness evaluation

Files: `backend/src/background/mediaReadiness.ts`, `backend/src/routes/readiness.ts`

- `evaluateRundownReadiness` / `evaluatePieceReadiness` already take an optional
  `coreStatus` per piece — add a parallel `source: 'core' | 'fs'` tag to each
  `PieceReadiness` (or each `MediaRequirement`) recording which path actually produced
  that particular ready/not-ready verdict.
- In `readiness.ts`'s route handler, include a top-level `diagnostics` block in the
  JSON response, e.g.:

```ts
{
  pieces: { ... },        // unchanged
  parts: { ... },         // unchanged
  summary: { ... },       // unchanged
  diagnostics: {
    coreConnectionStatus: coreHandler.connectionInfo.status,
    coreCallSource: result.source,             // 'core' | 'core-disconnected' | 'core-error'
    coreCallError: result.source === 'core-error' ? result.error : undefined,
    corePieceStatusCount: result.source === 'core' ? result.statuses.size : 0, // 0 is ambiguous, see above — don't over-interpret it
    piecesFromCore: number,
    piecesFromFsFallback: number,
    checkedAt: new Date().toISOString(),
  }
}
```

### 3. Backend: a standalone diagnostics endpoint (works even without an open rundown)

New file: `backend/src/routes/coreDiagnostics.ts`, registered next to
`registerReadinessRoutes` in wherever routes are wired up (check `backend/src/main.ts`
or `backend/src/routes/index.ts` for the pattern — follow whatever `readiness.ts` does
for auth).

`GET /api/core/diagnostics` should return, without needing a rundown:

- `coreHandler.connectionInfo` (url, port, status) — already public on `CoreHandler`.
- Whether a `deviceId`/`deviceToken` is configured (vs. the `unsecureToken` default —
  see `getCoreConnectionOptions` in `coreHandler.ts`).
- A live probe: call `getContentStatusForRundown` with a deliberately bogus
  `rundownExternalId` (e.g. `__diagnostics_probe__`). On throw: log the **full**
  Core error (message + stack) only in protected server logs (`console.warn` /
  structured logging already used by `coreContentStatus.ts`). Return a **safe
  operator-facing** summary to the client — e.g. map known stable Meteor reason
  patterns to short labels (`Device has no studio`, `Core method unavailable`,
  `Unauthorized`), otherwise a generic `Core content-status call failed`. Do **not**
  put the raw Core error string into the JSON response or the UI chip by default;
  allow verbatim exposure only if/when Core's error contract for this method is
  explicitly documented as operator-safe (today it is not — messages can include
  device ids and internal paths). This still surfaces the failure class described
  in ADR 0001 (e.g. device not assigned to a studio looking identical to "Core is
  just down") without leaking internals to every browser session.

  **Be precise about what this probe proves and what it doesn't.** A successful
  (non-throwing) call only proves: RE's device credentials are valid, the device is
  attached to a studio, and Core's method endpoint responded. It does **not** prove
  Package Manager itself is connected or actively reporting fresh statuses — PM could
  be completely offline and this same call would still succeed, just describing
  content as not-ready (or, per the empty-pieces ambiguity note above, returning zero
  piece statuses). Don't label this probe's success as "Package Manager connected" —
  call it what it is: Core's rundown-content-status API is reachable and this device
  is correctly configured. If you want a real Package-Manager-liveness signal, that's
  the optional Core-side extension in step 5, not something this probe can give you.

  **Coalesce concurrent polls:** cache the last probe result (and its `checkedAt`)
  in-process with a short TTL (e.g. 5–10s, matching the UI poll cadence). Concurrent
  browser requests within the TTL share one Core method call and the same
  `checkedAt` / traffic-light payload instead of each issuing a fresh probe. On TTL
  expiry, one in-flight probe refreshes the cache; others wait on that promise rather
  than stampeding Core. Preserve the existing traffic-light states; only the number
  of Core round-trips changes.

### 4. Frontend: show provenance, not just the badge

Files: `frontend/src/components/rundown/readinessBadge.tsx`,
`frontend/src/hooks/useRundownReadiness.ts` (or equivalent),
`frontend/src/components/rundown/RundownReadinessContext.tsx` (or equivalent — confirm
exact current filenames, PR #32 in `SPRAVY-V2-INTEGRATION.md` lists these).

- Extend `getPieceReadinessTooltip` to append a line noting the source, e.g. `via
  Package Manager` vs `via local scan (Core unreachable)` vs `Core: Device has no
  studio` (use the same safe operator-facing labels as the diagnostics probe — never
  the raw Core exception text).
- Add a small, persistent status chip somewhere always-visible (rundown header or a new
  Settings → Diagnostics page) driven by `/api/core/diagnostics`, polled on the same
  ~10s cadence as readiness. Traffic-light style, labeled for what the probe actually
  proves (see the note in step 3 — don't claim Package Manager's own connection state
  from this call): green "Core reachable, device configured", yellow "Core reachable,
  content-status call failed — showing local scan only" (with the **safe** operator
  label, not the raw Core string), red "Core disconnected". If step 5's optional
  Core-side extension lands, add a genuinely PM-sourced fourth state instead of
  inferring it from this probe. Backend coalescing (step 3) means N open browsers
  should still produce ~1 Core probe per TTL window.

### 5. Only if you actually hit it: Core-side diagnostics extension

Don't do this speculatively — only if step 3's probe reveals that RE genuinely needs
more than an error string to build a useful diagnostics screen (e.g. wanting to show
Package Manager's own connection/last-seen-scan state, not just piece-level status).
If so, a small addition to `sofie-core`'s
`meteor/server/api/integration/rundownContentStatus.ts` /
`RundownContentStatusIntegration` namespace that also returns basic
`PeripheralDevices`/`PackageContainerPackageStatuses` health for the studio would be
the minimal extension — reuse existing collections, don't invent a new status model.

### 6. Duration: split "on-air" vs "source" (separate, smaller task, same PR is fine)

The `RE-READINESS-AND-PLAYOUT-UX.md` planning doc flags this as unresolved: three
different durations exist (piece on-air `duration` in seconds, `payload.sourceDuration`
in ms from ffprobe, part `duration`) and operators conflate them. Concretely:

- In the story/part table and `piecePropertiesForm`, show **two** columns/fields where
  a `sourceDuration` exists: "On air" (editable) and "Source" (read-only, from
  ffprobe via the existing media picker probe in `mediaPickerField.tsx` /
  `backend/src/background/media.ts`).
- For piece type `wipe`, when `duration` is empty/0, display the effective blueprint
  default (`DEFAULT_WIPE_DURATION_MS` = 2500ms = "2.5s") instead of a blank/`00:00`,
  so it doesn't look uncontrolled. Pull this constant from wherever blueprints expose
  it, or just hardcode `2.5s` with a comment pointing at the blueprints constant if
  there's no shared source of truth today.

---

## Verify

1. `yarn test` (extend `mediaReadiness.test.ts` with cases for each new `source` value
   — `core` with a populated map, `core` with an empty map, `core-disconnected`,
   `core-error`).
2. `yarn lint`.
3. Manual: with Core stopped, confirm the diagnostics chip shows red + the readiness
   API's `diagnostics.coreCallSource === 'core-disconnected'`.
4. Manual: with Core up but the RE peripheral device **not** assigned to a studio in
   Core Settings, confirm the diagnostics chip/API shows a safe operator label (e.g.
   "Device has no studio") and that the **server log** still carries the full Core
   error — the browser response must not echo the raw exception string.
5. Manual: open the diagnostics page in two browsers at once; confirm both receive the
   same `checkedAt` within one TTL window and that Core only sees ~one probe call per
   window (log or network), not one per client.
6. Manual, on the real deployment (Windows Caspar/PM box + Alpine LXC): use the new
   `/api/core/diagnostics` + per-badge tooltips to walk the actual chain end-to-end and
   confirm you can now tell, from the RE UI alone, whether a NOT READY badge means
   "Package Manager says the file is missing" vs "RE can't reach Core at all" vs
   "device isn't attached to a studio."

## Out of scope

- Rebuilding or duplicating `checkPieceContentStatus.ts`'s computation — reuse it.
- Changing the `externalId` contract between RE and blueprints — it's already correct.
- The reactive-subscription-vs-polling open question in ADR 0001 — keep polling, it's
  fine for a status display.
- The bulk-editing / daily-clone workflow — see the companion handoff
  `re-daily-template-workflow.md`.
