# Unopus: ignore Sofie media status (sync rundown only)

## Problem

With Sync to Sofie off, media readiness uses local ingest filesystem checks and correctly shows Ready when files exist. With Sync on, readiness prefers Sofie Package Manager content-status via Core, which can invent false Not Ready errors.

## Fix (in `tojemoc/unopus`)

Branch: `cursor/ignore-core-content-status-46f4`

Adds Settings → Connection toggle **Ignore Sofie media status (sync rundown only)** (`ignoreCoreContentStatus`):

- Sync to Sofie still pushes rundown ingest create/update/delete
- Readiness skips Core content-status and uses local FS only; diagnostics report `coreCallSource: "ignored"` when the setting is on (other paths still use `core` / `core-disconnected` / `core-error`)
- Media listing skips Package Manager enrichment and uses local ingest filesystem data only (listed files are marked confirmed from ingest presence)

Open / merge the unopus PR from that branch; this megarepo note is tracking only (no nested consumer commit).
