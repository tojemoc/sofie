# CasparCG FFmpeg input buffers (DShow / Virtual Camera)

When PGM uses a live Windows capture producer such as:

```text
dshow://video=OBS Virtual Camera
```

CasparCG logs spam like:

```text
[ffmpeg] [dshow @ …] real-time buffer [OBS Virtual Camera] [video input] too full or near too full (102% of size: 3041280 [rtbufsize parameter])! frame dropped!
```

alongside `ffmpeg[dshow://…] Latency: N` warnings.

## What is happening

- **3041280 bytes** is FFmpeg’s default **`rtbufsize`** for DirectShow (~3 MiB).
- OBS Virtual Camera (often 1080p) can fill that buffer when Caspar’s producer thread is busy
  compositing HTML, ILU, wipes, and file loops on the same channel.
- Caspar then **drops frames** and logs latency — this is capture-side backlog, not PGM output
  `buffer-depth`.

## What does *not* fix it

| Knob | Scope | Effect on DShow spam |
|------|--------|----------------------|
| `<consumers><screen><buffer-depth>` | Output consumer | Smooths **playout to monitor/NDI** only |
| `<channels><channel><video-mode>` | Channel timing | Unrelated to FFmpeg capture buffer |
| AMCP `LOADBG` / blueprint `noStarttime` | Producer start | Reduces A/V sync warnings; **does not** resize `rtbufsize` |

Demo blueprints set `noStarttime: true` on live camera producers (see `pgmCamera.ts`) so DShow
does not fight Sofie’s timeline clock. That helps sync but **does not** stop `rtbufsize` drops.

## Fix: raise `rtbufsize` in Caspar server (recommended)

Stock CasparCG **2.4.x** does not expose `rtbufsize` for `dshow://` URLs. Patch the server once:

**File:** `src/modules/ffmpeg/av_input.cpp` (path varies slightly by fork)

**After** the existing `video_size` / `pixel_format` option block (~line 248), **before**
`avformat_open_input`:

```cpp
if (format_.find(L"dshow://") == 0 || format_.find(L"v4l2://") == 0) {
    av_dict_set(&options, "rtbufsize", "100M", 0);
}
```

Or apply the ready-made diff:

[`patches/caspar-dshow-rtbufsize.patch`](patches/caspar-dshow-rtbufsize.patch)

Rebuild CasparCG Server and redeploy. **`100M`** is a sane default for 1080p virtual cameras; use
`200M` if drops persist under heavy HTML/ILU load.

### Optional: per-studio value (future)

`main-studio-config.json` includes optional `pgmCameraDshowRtbufsize` for documentation and a
future server build that reads producer `media-content` options. Until that server exists, only the
**global patch** above applies.

## Operational mitigations (no rebuild)

1. **Lower OBS Virtual Camera output** to 1280×720 in OBS → Tools → Virtual Camera.
2. **Reduce concurrent producers** on PGM channel 2 (fewer simultaneous file loops during camera
   stress tests).
3. **Deploy current demo blueprints** so `assets/countup` is not in rundown baseline — countup
   latency lines at ~109 s often mean the old bundle still loads countup from segment 0.
4. **Close other DShow consumers** (only one Caspar producer per virtual camera).

## Related docs

- [`DOUBLEBOX-PGM.md`](DOUBLEBOX-PGM.md) — UVC / virtual camera wiring
- [`OUTPUT_TOPOLOGY.md`](OUTPUT_TOPOLOGY.md) — LED vs PGM channels
