# Handoff: Blueprints — Intro overlay on PGM (not LED)

**Copy everything below the line into a Cursor agent session on
`tojemoc/sofie-demo-blueprints` (branch off `develop`).**

---

## Problem (from Caspar / Softie)

1. **Intro plays on LED today.** `playLayer: 'effects'` maps to
   `CasparCGLayers.CasparCGEffectsPlayer` → **LED channel, layer 200**.
   Production rule: **Intro must never play on LED.** LED is reserved for
   **headlines + `loops/360_loop` only**.
2. **Intro must sit above everything on PGM** (camera, ILU when remapped, L3Ds,
   logo-bug, and story-block wipes). Wipe already uses PGM layer **200**
   (`CasparCGPgmEffectsPlayer`). Intro needs a **higher** PGM layer (recommend **210**).

Smoke fixture (sofie megarepo `assets/spravy-v3-smoke-rundown.json`) now uses:

- piece type `intro`, `fileName: "wipes/360s_ZNELKA.mov"`, duration 12s
- **no** `bg-loop` piece on the Intro part (baseline loop still covers LED)
- **no** wipe on HEADLINE / Intro parts (story-block wipes unchanged)

## Required code changes

### 1. New PGM intro mapping (layer 210)

In `packages/blueprints/src/base/studio/applyConfig/mappings/casparcgLayers.ts`:

```ts
export const PgmChannelLayers = {
	ClipPlayer: 110,
	IluPlayer: 115,
	Camera: 116,
	GraphicsLowerThird: 121,
	GraphicsLogo: 123,
	EffectsPlayer: 200, // wipe
	IntroOverlay: 210, // intro — above wipe + all compose layers
} as const
```

In `packages/blueprints/src/base/studio/layers.ts` add:

```ts
/** PGM intro / znelka overlay — above wipe (200). Never map to LED. */
CasparCGPgmIntroPlayer = 'casparcg_intro_player_pgm',
```

In `packages/blueprints/src/base/studio/applyConfig/mappings/casparcg.ts` add mapping:

```ts
[CasparCGLayers.CasparCGPgmIntroPlayer]: literal<BlueprintMapping<TSR.MappingCasparCGLayer>>({
	device: TSR.DeviceType.CASPARCG,
	deviceId: 'casparcg0',
	lookahead: LookaheadMode.NONE,
	options: {
		mappingType: TSR.MappingCasparCGType.Layer,
		channel: pgmChannel,
		layer: PgmChannelLayers.IntroOverlay,
	},
}),
```

Leave `CasparCGEffectsPlayer` on LED for legacy Sofie News Opener / titles if still needed,
or also point titles at `CasparCGPgmIntroPlayer` (same visual rule).

### 2. Route `playLayer: 'effects'` → PGM intro

In `packages/blueprints/src/base/showstyle/helpers/clips.ts`
`layeredVideoCasparLayer`:

```ts
if (playLayer === 'effects') return CasparCGLayers.CasparCGPgmIntroPlayer
if (playLayer === 'wipe') return CasparCGLayers.CasparCGPgmEffectsPlayer
return CasparCGLayers.CasparCGClipPlayer1
```

Update comments in `objects.ts`, `rundownEditorTypes.ts`, `part-adapters/intro.ts`:
**Intro = PGM layer 210, not LED.**

### 3. Tests

- `introOverlay.spec.ts`: expect `CasparCGPgmIntroPlayer` (not `CasparCGEffectsPlayer`).
- Smoke fixture no longer has `bg-loop` or wipe on `seg-intro` — adjust counts:
  layered videos on Intro part = **1** (overlay only).
  Overlay clip name contains `360s_ZNELKA` (not `introMichal`).
- `casparcgMappings.spec.ts`: assert new mapping → channel 2, layer 210.

After megarepo assets land, bump `scripts/fetch-sofie-megarepo-assets.sh` `REFS` to the
merged sofie commit SHA (newest first).

### 4. Verify

```bash
yarn test:blueprints
yarn lint
cd packages/blueprints && yarn dist
```

Upload bundle → Softie → **Apply config** (new mapping id) → re-ingest smoke rundown.

**AMCP expect on Intro take:**

```text
PLAY <pgm>-210 "wipes/360s_ZNELKA" …
```

**Must not** appear on LED channel (`PLAY 1-200 …` for intro).

LED during Intro: baseline / bg-loop on **1-110** only.
LED during Headlines: ILU **1-115** + headline CG as today; loop on **1-110**.

## Out of scope here

- Headline `404 PLAY FAILED` for `spravy/…/clips/headline1` — path/convention is correct;
  the file is missing from the Caspar media folder (Package Manager / copy). See
  megarepo `docs/integration/SPRAVY-V2-INTEGRATION.md` troubleshooting.
