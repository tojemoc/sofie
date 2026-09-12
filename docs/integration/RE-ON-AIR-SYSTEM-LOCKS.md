# Sofie on-air → Rundown Editor locks

## Goal

Mirror Sofie playout position in the Rundown Editor (RE), and reuse the existing collaborative presence lock UI so previous / current / next **parts** are locked by a synthetic user named **System**.

## Sofie Core

New peripheral-device method:

- Name: `peripheralDevice.ingest.getRundownPlayoutState`
- Args: `(deviceId, deviceToken, rundownExternalId)`
- Returns:

| Field | Meaning |
|-------|---------|
| `rundownExternalId` | Echo of the requested ingest external id |
| `activated` | Playlist containing the rundown has an `activationId` |
| `rehearsal` | Playlist is activated in rehearsal mode (informative only for v1 locks) |
| `previousPartExternalId` | Sofie `Part.externalId` of previous, or `null` |
| `currentPartExternalId` | Sofie `Part.externalId` of current, or `null` |
| `nextPartExternalId` | Sofie `Part.externalId` of next, or `null` |

If the rundown is unknown to the device's studio, or the playlist is not activated, Core returns `activated: false` and all part ids `null`.

### Device credentials

RE does **not** pick a device per rundown. It uses its **own** already-connected ingest peripheral (`coreHandler`): `callMethodRaw` injects that device's `deviceId` / `deviceToken`. Core authorizes the call against that device and scopes the rundown lookup to the device's studio.

## Rundown Editor

### Which rundowns are polled

`playoutLockService` polls ~1s for every local rundown with `sync=true` and `isTemplate=false`.

In this megarepo, `sync=true` means **RE is the ingest source** for that rundown (RE part ids == Sofie `Part.externalId`, 1:1). Do not mark foreign-ingest rundowns `sync=true` in RE; there is no alternate id mapping in v1.

### `activated` / `rehearsal`

| Core response | System locks | On-air chrome |
|---------------|--------------|---------------|
| `activated: false` | Cleared (`lockedPartIds: []`) | Cleared (`currentPartId` / `currentSegmentId` null) |
| `activated: true` (live or rehearsal) | Set on non-null previous/current/next | Current part + its segment highlighted |
| `rehearsal: true` | Same lock rules as live | Same; flag is forwarded for UI if needed |

Missing previous / current / next values are `null` and are **omitted** from the lock set (not locked as empty ids).

### `syncSystemPartLocks(rundownId, partIds)`

Each successful poll **replaces** the full System-owned part-lock set for that rundown:

- Parts in `partIds` get a System presence focus (evicting any human holder).
- System focuses on parts no longer in the window are removed.
- Pass `[]` to clear all System locks for the rundown.

### Core unreachable / timeout

If Core is disconnected or the method errors, RE **keeps the last successful lock / on-air snapshot** (no clear). Locks clear only when Core explicitly returns `activated: false`, or when the rundown is no longer `sync=true`.

### `playout:update` socket payload

Emitted **after** `syncSystemPartLocks` for that rundown (so presence and on-air stay in sync). Late-joining sockets also receive the cached last payload on connect.

```ts
{
  rundownId: string           // RE rundown id (== Sofie externalId)
  activated: boolean
  rehearsal: boolean
  previousPartId: string | null
  currentPartId: string | null
  nextPartId: string | null
  currentSegmentId: string | null  // segment owning currentPartId, if known
  lockedPartIds: string[]          // deduped previous/current/next when activated
}
```

### System lock enforcement

- UI: same lock chip as user locks; takeover modal is OK-only (no Kick) when holder is System.
- **Server:** `trySetPresenceFocus(..., { force: true })` still **rejects** when a System focus holds the entity. Clients cannot bypass via the force-take API.

## Product rule (v1)

Locked = Sofie **previous + current + next** parts (not whole segments). On-air chrome marks the current part and its segment.

## Companion PRs

- Core: https://github.com/tojemoc/sofie-core/pull/9
- RE: https://github.com/tojemoc/unopus/pull/82
