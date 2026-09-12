# Sofie on-air → Rundown Editor locks

## Goal

Mirror Sofie playout position in the Rundown Editor (RE), and reuse the existing collaborative presence lock UI so previous / current / next **parts** are locked by a synthetic user named **System**.

## Sofie Core

New peripheral-device method:

- Name: `peripheralDevice.ingest.getRundownPlayoutState`
- Args: `(deviceId, deviceToken, rundownExternalId)`
- Returns previous / current / next `Part.externalId` values plus `activated` / `rehearsal`

RE part ids are Sofie `externalId`s when RE is the ingest source, so the ids map 1:1.

## Rundown Editor

1. `playoutLockService` polls Core ~1s for every `sync=true` rundown.
2. Applies System presence locks on `{previous, current, next}` parts via `syncSystemPartLocks`.
3. Emits `playout:update` for on-air UI (part badge + segment highlight).
4. System locks cannot be force-taken (same lock chip UI as user locks; takeover modal explains and offers OK only).

## Product rule (v1)

Locked = Sofie **previous + current + next** parts (not whole segments). On-air chrome marks the current part and its segment.
