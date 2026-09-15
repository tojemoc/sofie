# FFmpeg recording — PGM video + discrete audio

Record the **PGM Caspar channel** (default **2**) with an FFmpeg consumer so you get
the composed picture plus multi-channel PCM for post / podcast stems.

## Always-on consumer (`caspar.config`)

```xml
<channel> <!-- 2 = PGM -->
  <video-mode>1080p5000</video-mode>
  <consumers>
    <!-- existing Screen / NDI / SDI … -->
    <ffmpeg>
      <path>recordings/pgm_%Y%m%d_%H%M%S.mov</path>
      <args>-codec:v libx264 -preset:v veryfast -crf:v 18 -pix_fmt yuv420p -codec:a pcm_s24le -filter:a aformat=sample_fmts=s32:channel_layouts=stereo</args>
    </ffmpeg>
  </consumers>
</channel>
```

For **4 discrete channels** (requires mixer layout ≥4 / `passthru`):

```xml
<args>-codec:v libx264 -preset:v veryfast -crf:v 18 -pix_fmt yuv420p -codec:a pcm_s24le -filter:a pan=4c|c0=c0|c1=c1|c2=c2|c3=c3</args>
```

## Runtime AMCP

```text
ADD 2 FILE "recordings/pgm.mov" -codec:v libx264 -preset:v veryfast -crf:v 18 -filter:v format=yuv420p -codec:a pcm_s24le
REMOVE 2 FILE
```

Multi-channel ISO:

```text
ADD 2 FILE "recordings/pgm_4ch.mov" -codec:v libx264 -preset:v veryfast -crf:v 18 -filter:v format=yuv420p -codec:a pcm_s24le -filter:a pan=4c|c0=c0|c1=c1|c2=c2|c3=c3
```

## Audio layout prerequisite

```xml
<audio>
  <channel-layouts>
    <quad>
      <type>4.0</type>
      <num-channels>4</num-channels>
      <channels>L R Ls Rs</channels>
    </quad>
  </channel-layouts>
</audio>
```

Or use built-in `passthru`. Always pass `-codec:a pcm_s24le` (or similar) when recording
more than stereo — default AAC/stereo encoders reject multi-channel layouts.

## Stem strategy

| Goal | Approach |
|------|----------|
| Single PGM ISO | One ffmpeg consumer on ch2 (video + mixed stereo) |
| Separate music / VO | Multi-channel layout + `pan=Nc\|…`, or post-split the multi-channel MOV |
| Per-file stems | Multiple Caspar channels each with their own ffmpeg consumer |

Blueprints do **not** emit RECORD timeline objects by default — recording is an ops /
`caspar.config` concern so ISO does not depend on rundown take.

## Related

- [`CASPAR-FFMPEG-BUFFERS.md`](./CASPAR-FFMPEG-BUFFERS.md) — DShow capture `rtbufsize`
- [`AUDIO-SQ5-ROUTING.md`](./AUDIO-SQ5-ROUTING.md) — live stems into SQ-5
- [`OUTPUT_TOPOLOGY.md`](./OUTPUT_TOPOLOGY.md) — channel / layer map
