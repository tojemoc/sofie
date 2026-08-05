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
	| { source: 'core'; statuses: Map<string, CorePieceContentStatus> }
	| { source: 'core-disconnected' }
	| { source: 'core-error'; error: string }
	| { source: 'core-empty' } // Core reachable, rundown not found there yet
```

Keep the existing `CoreConnectionStatus.CONNECTED` short-circuit and the
`callMethodRaw` try/catch, just don't discard the reason. Distinguish "rundown not
found on Core" (empty `pieces` array — likely not synced/ingested yet) from an actual
thrown error (bad device/studio config, DDP hiccup) — those need different operator
messaging.

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
    coreCallSource: result.source,             // 'core' | 'core-disconnected' | 'core-error' | 'core-empty'
    coreCallError: result.source === 'core-error' ? result.error : undefined,
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
  `rundownExternalId` (e.g. `__diagnostics_probe__`) and report the raw error message
  verbatim if it throws. This surfaces exactly the failure class described in ADR
  0001 — e.g. `Meteor.Error(400, 'Device "..." has no studio')` when the RE peripheral
  device hasn't been assigned to a studio in Core's Settings UI, which is a very easy
  state to end up in and looks identical to "Core is just down" today.

### 4. Frontend: show provenance, not just the badge

Files: `frontend/src/components/rundown/readinessBadge.tsx`,
`frontend/src/hooks/useRundownReadiness.ts` (or equivalent),
`frontend/src/components/rundown/RundownReadinessContext.tsx` (or equivalent — confirm
exact current filenames, PR #32 in `SPRAVY-V2-INTEGRATION.md` lists these).

- Extend `getPieceReadinessTooltip` to append a line noting the source, e.g. `via
  Package Manager` vs `via local scan (Core unreachable)` vs `Core error: Device "..."
  has no studio`.
- Add a small, persistent status chip somewhere always-visible (rundown header or a new
  Settings → Diagnostics page) driven by `/api/core/diagnostics`, polled on the same
  ~10s cadence as readiness. Traffic-light style: green "Package Manager connected",
  yellow "Core connected, PM status unavailable — showing local scan only", red "Core
  disconnected" — with the raw error text visible on click/hover for whoever is
  debugging.

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
   — `core`, `core-disconnected`, `core-error`, `core-empty`).
2. `yarn lint`.
3. Manual: with Core stopped, confirm the diagnostics chip shows red + the readiness
   API's `diagnostics.coreCallSource === 'core-disconnected'`.
4. Manual: with Core up but the RE peripheral device **not** assigned to a studio in
   Core Settings, confirm the diagnostics probe surfaces the "has no studio" error
   verbatim instead of looking identical to "Core disconnected".
5. Manual, on the real deployment (Windows Caspar/PM box + Alpine LXC): use the new
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
