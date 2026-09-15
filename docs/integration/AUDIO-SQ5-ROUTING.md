# Audio routing — Caspar → SQ-5 virtual outputs

SPRÁVY sends **multiple independent audio stems** out of Caspar so the Allen & Heath
**SQ-5** can mix them live (beds, SYN/ILU, wipe SFX, mic return). Sofie blueprints
still drive **Sisyfos** channel on/off + Caspar `mixer.volume`; the SQ-5 is the final
hardware mix.

## Stem map (recommended)

| Stem | Caspar origin | Typical SQ-5 USB / Dante in |
|------|---------------|-----------------------------|
| PGM program (stereo) | Channel **2** mix (route + overlays) | USB 1–2 or Dante 1–2 |
| LED bed / kolíska | Channel **1** layer **80** (`casparcg_audio_bed`) | USB 3–4 |
| PGM bed mirror | Channel **2** layer **80** (`casparcg_audio_bed_pgm`) | (or combined with LED bed) |
| SYN / ILU / VT | Look channels **3/4** → heard on PGM via `route://N` | Keep on PGM bus; duck under wipe in blueprints |
| Wipe SFX | Channel **2** layer **200** EffectsPlayer | Prefer discrete if SQ needs isolate |
| Host mic | Console input (not Caspar) — ForceMuted under SYN/wipe | SQ mic channel |

Blueprints ForceMute **Host + Playback** during wipe, ForceMute **Host** under SYN, and
duck Caspar clip/ILU `mixer.volume` to **0** for the wipe window so route:// audio is
silent while wipe SFX plays.

## Windows virtual outputs (stock Caspar)

Stock Caspar **system-audio / OAL** is **stereo, one device**. To feed the SQ-5 with
more than one stereo pair without an ASIO fork:

1. Install **VB-Audio VoiceMeeter** (or Cakewalk/ASIO4ALL + multiple CABLE devices).
2. Point Caspar channel consumers at VoiceMeeter inputs (or use one stereo out and
   split inside VoiceMeeter).
3. Route VoiceMeeter outputs to **SQ Loudspeaker** (WDM, stereo → SQ USB 1–2) and/or
   additional **VB-CABLE** devices patched into SQ USB / Dante Via.

```text
Caspar ch2 system-audio ──► VoiceMeeter VAIO
                              ├─ A1 → SQ Loudspeaker (USB 1–2)
                              ├─ A2 → CABLE-B → SQ / DAW
                              └─ A3 → local monitor
```

## Multi-channel ASIO (preferred for 4–8 stems)

Use a Caspar build with **PortAudio / ASIO** consumer (CasparCG Enhanced / community
PortAudio PRs). Match SQ-5 ASIO device name and channel count:

```xml
<audio>
  <channel-layout>passthru</channel-layout>
</audio>

<!-- example consumer on PGM channel -->
<portaudio>
  <device-name>SQ</device-name>
  <output-channels>8</output-channels>
  <latency-compensation-ms>40</latency-compensation-ms>
</portaudio>
```

Patch SQ I/O: USB outs 1…N → console channels. Keep Sisyfos channel numbers in studio
config aligned with the same stem order.

## Sofie studio config

Populate `sisyfosSources` (Host / Guest / Playback) so ForceMute has real channels.
Empty `sisyfosSources` (demo default) makes mute timeline objects no-ops.
