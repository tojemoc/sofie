# Shared Sofie manifests (megarepo source of truth)

Piece / part / segment type manifests and the SPRÁVY smoke rundown live **here** —
in the `tojemoc/sofie` megarepo — not in `sofie-demo-blueprints` or `unopus`.

```
PLAY 2-116 "dshow://video=OBS Virtual Camera"
```

| File | Purpose |
|------|---------|
| `sofie-rundown-editor-piece-types.json` | Piece type definitions and GFX preview templates |
| `sofie-rundown-editor-part-types.json` | Part presets (ILU, DoubleBox, SYN, GFX, Intro, …) |
| `sofie-rundown-editor-segment-types.json` | Segment presets (Headlines, Opening, …) |
| `spravy-v3-smoke-rundown.json` | End-to-end smoke rundown (`spravy-v3-smoke`) |

Piece types are kept in sync with the smoke rundown. Sofie **Intro** parts need
piece type **`intro`** (“Intro overlay” — alpha/znelka on **PGM layer 210**, never
LED), not a plain `video`. Also keep `bg-loop` and `wipe`. Thematic DoubleBox
parts use piece type **`doublebox-ilu`** (PGM left window) — not `headline` —
plus `l3d-tema` + `camera`. Legacy demo pieces
`remote` / `split` / `guest` (and part presets REMI / DVE / Guest) were removed.

Smoke Intro uses `assets/intro_michal` (disk `assets/intro_michal.mov`). LED
allow-list is **headline ILU + loop only** (blueprints **baseline**
`loops/bg_loop` — not listed as a RE piece). Presenter MOD and other L3Ds are
**PGM**. See integration log and
`docs/integration/RE-READINESS-AND-PLAYOUT-UX.md`.
Wipes: piece type `wipe` → Caspar PGM layer 200 (`wipes/wipe`; story blocks may
use `wipes/wipe_sjv`, `wipes/wipe_sport`, `wipes/wipe_pocasie`). See
`docs/integration/DOUBLEBOX-PGM.md` and
`docs/integration/handoffs/blueprints-baseline-bg-loop.md`.

## Media folder layout (`bg-loop`, wipe, clips, assets)

Three different strings get confused — keep them separate:

| Role | Example | Notes |
|------|---------|--------|
| **Disk filename** | `clips/HEADLINE1.mov` (or `.mp4`) | Real file under `casparcgMediaFolder` / ingest root |
| **Piece / ExpectedPackage path** | Prefer disk name with extension for clips (`clips/HEADLINE1.mov`) | Package Manager `LOCAL_FOLDER` looks up this exact relative path |
| **Caspar PLAY path** | `clips/HEADLINE1` | What blueprints put on the timeline after `toCasparPlayPath` (strips `.mp4`/`.mov`/…). Caspar resolves it to the on-disk file |

CLS media listings also omit extensions; that is Caspar’s inventory display, **not** the contract for RE payloads or Package Manager paths. This blueprints stack uses extensionless values only as **PLAY** paths (and for some loops/wipes/assets piece `fileName`s that are then mapped for PM via `toPackageManagerPath` → `.mov`).

**Package Manager vs Caspar:** Sofie Core readiness (“can't be found on the
playout system”) checks ExpectedPackage paths with a `LOCAL_FOLDER` lookup —
that needs the **disk filename including extension**. Demo blueprints map
extensionless `loops/` / `wipes/` / `assets/` PLAY-style paths to `.mov` when
emitting ExpectedPackages (`toPackageManagerPath`); timeline `PLAY` still uses
`toCasparPlayPath`. Prefer storing clips with their real extension
(disk: `clips/HEADLINE1.mov`) so PM does not have to guess.

```text
<casparcgMediaFolder>/
  loops/bg_loop.mov           ← disk; PLAY / piece path often `loops/bg_loop`
  wipes/wipe.mov              ← disk; PLAY / piece path often `wipes/wipe`
  assets/intro_michal.mov     ← disk; intro piece `fileName` often `assets/intro_michal`
  clips/HEADLINE1.mov         ← disk filename (ILU / VT); PLAY → `clips/HEADLINE1`
  clips/ILU ….mp4
  clips/SYN ….mp4
```

- Two levels only: `<subdir>/<file>` — no `spravy/<rundownId>/…` nesting.
- Rundown Editor `mediaPick.subdir` (`loops` / `wipes` / `clips` / `assets`) only
  scopes the picker UI under the ingest root — the saved `fileName` must include
  the subdir.
- `bg-loop` plays on LED ClipPlayer1 (layer 110). Baseline also loops
  `loops/bg_loop` at priority 0; a `bg-loop` piece overrides at priority 1.
  Blueprints baseline uses the same basename
  ([sofie-demo-blueprints#58](https://github.com/tojemoc/sofie-demo-blueprints/pull/58)).
  Smoke does not carry a `bg-loop` piece on Intro.
- `intro` must PLAY on **PGM** (target layer 210). A `404` on
  `PLAY … "clips/HEADLINE1"` means the file is missing from the Caspar
  media folder — ingest/copy it; the rundown path is already correct.
- Do **not** put loops under `clips/` — those are editorial clips.
- HTML templates (`gfx/l3d-headline`, `gfx/l3d-tema`, …) live under Caspar
  **template-path**, not the media folder — they are **not** ExpectedPackages
  and do not drive “can't be found on the playout system” (that warning names
  the Sofie **source layer**, e.g. Lower Third / Titles, not `gfx/` vs `pgm/`).

## Consumers

- **Rundown Editor (`rundown-editor/` / unopus)** loads the three type JSON files at
  startup and via **Settings → Connection → Reload type manifests from assets**.
  When nested in this megarepo it resolves `../assets/` from the editor root.
- **Demo Blueprints (`blueprints/`)** uses `spravy-v3-smoke-rundown.json` as the
  ingest smoke-test fixture (same nested-megarepo resolution).

Do not reintroduce copies under `blueprints/assets/` or `rundown-editor/assets/`.
Edit these files in PRs against `tojemoc/sofie`.

## Standalone CI / Docker (pin + checksums)

Standalone clones must **not** download from mutable refs (`main`, `cursor/…`).
Fetch scripts pin an **immutable sofie commit SHA** and verify each file’s **SHA-256**
before exporting `SOFIE_MEGAREPO_ASSETS`. See
[`docs/integration/MEGAREPO-ASSETS-FETCH.md`](../docs/integration/MEGAREPO-ASSETS-FETCH.md)
and [unopus PR #45](https://github.com/tojemoc/unopus/pull/45).

When you change files here, bump the consumer pin **and** checksums in the same follow-up
PR(s) — otherwise CI will fail closed on mismatch.
