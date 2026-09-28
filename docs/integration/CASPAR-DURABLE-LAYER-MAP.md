# Caspar durable channel / layer map

**Canonical inventory** of every durable Sofie → CasparCG address used by hypercomposed
SPRÁVY / 360 sekúnd. Topology rationale: [`OUTPUT_TOPOLOGY.md`](./OUTPUT_TOPOLOGY.md).
DoubleBox FILL/CROP: [`DOUBLEBOX-PGM.md`](./DOUBLEBOX-PGM.md).

**Code truth:** `blueprints/packages/blueprints/src/base/studio/applyConfig/mappings/casparcg.ts`
+ `casparcgLayers.ts` + showstyle helpers (`clips.ts`, `pgmLook.ts`, `graphics.ts`,
`backgroundMusic.ts`, `baseline.ts`, …).

**Shipping blueprints:** [sofie-demo-blueprints #121](https://github.com/tojemoc/sofie-demo-blueprints/pull/121)
(per-file PGM wipe layers **205–208**, hard-cut overlap). Topology ADR path remains
[#77](https://github.com/tojemoc/sofie-demo-blueprints/pull/77).

Default channels: **1** LED · **2** PGM · **3** BG A (DoubleBox) · **4** BG B (Full) ·
**5** CAM ingest. Studio may remap via `casparcg.hypercomposed.*`.

AMCP address = `{channel}-{layer}` (e.g. `PLAY 2-205 "wipes/wipe"`). MEDIA paths are
extensionless under Caspar `media-path`; HTML CG templates live under `template-path`.

---

## Quick matrix (what lands where)

| Channel | Role | Consumer? | What lives here |
|--------:|------|:---------:|-----------------|
| **1** | LED wall | yes | `bg_loop`, pod, headline ILU, kolíska bed |
| **2** | PGM air | yes | `route://3\|4`, wipes 205–208, countup, intro/outro, bed |
| **3** | DoubleBox look | no | cam `route://5`, story ILU, `db_loop`, L3D, SYN/VT |
| **4** | Full look | no | SYN/SJV/sport/weather, fullscreen cam, L3D |
| **5** | Live CAM ingest | no | sole DeckLink / dshow |

```text
CasparCG
├── 1 LED  ──► consumers     durable: loops + headline stack + bed
├── 2 PGM  ──► consumers     durable: route + overlays (wipe/countup/intro) + bed
├── 3 BG A ──► (render only) durable look stack (DoubleBox)
├── 4 BG B ──► (render only) durable look stack (Full)
└── 5 CAM  ──► (render only) durable: live capture once
```

---

## Channel 1 — LED (allow-list)

| Layer | Sofie mapping id | AMCP shape | Durable path / payload | When |
|------:|------------------|------------|------------------------|------|
| **80** | `casparcg_audio_bed` | `PLAY 1-80 "loops/bg_music_{a\|c}" LOOP` + `MIXER … VOLUME` | `loops/bg_music_a` (show bed), `loops/bg_music_c` (ŠPORT) | Baseline + segment beds; mirrored on PGM 80 |
| **80** | *(same)* | `PLAY 1-80 "assets/headline_sfx"` | `assets/headline_sfx` | Each headline Take (hit, then bed resumes) |
| **100** | `casparcg_clip_player_preview` | preview only | — | Softie preview; not on-air LED |
| **110** | `casparcg_clip_player1` | `PLAY 1-110 "loops/bg_loop" LOOP` | `loops/bg_loop` | Always (baseline); tema FILL/CROP zoom on DoubleBox |
| **112** | `casparcg_led_pod_headline` | `PLAY 1-112 "assets/pod_headline" LOOP` | `assets/pod_headline` (.png) | Headlines segment; cleared on first DoubleBox |
| **115** | `casparcg_ilu_player` | `PLAY 1-115 "clips/<name>"` | `clips/HEADLINE*`, other headline ILU movs | Headline parts |
| **120** | `casparcg_graphics_ticker` | legacy CG | — | **Unused** in hypercomposed SPRÁVY |
| **121** | `casparcg_graphics_l3d` | legacy CG `gfx/headline-fallback` | chrome only | Optional LED ILU frame; **not** story L3D copy |
| **122** | `casparcg_graphics_strap` | legacy | — | Unused |
| **123** | `casparcg_graphics_logo` (LED) | deprecated | — | Logo is **PGM 123**, not LED |
| **200** | `casparcg_effects_player` | legacy | — | **Do not use** for intro/wipe in hypercomposed |
| **990** | `casparcg_debug_label_led` | debug burn-in | — | Optional |

**LED must not carry:** wipe, intro/outro, `l3d-*`, logo-bug/countup, camera, story SYN fullscreen.

### LED z-order

```text
990  debug (optional)
200  legacy effects — unused
121  headline-fallback chrome (optional)
115  headline ILU mov          ◄── allow-list
112  pod_headline              ◄── allow-list (headlines)
110  bg_loop                   ◄── allow-list
100  preview
 80  audio bed / headline_sfx
```

---

## Channel 2 — PGM (route bus + overlays)

| Layer | Sofie mapping id | AMCP shape | Durable path / payload | When |
|------:|------------------|------------|------------------------|------|
| **80** | `casparcg_audio_bed_pgm` | `PLAY 2-80 "loops/bg_music_{a\|c}" LOOP` | same files as LED 80 | Mirror of LED kolíska |
| **110** | `casparcg_pgm_route` | `PLAY 2-110 "route://3"` or `"route://4"` | full-channel route (never `route://N-0`) | Always while on-air; hard-cut under wipe at air cut |
| **123** | `casparcg_graphics_logo` | `PLAY 2-123 "assets/countup" LOOP` (+ MIX opacity) | `assets/countup` | First DoubleBox Take onward; hidden during headlines |
| **205** | `casparcg_effects_player_pgm` | `LOADBG` / hot `PLAY 2-205` | `wipes/wipe` + `VF premultiply=inplace=1` | Classical story wipe — **own layer** |
| **206** | `casparcg_effects_player_pgm_sjv` | `LOADBG` / hot `PLAY 2-206` | `wipes/wipe_sjv` | SJV entrance wipe |
| **207** | `casparcg_effects_player_pgm_sport` | `LOADBG` / hot `PLAY 2-207` | `wipes/wipe_sport` | ŠPORT entrance wipe |
| **208** | `casparcg_effects_player_pgm_pocasie` | `LOADBG` / hot `PLAY 2-208` | `wipes/wipe_pocasie` | Počasie entrance wipe |
| **210** | `casparcg_intro_player_pgm` | `PLAY 2-210 "assets/intro_*"` / `"assets/outro"` | `assets/intro_michal`, `assets/outro`, … | Intro / znelka / outro — **never LED** |
| **990** | `casparcg_debug_label_pgm` | debug burn-in | — | Optional |

### Why 205–208 are separate

Sofie `LookaheadMode.PRELOAD` LOADBGs the **next** wipe onto the EffectsPlayer mapping.
One shared layer meant PRELOAD of `wipe_sjv` **destroyed** LOADBG'd `wipe.mov`, so the
next Take cold-played `PLAY 2-205 "wipes/wipe"` (Latency 22–34f) while air cut still
assumed hot (~0–19f). One Sofie mapping + physical layer **per wipe file** keeps hot PLAY
([blueprints #121](https://github.com/tojemoc/sofie-demo-blueprints/pull/121)).

### PGM z-order

```text
990  debug (optional)
210  intro / znelka / outro
208  wipe_pocasie
207  wipe_sport
206  wipe_sjv
205  wipe (classical)
123  countup / logo-bug
110  route://3|4          ◄── hears look compose
 80  audio bed
```

Legacy: do **not** put wipes on **200** (sticky `MIXER … KEYER` broken remastered alpha).

---

## Channel 3 — BG A / DoubleBox look (render-only)

Same layer numbers as channel 4. PGM hears this mix via `PLAY 2-110 "route://3"`.

| Layer | Sofie mapping id | AMCP shape | Durable path / payload | When |
|------:|------------------|------------|------------------------|------|
| **110** | `casparcg_clip_player2` | `PLAY` / `LOAD` + `RESUME` | `clips/<ILU|SYN|VT…>` | Story VT in left compose / pre-roll |
| **115** | `casparcg_pgm_camera` | `PLAY 3-115 "route://5"` + FILL | live CAM sample | DoubleBox right window |
| **116** | `casparcg_pgm_ilu_player` | `PLAY 3-116 "clips/…"` + FILL/CROP | DoubleBox left ILU | `doublebox-ilu` |
| **118** | `casparcg_pgm_doublebox_loop` | `PLAY 3-118 "loops/db_loop" LOOP` | `loops/db_loop` (aka `dp_loop` on disk) | DoubleBox segment frame |
| **121** | `casparcg_graphics_pgm_l3d` | `CG 3-121 ADD 1 "gfx/…" 1 {json}` | see HTML table below | Topic L3Ds on DoubleBox |
| **990** | `casparcg_debug_label_doublebox` | debug | — | Optional |

Look compose layers use Sofie lookahead **NONE** (PRELOAD would replace on-air producers under the wipe).

### BG A z-order

```text
990  debug
121  l3d-* HTML
118  db_loop frame
116  story ILU (left)
115  camera route://5 (right)
110  fullscreen / preloaded VT
```

---

## Channel 4 — BG B / Full look (render-only)

| Layer | Sofie mapping id | AMCP shape | Durable path / payload | When |
|------:|------------------|------------|------------------------|------|
| **110** | `casparcg_clip_player2_b` | `PLAY 4-110 "clips/…"` / `"loops/bg_loop"` | SYN clusters, SJV beds, fullscreen VT | Full-section story |
| **115** | `casparcg_pgm_camera_b` | `PLAY 4-115 "route://5"` or `EMPTY` | fullscreen cam / cleared under SYN | Headlines cam, MOD, ZAVER |
| **116** | `casparcg_pgm_ilu_player_b` | `PLAY 4-116 "assets/bg_pocasie"` / clips / `EMPTY` | weather map under HTML; story ILU | Počasie + Full ILU |
| **118** | `casparcg_pgm_doublebox_loop_b` | usually `EMPTY` / clear | — | Must not leave stray `db_loop` on Full |
| **121** | `casparcg_graphics_pgm_l3d_b` | `CG 4-121 ADD 1 "gfx/…" 1 {json}` | headline / syn / sjv / sport / pocasie / odporúčanie | Most Full L3Ds |
| **990** | `casparcg_debug_label_full` | debug | — | Optional |

### BG B z-order

```text
990  debug
121  l3d-* / pocasie HTML
118  (keep clear on Full)
116  bg_pocasie / Full ILU
115  camera route://5 or EMPTY
110  SYN / loops / fullscreen VT
```

---

## Channel 5 — CAM ingest (render-only)

| Layer | Sofie mapping id | AMCP shape | Durable path / payload | When |
|------:|------------------|------------|------------------------|------|
| **10** | `casparcg_pgm_camera_ingest` | `PLAY 5-10 DECKLINK DEVICE 1 FORMAT 1080P5000` (or `dshow://…`) | live input | Opened once; looks sample via `route://5` |

Never `PLAY … DECKLINK` on ch3/4 — second open fails (`Could not enable video input`).

---

## Durable media inventory (PLAY paths)

Caspar `media-path` layout (extensionless PLAY; Package Manager needs extension):

### `loops/`

| PLAY path | Channels / layers | Role |
|-----------|-------------------|------|
| `loops/bg_loop` | **1-110** (always); sometimes **4-110** under weather restore | LED baseline / Full bed |
| `loops/db_loop` | **3-118** (DoubleBox) | Alpha DoubleBox frame |
| `loops/bg_music_a` | **1-80** + **2-80** | Main kolíska bed |
| `loops/bg_music_c` | **1-80** + **2-80** | ŠPORT bed |

### `wipes/` (PGM overlays — one layer each)

| PLAY path | Layer | Mapping |
|-----------|------:|---------|
| `wipes/wipe` | **205** | `casparcg_effects_player_pgm` |
| `wipes/wipe_sjv` | **206** | `casparcg_effects_player_pgm_sjv` |
| `wipes/wipe_sport` | **207** | `casparcg_effects_player_pgm_sport` |
| `wipes/wipe_pocasie` | **208** | `casparcg_effects_player_pgm_pocasie` |

All use straight→premul `videoFilter` (`premultiply=inplace=1`) and mixer `keyer: false`.

### `assets/`

| PLAY path | Channels / layers | Role |
|-----------|-------------------|------|
| `assets/pod_headline` | **1-112** | LED headline pod underlay |
| `assets/headline_sfx` | **1-80** + **2-80** | Headline sting hit |
| `assets/countup` | **2-123** | Logo + seconds countup |
| `assets/intro_*` (e.g. `intro_michal`) | **2-210** | Intro / znelka overlay |
| `assets/outro` | **2-210** | Outro jingle overlay |
| `assets/bg_pocasie` | **4-116** | Weather map under `gfx/pocasie` |

### `clips/`

| PLAY path | Channels / layers | Role |
|-----------|-------------------|------|
| `clips/HEADLINE*` / editorial ILU | **1-115** | LED headline ILU |
| `clips/<story ILU>` | **3-116** / **4-116** | DoubleBox / Full story ILU |
| `clips/<SYN|VT|cluster…>` | **3-110** / **4-110** | Editorial VT on active look |

Filenames are rundown-specific; folders are durable.

---

## Durable HTML templates (CG)

`CG {3\|4}-121 ADD 1 "<template>" 1 {json}` — templates under `template-path/gfx/…`.

| Template (`clipName`) | Typical look | Role |
|----------------------|--------------|------|
| `gfx/l3d-headline` | **4-121** | Opening headline bars |
| `gfx/l3d-tema` | **3-121** | Topic line on DoubleBox |
| `gfx/l3d-syn` | **4-121** | SYN name strap |
| `gfx/l3d-mod` | **4-121** | Presenter MOD |
| `gfx/l3d-predstavovak` | → plays as `gfx/l3d-syn` | Guest introduce alias |
| `gfx/l3d-sjv` | **4-121** | Správy jednou vetou |
| `gfx/l3d-sport` | **4-121** | ŠPORT kicker |
| `gfx/l3d-odporucanie` | **4-121** | End tip / odporúčanie |
| `gfx/pocasie` | **4-121** | Weather HTML over `bg_pocasie` |
| `gfx/headline-fallback` | **1-121** (optional) | LED ILU chrome only |

Story L3Ds are **never** on LED as the primary copy path — watch **PGM ch2** (`route://`).

---

## Sofie mapping id → Caspar address (defaults)

| Mapping id | Ch | Layer |
|------------|---:|------:|
| `casparcg_audio_bed` | 1 | 80 |
| `casparcg_clip_player_preview` | 1 | 100 |
| `casparcg_clip_player1` | 1 | 110 |
| `casparcg_led_pod_headline` | 1 | 112 |
| `casparcg_ilu_player` | 1 | 115 |
| `casparcg_graphics_ticker` | 1 | 120 |
| `casparcg_graphics_l3d` | 1 | 121 |
| `casparcg_graphics_strap` | 1 | 122 |
| `casparcg_effects_player` | 1 | 200 |
| `casparcg_audio_bed_pgm` | 2 | 80 |
| `casparcg_pgm_route` | 2 | 110 |
| `casparcg_graphics_logo` | 2 | 123 |
| `casparcg_effects_player_pgm` | 2 | 205 |
| `casparcg_effects_player_pgm_sjv` | 2 | 206 |
| `casparcg_effects_player_pgm_sport` | 2 | 207 |
| `casparcg_effects_player_pgm_pocasie` | 2 | 208 |
| `casparcg_intro_player_pgm` | 2 | 210 |
| `casparcg_clip_player2` | 3 | 110 |
| `casparcg_pgm_camera` | 3 | 115 |
| `casparcg_pgm_ilu_player` | 3 | 116 |
| `casparcg_pgm_doublebox_loop` | 3 | 118 |
| `casparcg_graphics_pgm_l3d` | 3 | 121 |
| `casparcg_clip_player2_b` | 4 | 110 |
| `casparcg_pgm_camera_b` | 4 | 115 |
| `casparcg_pgm_ilu_player_b` | 4 | 116 |
| `casparcg_pgm_doublebox_loop_b` | 4 | 118 |
| `casparcg_graphics_pgm_l3d_b` | 4 | 121 |
| `casparcg_pgm_camera_ingest` | 5 | 10 |
| `casparcg_debug_label_*` | 1–5 | 990 |

---

## RE piece → durable Caspar target

| RE piece type | Caspar |
|---------------|--------|
| `bg-loop` | **1-110** `loops/bg_loop` |
| `bg-music` | **1-80** + **2-80** `loops/bg_music_*` |
| `headline` | **1-115** `clips/…` (+ optional **1-112** pod) |
| `camera` | look **3/4-115** = `route://5` (ingest **5-10**) |
| `doublebox-ilu` | look **3-116** + **3-118** `db_loop` |
| `video` / SYN | look **3/4-110** |
| `l3d-*` / `weather` | look **3/4-121** CG (+ weather **4-116** `bg_pocasie`) |
| `logo-bug` | **2-123** (countup owns production path) |
| `wipe` | **2-205…208** by file + delayed **2-110** `route://` |
| `intro` | **2-210** `assets/intro_*` |
| `outro` | **2-210** `assets/outro` |
| `ilu-zaver` | LED ILU + Full look compose (see show flow) |

---

## Example AMCP from a live take (classical wipe into DoubleBox)

```text
LOADBG 2-205 "wipes/wipe" … VF "premultiply=inplace=1"     ← PRELOAD (hot)
PLAY   3-116 "clips/…" … FILL …                          ← look A ILU
PLAY   3-118 "loops/db_loop" LOOP                        ← frame
PLAY   3-115 "route://5" … FILL …                        ← cam
PLAY   2-205                                             ← hot PLAY (no filename)
PLAY   2-110 "route://3" …                               ← air cut under cover
CG     3-121 ADD 1 "gfx/l3d-tema" 1 {…}
```

Healthy hot wipe: `PLAY 2-205` **without** a filename after LOADBG, Caspar
`Latency: 0`. Cold failure mode: `PLAY 2-205 "wipes/wipe"` with Latency 22–34 after
another wipe file destroyed the LOADBG on the same layer.

---

## Related

| Doc | Role |
|-----|------|
| [`OUTPUT_TOPOLOGY.md`](./OUTPUT_TOPOLOGY.md) | LED vs PGM policy, ops `caspar.config` |
| [`DOUBLEBOX-PGM.md`](./DOUBLEBOX-PGM.md) | FILL/CROP numbers, wipe checklist |
| [`SPRAVY-SHOW-FLOW.md`](./SPRAVY-SHOW-FLOW.md) | Show spine / which wipe when |
| [`adr/0002-wipe-prebuild-bg-channels.md`](../adr/0002-wipe-prebuild-bg-channels.md) | Why BG 3/4 exist |
| [`adr/0003-cam-ingest-channel.md`](../adr/0003-cam-ingest-channel.md) | Why CAM is ch5 |
| [sofie-demo-blueprints #121](https://github.com/tojemoc/sofie-demo-blueprints/pull/121) | Code: wipe layers 205–208 + hard-cut overlap |
