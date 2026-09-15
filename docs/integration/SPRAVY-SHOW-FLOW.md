# SPRÁVY show flow — LED vs PGM (smoke contract)

Canonical operator sequence for `assets/spravy-v3-smoke-rundown.json` and the
hypercomposed Caspar stack. Topology layers: [`OUTPUT_TOPOLOGY.md`](./OUTPUT_TOPOLOGY.md).
DoubleBox geometry: [`DOUBLEBOX-PGM.md`](./DOUBLEBOX-PGM.md).

## Spine (4 topics)

| # | Block | LED (ch1) | PGM (ch2) | Transition |
|---|-------|-----------|-----------|------------|
| 1 | Headlines (3×) | `bg_loop` + ILU (slot or bypass fullscreen) | Fullscreen OBS cam + `l3d-headline` + logo-bug | — |
| 2 | Intro | `bg_loop` only | Intro overlay (`assets/intro_*`) on layer 210 | — |
| 3 | MOD | `bg_loop` | Fullscreen OBS + `l3d-predstavovak` / `l3d-mod` | — |
| 4 | Topic DoubleBox | `bg_loop` | `db_loop` (118) over CAM (~80% right) + ILU left + topic L3D + bug | Wipe into topic / new story |
| 5 | Topic SYN | `bg_loop` | Fullscreen SYN + timed `l3d-syn` (+ optional Zdroj) | **Hard cut** from DB (no wipe) |
| 6 | SYN → SYN | `bg_loop` | Hard cut; L3D duration ends before next SYN | **Hard cut** |
| 7 | SYN → DB (same topic) | `bg_loop` | Back to DoubleBox | **Hard cut** |
| 8 | SYN → new topic | `bg_loop` | DoubleBox | **Wipe** |
| 9 | SJV (3–5 SYNs) | `bg_loop` | Timed `l3d-sjv` over SYNs | `wipes/wipe_sjv` on **first SYN** (no empty open Take) |
| 10 | Šport (2–5) | `bg_loop` | Timed `l3d-sport` (`kicker=ŠPORT`) | `wipes/wipe_sport` on **first SYN** |
| 11 | Počasie | `bg_loop` | Transparent `gfx/pocasie` on Full look (**routed**; look clip underlay) + logo-bug; or bypass `assets/weather` | `wipes/wipe_pocasie` |
| 12 | Odporúčanie / Závěr Avízo | `bg_loop` + windowed `ilu-zaver` (~60%) | Full-look CAM + `l3d-odporucanie` — **no** `db_loop`, **no** LED `route://4` | Normal wipe |
| 12b | optional SYN | `bg_loop` | Hard cut ILU↔SYN | Hard cut |
| 13 | Outro | `bg_loop` | `assets/outro` on layer 210 (above everything) | — |

## Templates (demo-assets)

| Piece type | Caspar | Source |
|------------|--------|--------|
| `l3d-predstavovak` / `l3d-mod` | `gfx/l3d-predstavovak` | megarepo `spravy_360_predstavovak` |
| `l3d-sjv` | `gfx/l3d-sjv` | megarepo `spravy_360_jednou_vetou` (+ kicker) |
| `l3d-sport` | `gfx/l3d-sport` | same shell, default kicker `ŠPORT` |
| `l3d-odporucanie` | `gfx/l3d-odporucanie` | same shell, **no** kicker |

## Timed L3D / Zdroj

RE piece `start` (seconds) → ingest `objectTime` (ms); `duration` (seconds) → piece enable duration.
Caspar STOP runs the template slide-out. Set SYN L3D duration shorter than the clip so it
cannot overflow into the next SYN even if Takes are early.

## Media notes

- DoubleBox frame: `loops/db_loop` (production may call the file `dp_loop.mov` — rename/symlink).
- Weather HTML (`bypass: false` in smoke): transparent `gfx/pocasie` over Full-look
  `assets/bg_pocasie` underlay on the ILU layer (map loop under city cards; `bg_loop`
  stays on the clip layer).
- Weather bypass clip (when wired): PLAY `assets/weather` premade animation.
- Outro: PLAY `assets/outro` on PGM intro layer 210 (jingle, no bed music).
- Headlines: each Take also PLAYs `assets/headline_sfx` (disk `headline_sfx.wav`) on
  LED+PGM audio beds.
- Závěr + Avízo: `ilu-zaver` windowed (~`PGM_DOUBLEBOX_ILU_FILL`, ≈60–68%) on **LED 115**
  over `bg_loop`. Full look keeps fullscreen CAM + `l3d-odporucanie` on PGM — do **not**
  `route://4` onto LED.

## ILU bypass

`headline.iluPrerendered` (bypass) ON → alpha `.mov` FILL `0 0 1 1` on LED over `bg_loop`
(+ `assets/pod_headline` on layer 112 during headlines).
OFF → cover-cropped slot + `gfx/headline-fallback` chrome (no squish).
Default ILU mixer volume is **0.5** when RE leaves volume unset.
