# Handoff: preserve part `script` on rundown import (unopus)

## Problem

Importing `assets/spravy-v3-smoke-rundown.json` into the Rundown Editor left the
**SCRIPT** textarea empty for every part (e.g. Počasie / weather), even though the
JSON has top-level `"script": "Zajtra sa oteplí…"`.

## Cause

`convertOldPartToNew` in unopus treated **any** part with `payload.type` as a
legacy export and rebuilt the part from **payload only**. Modern smoke parts look
like:

```json
{
  "partType": "gfx",
  "script": "Zajtra sa oteplí…",
  "duration": 2.5,
  "payload": { "name": "Počasie", "type": "GFX" }
}
```

`payload.type` is Sofie ingest metadata; script/duration live at the **top level**.
The legacy converter therefore set `script` / `duration` to `undefined`.

## Fix

**Repo:** [tojemoc/unopus](https://github.com/tojemoc/unopus)  
**Branch:** `cursor/import-part-script-46f4`  
**Open PR from:** https://github.com/tojemoc/unopus/pull/new/cursor/import-part-script-46f4

- If `partType` is already set → return the part unchanged (keep top-level script).
- True legacy parts (no `partType`, script inside `payload`) still migrate as before.
- Unit tests: `frontend/src/util/convertOldPart.test.ts`

## Verify

1. Import `spravy-v3-smoke-rundown.json` in the Rundown Editor.
2. Open segment **POČASIE** → part **Počasie**.
3. SCRIPT shows the weather copy; read time is non-zero.
