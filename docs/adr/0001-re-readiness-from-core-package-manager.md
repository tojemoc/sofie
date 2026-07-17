# ADR 0001: Source Rundown Editor readiness from Core's Package Manager status

**Status:** Proposed — deferred, target post-demo (PR2-style)
**Date:** 2026-07-17
**Repos affected:** `tojemoc/sofie-core` (primary), `tojemoc/unopus` (secondary)
**Owner:** Jakub

---

## Context

Rundown Editor's READY/NOT READY badges (`backend/src/background/mediaReadiness.ts`) currently
compute readiness by polling the Linux filesystem directly: `fs.stat()` against
`<ingestMediaRoot>/spravy/<rundownId>/clips/<file>`, plus a WebM-sibling check for `iluFile`
fields. This is fully independent of Sofie — it does not consult Core, Playout Gateway, or
Package Manager in any way.

This caused two concrete failures in the current deployment (Windows CasparCG + Package Manager
worker, Linux Proxmox CT running Core/Playout Gateway/RE in Docker):

1. `ingestMediaRoot` was set to a Windows-style path (`C:/casparcg/sofie-demo-media/spravy`),
   which does not resolve on the Linux container RE runs in, and additionally double-nests
   `spravy` since `media.ts` already appends that segment.
2. More fundamentally: RE's local-fs check can never be "correct" in a mixed-OS deployment,
   because it is checking a different, unrelated filesystem from the one Package Manager
   actually manages. Any fix is a coincidental alignment (e.g. a mounted SMB share), not a
   structural guarantee.

Separately, Package Manager **already** computes and reports exactly this kind of status
natively: `updatePackageContainerPackageStatuses` (peripheral device method) writes into Core's
`PackageContainerPackageStatuses` collection, alongside `PackageInfos` and `MediaObjects`. Core's
own WebUI already turns this into piece-level readiness via
`meteor/server/publications/pieceContentStatusUI/checkPieceContentStatus.ts` (`PieceStatusCode`),
published to browser clients as `CorelibPubSub.uiPieceContentStatuses`.

The gap: RE connects to Core as a **PeripheralDevice** (`CoreHandler`, using
`@sofie-automation/server-core-integration`), and the device-scoped subscription surface
(`PeripheralDevicePubSub`) does not expose package/content status — only
`packageManagerExpectedPackages`, `packageManagerPackageContainers`, and
`packageManagerPlayoutContext`, which are for Package Manager itself to read its *assignments*,
not for other devices to read its *results*. `uiPieceContentStatuses` and `packageInfos` are
`CorelibPubSub`, scoped to authenticated Meteor UI clients only.

## Decision

Give RE a real, device-scoped read path into Core's already-computed package/content status,
instead of RE re-deriving readiness itself from a filesystem it doesn't reliably share with
Package Manager.

### Core changes (`sofie-core`)

- Add a new peripheral-device-callable API, e.g.
  `peripheralDevice.packageManager.getContentStatusForRundown(deviceId, token, rundownId)`,
  reusing the existing computation in `checkPieceContentStatus.ts` rather than reimplementing it.
- Extend `PeripheralDevicePubSubTypes` / `PeripheralDevicePubSub` with the minimum needed to
  subscribe reactively (or start with a polled method call if a full publication is too invasive
  — see Open Questions).
- Scope the returned payload to what RE actually needs to render a badge: per-piece
  `PieceStatusCode` + a short reason string. Do **not** expose full `PackageInfo` internals
  (scan results, thumbnails, etc.) unless a future RE feature needs them — keep the API surface
  minimal and intentional.

### RE changes (`unopus`)

- `CoreHandler` subscribes to / polls the new API for the active rundown.
- `mediaReadiness.ts` is updated to prefer Core-reported status when available.
- Keep the existing local `fs.stat` check as a **fallback**, not delete it outright — see Rollout.

## Consequences

- **Touches Core's server code**, which is otherwise tracked close to upstream (small, deliberate
  fork delta). This is real, reviewable surgery, not a config change — budget it like a normal
  feature PR, not a quick follow-on.
- **Touches RE's Core WebSocket integration**, which is on the RE fork's own explicit "do not
  change" list. This ADR is the deliberate, documented exception to that rule — the rule stays in
  force for everything else.
- Once landed, RE's readiness becomes authoritative and agrees with what Sofie's own rundown view
  shows, instead of two independent (and occasionally disagreeing) implementations.
- Removes RE's dependency on ever having direct filesystem access to Package Manager's media root
  — no more SMB mount required for readiness specifically (still likely wanted for other reasons,
  e.g. RE's own media picker/import features, which is a separate concern from this ADR).

## Rollout plan

1. Ship the near-term fix first and independently: correct `ingestMediaRoot` (Linux mount path,
   no trailing `spravy`) + SMB share from the Windows box. This is what actually needs to work by
   Friday and is unaffected by this ADR's timeline.
2. Land the Core API addition on its own branch/PR against `tojemoc/sofie-core`, with its own
   test coverage, once demo pressure is off.
3. Land the RE consumption change as a second PR, defaulting to **hybrid mode**: use Core-reported
   status when the subscription is live and healthy, fall back to local fs-stat if Core is
   disconnected or the new API errors. Don't hard-cut to Core-only until it's been observed
   agreeing with the fs-based check across a few real rundowns.
4. Once confidence is established, remove the fs-based path (or keep it permanently as a
   diagnostic-only fallback — decide at that point, not now).

## Do-not-change boundaries

- Don't rework rundown ingestion or the existing `ExpectedPackages` generation path in blueprints
  — this ADR is read-only status plumbing, not a change to what Package Manager is asked to do.
- Reuse `checkPieceContentStatus.ts`'s existing computation in Core rather than duplicating
  `PieceStatusCode` logic in a new code path.
- No schema changes to RE's SQLite store beyond whatever's needed to cache the last-known Core
  status per piece (if caching is even needed — may be able to keep this in-memory only).

## Open questions

- Polling vs. reactive subscription: a full DDP publication is more idiomatic Sofie architecture
  but larger surface area; a simple periodic method call (mirroring RE's existing 10s readiness
  poll) may be enough and is a smaller Core change. Decide based on how much lag is acceptable
  for the badge to update after PM finishes a copy.
- Auth/token scoping: confirm the existing RE peripheral device token is sufficient for a new
  method namespace, or whether a distinct permission is warranted.
- Whether "reason" strings from Core's `PieceStatusCode` are specific enough for RE's tooltip UX,
  or whether the new API needs to return something more granular than what the WebUI currently
  shows.
