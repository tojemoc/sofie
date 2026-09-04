# Playout NR badges & Package Manager path

When Sofie WebUI shows yellow warnings like:

- **Voice Over** can't be found on the playout system
- **ILU** can't be found on the playout system
- **Lower Third** / **Logo** / **Audio Bed** / **PGM DoubleBox frame** can't be found…

those strings are **Sofie source-layer names**, not missing scripts or L3D templates.
Diagonal striping (“banding”) on a timeline piece is the same signal: Package Manager
marked that ExpectedPackage **not ready**.

| Sofie badge | What Package Manager is verifying |
|-------------|-----------------------------------|
| Voice Over | SYN / VO clip under `clips/…` (media file) |
| ILU | Headline illustration clip (`clips/HEADLINE*.mov`, etc.) |
| Lower Third | DoubleBox ILU media (or legacy L3D package) |
| Logo | Countup / logo-bug asset (`assets/countup`) |
| Audio Bed | `loops/bg_music_*` |
| PGM DoubleBox frame | `loops/db_loop` |

**How to read a useful warning after the path is fixed**

1. Title row = piece / payload (e.g. `HEADLINES • gfx/headline | clips/HEADLINE1.mov, …`).
2. Body = source layer that failed verify (`ILU`, `Voice Over`, …).
3. One missing file can appear twice in the notifications list (piece status + package
   status). Treat identical title+body pairs as a single issue.
4. If **every** clip is banded and every layer says “can't be found”, ignore the
   per-clip wording until Package Manager can read its media folder (below). The
   folder is broken, not fifty separate files.

## Root cause on this studio

Caspar plays from the real media tree:

```text
Y:/360-ingest/sofie-demo-media/clips/…
```

Package Manager was still configured for the blueprint demo default:

```text
c:\casparcg\sofie-demo-media   ← ENOENT every ~60s in PM logs
```

Caspar `PLAY` / `LOADBG` can succeed (files on `Y:`) while Sofie marks every ExpectedPackage **not ready** because PM cannot `access()` its container folder. **Do not suppress these warnings** — fix the path so warnings mean a real miss.

Confirm in Package Manager logs:

```text
ENOENT: no such file or directory, access 'c:\\casparcg\\sofie-demo-media'
```

That single error produces the mass “Voice Over / ILU / … can't be found” spam.

## Fix (ops)

1. Sofie WebUI → Studio settings → set **Ingest media folder** and **CasparCG media folder** to the same tree Caspar uses, e.g. `Y:/360-ingest/sofie-demo-media` (forward slashes OK).
2. **Apply Configuration**.
3. Confirm Package Manager log no longer spam `ENOENT … sofie-demo-media`.
4. Optional: `mklink /J c:\casparcg\sofie-demo-media Y:\360-ingest\sofie-demo-media` if you want the blueprint default path to keep working.
5. Re-check the rundown: banding should clear for files that exist; remaining NR rows
   are real misses (wrong relative path, typo, or file not on the Caspar host).

Rundown Editor **Ingest media root** must match the same tree.

Near-duplicate on-air filenames (`FOO.mp4` vs `FOO v2.mp4` / `FOO_final.mp4`) are
warned in the Rundown Editor media picker (unopus), not via Sofie NR banding.

## Related black PGM after DoubleBox → SYN

If AMCP shows `PLAY 2-110 route://3-0` (layer **0**) instead of `route://3`, PGM is routing an empty layer while the SYN clip plays on `3-110` → black program. Blueprints after the full-channel route fix emit `layer: null` so casparcg-state serializes a full-channel mix. Upload a fresh blueprint bundle + Activate.

## Dual OBS Virtual Camera / `rtbufsize` spam

Lookahead `PRELOAD` on camera layers was opening `dshow://` on the **idle** BG channel while the on-air look still held another instance. Camera mappings now use `LookaheadMode.NONE` and live camera pieces skip look preroll. Still raise `rtbufsize` per [`CASPAR-FFMPEG-BUFFERS.md`](./CASPAR-FFMPEG-BUFFERS.md).

## Debug channel labels

Studio flag `casparcg.hypercomposed.debugChannelLabels` burns in:

- `1. LED` · `2. PGM` · `3. DoubleBox` · `4. Full`

on Caspar layer **990**. Copy [`assets/caspar-debug-channel-label/debug-channel-label.html`](../../assets/caspar-debug-channel-label/debug-channel-label.html) to:

```text
<template-path>/gfx/debug-channel-label/debug-channel-label.html
```

then Apply Configuration / restart playout.
