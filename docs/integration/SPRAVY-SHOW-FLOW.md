# SPRÁVY show flow — LED vs PGM (smoke contract)

Canonical operator sequence for `assets/spravy-v3-smoke-rundown.json` and the
hypercomposed Caspar stack. Topology layers: [`OUTPUT_TOPOLOGY.md`](./OUTPUT_TOPOLOGY.md).
DoubleBox geometry: [`DOUBLEBOX-PGM.md`](./DOUBLEBOX-PGM.md).

## Spine (5 topics)

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
| 9 | SJV (3–5 SYNs) | `bg_loop` | Timed `l3d-sjv` over SYNs | `wipes/wipe_sjv` |
| 10 | Šport (2–5) | `bg_loop` | Timed `l3d-sport` (`kicker=ŠPORT`) | `wipes/wipe_sport` |
| 11 | Počasie | `bg_loop` | Weather **bypass** default (`assets/weather`) + logo-bug | `wipes/wipe_pocasie` |
| 12 | Odporúčanie | `bg_loop` | DoubleBox + `l3d-odporucanie` (no kicker) | Normal wipe |
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
- Weather bypass default: `bypass` absent or `true` → PLAY `assets/weather` (not HTML stub).
- Outro: PLAY `assets/outro` on PGM intro layer 210 (jingle, no bed music).

## ILU bypass

`headline.iluPrerendered` (bypass) ON → alpha `.mov` FILL `0 0 1 1` on LED over `bg_loop`.
OFF → cover-cropped slot + `gfx/headline-fallback` chrome (no squish).
