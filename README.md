# Sofie megarepo (`tojemoc/sofie`)

A **superproject** that aggregates the forks and assets used for the **SPRÁVY / 360 sekúnd** Sofie TV-automation demo stack. It is the coordination layer for local Cursor Cloud development: submodule metadata (`.gitmodules`), agent instructions (`AGENTS.md`), and cross-repo integration docs.

Application code lives in the four component repositories below. This repo itself tracks documentation and configuration (including `.gitmodules`) — not committed application gitlinks (see [Workspace layout](#workspace-layout)).

## What’s in the stack

| Path | Repository | Upstream | Role |
|------|------------|----------|------|
| `core/` | [tojemoc/sofie-core](https://github.com/tojemoc/sofie-core) | [Sofie-Automation/sofie-core](https://github.com/Sofie-Automation/sofie-core) | Sofie Core — Meteor 3 + Node backend + React (Vite) WebUI |
| `blueprints/` | [tojemoc/sofie-demo-blueprints](https://github.com/tojemoc/sofie-demo-blueprints) | [SuperFlyTV/sofie-demo-blueprints](https://github.com/SuperFlyTV/sofie-demo-blueprints) | Demo blueprints — builds `*-bundle.js` uploaded into Core |
| `rundown-editor/` | [tojemoc/unopus](https://github.com/tojemoc/unopus) | [SuperFlyTV/sofie-automation-rundown-editor](https://github.com/SuperFlyTV/sofie-automation-rundown-editor) | Rundown Editor (Unopus) — Express + Socket.IO / React |
| `demo-assets/` | [tojemoc/sofie-demo-assets](https://github.com/tojemoc/sofie-demo-assets) | [mint-dewit/casparcg-vue-boilerplate](https://github.com/mint-dewit/casparcg-vue-boilerplate) (history base; not a GitHub fork) | CasparCG static HTML templates (`template/gfx/*.html`) — Vue pipeline removed Sept 2026 |

**Playout path:** Rundown Editor → Sofie Core → Playout Gateway → CasparCG (v2 HTML templates from `demo-assets`).

End-to-end rundown schema and layout map: [`docs/integration/RUNDOWN-SCHEMA-AND-LAYOUT.md`](docs/integration/RUNDOWN-SCHEMA-AND-LAYOUT.md).
Cross-repo status, template catalogue, and verification checklist live in [`docs/integration/SPRAVY-V2-INTEGRATION.md`](docs/integration/SPRAVY-V2-INTEGRATION.md).

## Workspace layout

Declared in [`.gitmodules`](.gitmodules). In the Cursor Cloud environment the four directories are **standalone clones** provisioned into the VM snapshot — the superproject does **not** commit gitlinks, so `git submodule update --init` does nothing here. Update each project with normal `git` inside its directory; do not `git add` those trees into this repo.

Agent-oriented run/lint/build notes: [`AGENTS.md`](AGENTS.md).

### Services (dev)

| Service | Dir | Port | Command |
|---------|-----|------|---------|
| Sofie Core | `core` | 3000 (API/DDP), 3005 (WebUI) | `yarn dev` |
| Rundown Editor backend | `rundown-editor` | 3010 | `yarn dev:backend` |
| Rundown Editor frontend | `rundown-editor` | 5173 | `yarn dev:ui` |
| Blueprints docs (optional) | `blueprints` | 3030 | `yarn watch:docs` |
| CasparCG template serve (optional) | `demo-assets` | 8080 | `yarn serve` |

---

## Changes from upstream

Below are **merged pull requests** on the `tojemoc` forks (and this megarepo) that diverge from — or, for `demo-assets`, extend — the upstream baselines. Lists are current as of **2026-11-16** (older tables frozen at 2026-07-17; newer PRs in collapsible lists below). Open/unmerged work is omitted.

### Megarepo — [tojemoc/sofie](https://github.com/tojemoc/sofie)

Coordination-only repo (docs + submodule config). No upstream Sofie product.

| PR | Merged | Title |
|----|--------|-------|
| [#1](https://github.com/tojemoc/sofie/pull/1) | 2026-06-11 | Set up Cursor Cloud dev environment for Sofie superproject |
| [#2](https://github.com/tojemoc/sofie/pull/2) | 2026-06-23 | chore: document demo-assets submodule and hypercomposed Caspar path |
| [#3](https://github.com/tojemoc/sofie/pull/3) | 2026-06-25 | docs: SPRÁVY v2 integration log and blueprints agent handoff |
| [#4](https://github.com/tojemoc/sofie/pull/4) | 2026-06-28 | docs: update SPRÁVY integration log (June 28) |
| [#5](https://github.com/tojemoc/sofie/pull/5) | 2026-07-15 | docs: isolate ILU MIXER FILL onto Caspar layer 115 |
| [#6](https://github.com/tojemoc/sofie/pull/6) | 2026-07-15 | docs: VID clip hardening + RE media picker free-text |

### Sofie Core — [tojemoc/sofie-core](https://github.com/tojemoc/sofie-core)

Fork of [Sofie-Automation/sofie-core](https://github.com/Sofie-Automation/sofie-core). Default branch: `main`.

| PR | Merged | Title |
|----|--------|-------|
| [#1](https://github.com/tojemoc/sofie-core/pull/1) | 2026-06-09 | docs: add Cursor Cloud development environment instructions |
| [#2](https://github.com/tojemoc/sofie-core/pull/2) | 2026-06-15 | feat(playout-gateway): poll vMix inputs into Core mediaObjects |
| [#3](https://github.com/tojemoc/sofie-core/pull/3) | 2026-06-15 | ci: enable GHCR docker image push in Node CI |
| [#4](https://github.com/tojemoc/sofie-core/pull/4) | 2026-06-15 | ci: fork-friendly GHCR Docker release workflow |
| [#5](https://github.com/tojemoc/sofie-core/pull/5) | 2026-06-17 | Fix rundown view crash when tTimers or studio settings are missing |

**Highlights vs upstream:** vMix input polling into Core `mediaObjects`; fork-friendly GHCR CI; WebUI crash guard when timer/studio settings are missing.

### Demo blueprints — [tojemoc/sofie-demo-blueprints](https://github.com/tojemoc/sofie-demo-blueprints)

Fork of [SuperFlyTV/sofie-demo-blueprints](https://github.com/SuperFlyTV/sofie-demo-blueprints). Intended branch: `develop` (GitHub default and `.gitmodules` tracking branch; SPRÁVY / Caspar work). Earlier line of work landed on `vmix-demo-blueprints` and briefly on `main` (some of those `main` PRs were reverted).

#### `develop` — SPRÁVY / CasparCG

| PR | Merged | Title |
|----|--------|-------|
| [#26](https://github.com/tojemoc/sofie-demo-blueprints/pull/26) | 2026-06-25 | feat: wire Spravy v2 CasparCG HTML templates (Friday MVP) |
| [#27](https://github.com/tojemoc/sofie-demo-blueprints/pull/27) | 2026-06-25 | fix: add entityType to rundown editor piece types JSON |
| [#28](https://github.com/tojemoc/sofie-demo-blueprints/pull/28) | 2026-06-25 | feat: hypercomposed CasparCG — route graphics to LED channel 1 |
| [#29](https://github.com/tojemoc/sofie-demo-blueprints/pull/29) | 2026-06-25 | SPRÁVY v2: ILU package tracking and config-driven media containers |
| [#30](https://github.com/tojemoc/sofie-demo-blueprints/pull/30) | 2026-06-25 | feat(spravy): simplify rundown types and bump smoke rundown to v3 |
| [#31](https://github.com/tojemoc/sofie-demo-blueprints/pull/31) | 2026-06-26 | Sync assets and blueprints with unopus rundown editor schema |
| [#32](https://github.com/tojemoc/sofie-demo-blueprints/pull/32) | 2026-06-27 | Fix SPRÁVY v3 ingest ↔ Caspar playout loop |
| [#33](https://github.com/tojemoc/sofie-demo-blueprints/pull/33) | 2026-06-27 | PLAY ILU clips on Caspar layer 110 for gfx/headline pieces |
| [#34](https://github.com/tojemoc/sofie-demo-blueprints/pull/34) | 2026-06-28 | Cursor/fix headline ilu play layer 715a |
| [#35](https://github.com/tojemoc/sofie-demo-blueprints/pull/35) | 2026-07-09 | Support ILU fallback mode with Caspar media layer playback |
| [#37](https://github.com/tojemoc/sofie-demo-blueprints/pull/37) | 2026-07-13 | Fix spravy-v3-smoke-rundown.json for Rundown Editor import |
| [#38](https://github.com/tojemoc/sofie-demo-blueprints/pull/38) | 2026-07-13 | Fix headline L3D display, ILU PLAY, and editor piece types |
| [#39](https://github.com/tojemoc/sofie-demo-blueprints/pull/39) | 2026-07-14 | Frame headline ILU media with MIXER FILL matching HTML #ilu-slide |
| [#40](https://github.com/tojemoc/sofie-demo-blueprints/pull/40) | 2026-07-15 | Isolate headline ILU MIXER FILL onto dedicated Caspar layer 115 |
| [#41](https://github.com/tojemoc/sofie-demo-blueprints/pull/41) | 2026-07-15 | fix Package Manager accessors missing LOCAL_FOLDER type |
| [#42](https://github.com/tojemoc/sofie-demo-blueprints/pull/42) | 2026-07-15 | Cursor/pm accessor type ingest 09c3 |
| [#43](https://github.com/tojemoc/sofie-demo-blueprints/pull/43) | 2026-07-15 | fix: harden VID/video clip ingest for Softie |

#### `vmix-demo-blueprints` — vMix-first line

| PR | Merged | Title |
|----|--------|-------|
| [#6](https://github.com/tojemoc/sofie-demo-blueprints/pull/6) | 2026-06-09 | Cursor/vmix first newsroom architecture 37a9 |
| [#9](https://github.com/tojemoc/sofie-demo-blueprints/pull/9) | 2026-06-09 | Cursor/blueprint release workflow 2266 |
| [#10](https://github.com/tojemoc/sofie-demo-blueprints/pull/10) | 2026-06-10 | docs: add AGENTS.md with Cursor Cloud development instructions |
| [#11](https://github.com/tojemoc/sofie-demo-blueprints/pull/11) | 2026-06-10 | feat: Hello vMix demonstration blueprint |
| [#12](https://github.com/tojemoc/sofie-demo-blueprints/pull/12) | 2026-06-12 | feat(vmix): registry routing for stock RE parts (milestones 0-2) |
| [#13](https://github.com/tojemoc/sofie-demo-blueprints/pull/13) | 2026-06-12 | fix(schema): restore input table UI for studio config sources |
| [#14](https://github.com/tojemoc/sofie-demo-blueprints/pull/14) | 2026-06-12 | Cursor/fix studio input tables 6d70 |
| [#15](https://github.com/tojemoc/sofie-demo-blueprints/pull/15) | 2026-06-17 | Publish pre-release blueprints on main push and add vMix-only playout routing |
| [#16](https://github.com/tojemoc/sofie-demo-blueprints/pull/16) | 2026-06-17 | Fix CI checkout failure for workflow_dispatch release tags |
| [#17](https://github.com/tojemoc/sofie-demo-blueprints/pull/17) | 2026-06-17 | Fix vMix Input Registry overrides not applying when preset omits vmix… |
| [#18](https://github.com/tojemoc/sofie-demo-blueprints/pull/18) | 2026-06-17 | .github/workflows: Migrate workflows to Blacksmith runners |
| [#19](https://github.com/tojemoc/sofie-demo-blueprints/pull/19) | 2026-06-20 | PoC: vMix GT text from Rundown Editor graphics with timed overlays |
| [#21](https://github.com/tojemoc/sofie-demo-blueprints/pull/21) | 2026-06-22 | Cursor/companion import vmix merge 04e2 |
| [#22](https://github.com/tojemoc/sofie-demo-blueprints/pull/22) | 2026-06-23 | Cursor/vmix macros UI routing docs 04e2 |
| [#23](https://github.com/tojemoc/sofie-demo-blueprints/pull/23) | 2026-06-23 | fix: smoke rundown import and vMix shelf ad-lib VT errors |
| [#24](https://github.com/tojemoc/sofie-demo-blueprints/pull/24) | 2026-06-23 | fix: smoke rundown import for current Rundown Editor |

#### `main` — early experiments (several reverted)

| PR | Merged | Title |
|----|--------|-------|
| [#1](https://github.com/tojemoc/sofie-demo-blueprints/pull/1) | 2026-06-01 | .github/workflows: Migrate workflows to Blacksmith runners |
| [#2](https://github.com/tojemoc/sofie-demo-blueprints/pull/2) | 2026-06-01 | Revert ".github/workflows: Migrate workflows to Blacksmith runners" |
| [#3](https://github.com/tojemoc/sofie-demo-blueprints/pull/3) | 2026-06-09 | docs: add AGENTS.md with Cursor Cloud development instructions |
| [#4](https://github.com/tojemoc/sofie-demo-blueprints/pull/4) | 2026-06-09 | Implement vMix-first newsroom architecture |
| [#5](https://github.com/tojemoc/sofie-demo-blueprints/pull/5) | 2026-06-09 | Revert "Implement vMix-first newsroom architecture" |
| [#7](https://github.com/tojemoc/sofie-demo-blueprints/pull/7) | 2026-06-09 | ci: add automated blueprint release workflow |
| [#8](https://github.com/tojemoc/sofie-demo-blueprints/pull/8) | 2026-06-09 | Revert "ci: add automated blueprint release workflow" |

**Highlights vs upstream:** SPRÁVY v2 Caspar template wiring (`gfx/*`), hypercomposed LED routing, ILU media + MIXER FILL on layer 115, Package Manager accessor/media-container fixes, VID ingest hardening; separate vMix registry / GT / Companion line on `vmix-demo-blueprints`.

### Rundown Editor (Unopus) — [tojemoc/unopus](https://github.com/tojemoc/unopus)

Fork of [SuperFlyTV/sofie-automation-rundown-editor](https://github.com/SuperFlyTV/sofie-automation-rundown-editor). Default branch: `main`.

| PR | Merged | Title |
|----|--------|-------|
| [#1](https://github.com/tojemoc/unopus/pull/1) | 2026-05-17 | Add AGENTS.md for Cursor Cloud development environment |
| [#2](https://github.com/tojemoc/unopus/pull/2) | 2026-05-17 | Duopus fork: settings persistence, session auth, newsroom UX |
| [#3](https://github.com/tojemoc/unopus/pull/3) | 2026-05-17 | Fix GHCR push denied in release workflow |
| [#4](https://github.com/tojemoc/unopus/pull/4) | 2026-05-17 | .github/workflows: Migrate workflows to Blacksmith runners |
| [#5](https://github.com/tojemoc/unopus/pull/5) | 2026-05-18 | NRCS-style story creation, story library, and daily template generation |
| [#6](https://github.com/tojemoc/unopus/pull/6) | 2026-05-18 | Add NRCS → Google Sheets adapter for vMix automation |
| [#7](https://github.com/tojemoc/unopus/pull/7) | 2026-05-18 | Fix sidebar layout, story template import, and Docker persistence guidance |
| [#8](https://github.com/tojemoc/unopus/pull/8) | 2026-05-18 | Rundown template scheduling, UI fixes, and improved home lists |
| [#9](https://github.com/tojemoc/unopus/pull/9) | 2026-05-18 | Fix rundown UX, unify templates, and add Google Sheets settings |
| [#10](https://github.com/tojemoc/unopus/pull/10) | 2026-05-18 | Sheets adapter: volume (K) and contextual transitions (I) |
| [#11](https://github.com/tojemoc/unopus/pull/11) | 2026-05-21 | Template sync for generated rundowns and scrollable properties panel |
| [#12](https://github.com/tojemoc/unopus/pull/12) | 2026-05-21 | Add l3d timing columns (L/M) to Google Sheets export |
| [#13](https://github.com/tojemoc/unopus/pull/13) | 2026-05-21 | Replace video fileName text input with searchable media clip picker |
| [#14](https://github.com/tojemoc/unopus/pull/14) | 2026-05-27 | Simplify Google Sheets sync modal to push-only action |
| [#15](https://github.com/tojemoc/unopus/pull/15) | 2026-05-27 | Add optional bundled NRCS fallback for Sheets sync |
| [#16](https://github.com/tojemoc/unopus/pull/16) | 2026-05-28 | Fix bundled story script mapping to Google Sheets LongText1 |
| [#17](https://github.com/tojemoc/unopus/pull/17) | 2026-05-28 | Simplify Google Sheets sync to actual A-K structure |
| [#18](https://github.com/tojemoc/unopus/pull/18) | 2026-05-30 | Map Rundown Editor data to Google Sheets for vMix |
| [#19](https://github.com/tojemoc/unopus/pull/19) | 2026-05-31 | Google Sheets: remove NRCS push, add pull and column mappings |
| [#20](https://github.com/tojemoc/unopus/pull/20) | 2026-06-08 | Add rundown CSV export on rebuild baseline |
| [#21](https://github.com/tojemoc/unopus/pull/21) | 2026-06-09 | Rebuild baseline + rundown CSV export |
| [#22](https://github.com/tojemoc/unopus/pull/22) | 2026-06-09 | Add SESSION_COOKIE_SECURE env var for HTTP deployments |
| [#23](https://github.com/tojemoc/unopus/pull/23) | 2026-06-25 | Fix rundown layout and sidebar button overlaps |
| [#24](https://github.com/tojemoc/unopus/pull/24) | 2026-06-25 | Fix startup manifest seeding and case-sensitive part types |
| [#25](https://github.com/tojemoc/unopus/pull/25) | 2026-06-25 | Add media picker and GFX preview for Správy piece types |
| [#26](https://github.com/tojemoc/unopus/pull/26) | 2026-06-26 | feat: button-based segment/part creation from blueprint manifests |
| [#27](https://github.com/tojemoc/unopus/pull/27) | 2026-06-26 | Fix piece properties panel overflow when GFX preview is shown |
| [#28](https://github.com/tojemoc/unopus/pull/28) | 2026-06-26 | fix: allow payload.type when partType is set during DB migration |
| [#29](https://github.com/tojemoc/unopus/pull/29) | 2026-06-26 | fix: make right piece properties panel scroll independently |
| [#30](https://github.com/tojemoc/unopus/pull/30) | 2026-06-27 | Rundown piece properties scrolling |
| [#31](https://github.com/tojemoc/unopus/pull/31) | 2026-06-27 | Fix Rundown Editor ↔ Sofie contract for SPRÁVY v3 smoke rundowns |
| [#32](https://github.com/tojemoc/unopus/pull/32) | 2026-06-27 | Add MOS-style READY/NOT READY badges and Octopus-inspired story list |
| [#33](https://github.com/tojemoc/unopus/pull/33) | 2026-06-28 | fix: move quick-add story buttons to rundown timing toolbar |
| [#34](https://github.com/tojemoc/unopus/pull/34) | 2026-06-28 | fix: serve GFX preview templates without SPA fallback |
| [#35](https://github.com/tojemoc/unopus/pull/35) | 2026-07-08 | Fix rundown list action button layout and first-row overlap spacing |
| [#36](https://github.com/tojemoc/unopus/pull/36) | 2026-07-13 | Fix sidebar header overlap, media picker, and source field UX |
| [#37](https://github.com/tojemoc/unopus/pull/37) | 2026-07-14 | Headline Source toggle + text; pair with MIXER FILL for ILU video |
| [#38](https://github.com/tojemoc/unopus/pull/38) | 2026-07-15 | fix: allow free-text media paths and clearer ingest scan UX |

**Highlights vs upstream:** newsroom/NRCS workflows, Google Sheets ↔ vMix adapter, SPRÁVY piece-type UX (media picker, GFX preview, manifest-driven create), media readiness badges, dark/light theming / Unopus rebrand, free-text ingest paths.

### Demo assets — [tojemoc/sofie-demo-assets](https://github.com/tojemoc/sofie-demo-assets)

Not a GitHub fork. Started from [mint-dewit/casparcg-vue-boilerplate](https://github.com/mint-dewit/casparcg-vue-boilerplate); all product work is original to this repo. Default branch: `main` (PR #1 landed on `master` before the rename).

| PR | Merged | Title |
|----|--------|-------|
| [#1](https://github.com/tojemoc/sofie-demo-assets/pull/1) | 2026-06-23 | Set up Cloud dev environment + AGENTS.md |
| [#2](https://github.com/tojemoc/sofie-demo-assets/pull/2) | 2026-06-24 | feat: Caspar deploy layout, Sofie field mapping, SPRÁVY template stubs |
| [#3](https://github.com/tojemoc/sofie-demo-assets/pull/3) | 2026-06-24 | feat: 360 sekúnd CasparCG template spec v2 |
| [#4](https://github.com/tojemoc/sofie-demo-assets/pull/4) | 2026-06-24 | ci: add CD workflow with automated pre-releases |
| [#8](https://github.com/tojemoc/sofie-demo-assets/pull/8) | 2026-06-25 | fix: flat gfx/ packaging for CasparCG template path resolution |
| [#9](https://github.com/tojemoc/sofie-demo-assets/pull/9) | 2026-06-27 | Demo assets: production logo, payload contract, media layout docs |
| [#10](https://github.com/tojemoc/sofie-demo-assets/pull/10) | 2026-06-27 | Cursor/fix headline ilu media path 715a |
| [#11](https://github.com/tojemoc/sofie-demo-assets/pull/11) | 2026-06-27 | Play ILU via Caspar clip layer; headline template is overlay only |
| [#12](https://github.com/tojemoc/sofie-demo-assets/pull/12) | 2026-06-28 | Cursor/fix headline ilu play layer 715a |
| [#15](https://github.com/tojemoc/sofie-demo-assets/pull/15) | 2026-07-02 | Fix ILU video invisible when headline block slides in |
| [#16](https://github.com/tojemoc/sofie-demo-assets/pull/16) | 2026-07-08 | Add headline fallback overlay template for layered ILU playback |
| [#17](https://github.com/tojemoc/sofie-demo-assets/pull/17) | 2026-07-10 | Cloud agent setup and consolidated GitHub Actions dependency bumps |

**Highlights vs boilerplate:** SPRÁVY v2 templates as **hand-written static HTML** in `template/gfx/*.html` (12 files: `l3d-*`, `pocasie`, `outro`, `logo-bug`, `source`). The Vue/webpack build pipeline and `assemble-caspar` were removed in Sept 2026 — `yarn build`, `yarn test`, and the Dockerfile currently reference deleted files and fail (see repo AGENTS.md for the real deploy path).


### Merged since 2026-07-17 (tables above frozen at that date)

<details><summary>tojemoc/sofie — 54 PRs merged since the tables above</summary>

| PR | Merged | Title |
|----|--------|-------|
| [#7](https://github.com/tojemoc/sofie/pull/7) | 2026-07-17 | docs: add megarepo README with upstream PR catalogue |
| [#8](https://github.com/tojemoc/sofie/pull/8) | 2026-07-17 | docs: add ADR 0001 for RE readiness from Core Package Manager |
| [#9](https://github.com/tojemoc/sofie/pull/9) | 2026-07-20 | docs: Intro overlay + BG-loop integration notes |
| [#10](https://github.com/tojemoc/sofie/pull/10) | 2026-07-20 | docs: Intro overlay, BG-loop, and l3d-headline LED fix |
| [#11](https://github.com/tojemoc/sofie/pull/11) | 2026-07-20 | docs: muster smoke rundown + Intro/PGM notes |
| [#12](https://github.com/tojemoc/sofie/pull/12) | 2026-07-21 | Move RE type manifests and smoke rundown into megarepo assets/ |
| [#13](https://github.com/tojemoc/sofie/pull/13) | 2026-07-22 | DoubleBox PGM docs, wipe piece type, and smoke wipe transitions |
| [#14](https://github.com/tojemoc/sofie/pull/14) | 2026-07-22 | docs: document megarepo assets pin + SHA-256 fetch contract |
| [#15](https://github.com/tojemoc/sofie/pull/15) | 2026-07-22 | docs: clarify bg-loop media paths and PGM-only logo-bug |
| [#16](https://github.com/tojemoc/sofie/pull/16) | 2026-07-22 | chore(assets): drop unused remote/split/guest; keep Intro overlay |
| [#17](https://github.com/tojemoc/sofie/pull/17) | 2026-07-23 | Smoke Intro on PGM znelka; LED = headlines + loop |
| [#18](https://github.com/tojemoc/sofie/pull/18) | 2026-07-23 | Redesign ILU toggle as prerendered/bypass (no WebM) |
| [#19](https://github.com/tojemoc/sofie/pull/19) | 2026-08-04 | fix(smoke): ILU/L3DH shared duration; Softie manual Take (not AUTO) |
| [#20](https://github.com/tojemoc/sofie/pull/20) | 2026-08-04 | refactor(media): flatten to sofie-demo-media/clips|loops|wipes |
| [#22](https://github.com/tojemoc/sofie/pull/22) | 2026-08-05 | fix(smoke): l3d-syn on PGM docs + bump muster paths from RE export |
| [#23](https://github.com/tojemoc/sofie/pull/23) | 2026-08-06 | docs: UVC camera, LED loop permanence, RE readiness/wipe UX planning |
| [#24](https://github.com/tojemoc/sofie/pull/24) | 2026-08-06 | docs(integration): handoffs for RE readiness diagnostics + daily template workflow |
| [#25](https://github.com/tojemoc/sofie/pull/25) | 2026-08-07 | Align smoke rundown media paths with production Caspar names |
| [#26](https://github.com/tojemoc/sofie/pull/26) | 2026-08-08 | feat(assets): DoubleBox ILU piece + CAM crop contract |
| [#28](https://github.com/tojemoc/sofie/pull/28) | 2026-08-12 | docs: HEADLINE3 ILU dropped by Sofie Lower Third piece prune |
| [#29](https://github.com/tojemoc/sofie/pull/29) | 2026-08-13 | docs: PGM L3D source layer stays on GFX output (not flattened PGM) |
| [#30](https://github.com/tojemoc/sofie/pull/30) | 2026-08-15 | docs: canonical Caspar LED vs PGM output topology |
| [#31](https://github.com/tojemoc/sofie/pull/31) | 2026-08-14 | docs: PGM L3D duration inheritance notes |
| [#32](https://github.com/tojemoc/sofie/pull/32) | 2026-08-17 | Document l3d-headline GFX visibility and RE duration sync troubleshooting |
| [#33](https://github.com/tojemoc/sofie/pull/33) | 2026-08-20 | Add bg-music piece type, smoke pieces, and wipe 760ms docs |
| [#34](https://github.com/tojemoc/sofie/pull/34) | 2026-08-21 | SPRÁVY show flow: 5-topic smoke, L3D types, LED/PGM spine docs |
| [#35](https://github.com/tojemoc/sofie/pull/35) | 2026-08-21 | docs: LED-only bg_loop; DoubleBox ILU above CAM |
| [#36](https://github.com/tojemoc/sofie/pull/36) | 2026-08-25 | Add Cloud Agent development environment for the Sofie megarepo |
| [#37](https://github.com/tojemoc/sofie/pull/37) | 2026-08-31 | Kubo studio tasks: SYN trim/volume piece fields and integration docs |
| [#38](https://github.com/tojemoc/sofie/pull/38) | 2026-08-31 | Wire SPRÁVY v2 Caspar graphics (megarepo assets + integration docs) |
| [#39](https://github.com/tojemoc/sofie/pull/39) | 2026-09-01 | Sync smoke rundown from export; logo on first DoubleBox, pocasie HTML |
| [#40](https://github.com/tojemoc/sofie/pull/40) | 2026-09-02 | Fix smoke rundown demo playout issues |
| [#41](https://github.com/tojemoc/sofie/pull/41) | 2026-09-02 | fix(assets): SPRÁVY piece types, logo timing, playout handoff |
| [#44](https://github.com/tojemoc/sofie/pull/44) | 2026-09-05 | docs/assets: stack #42+#43+#44 — NR path, wipe ADR, On air, smoke scripts |
| [#45](https://github.com/tojemoc/sofie/pull/45) | 2026-09-07 | docs: wipe-gated BG look flips so hard-cut headlines stay on PGM route |
| [#46](https://github.com/tojemoc/sofie/pull/46) | 2026-09-10 | docs: RE ignore-core status, weather, cities JSON, import scripts |
| [#50](https://github.com/tojemoc/sofie/pull/50) | 2026-09-12 | docs: describe Sofie on-air → RE System lock contract |
| [#51](https://github.com/tojemoc/sofie/pull/51) | 2026-09-14 | docs: Package Manager was deleting NAS media; script visibility |
| [#52](https://github.com/tojemoc/sofie/pull/52) | 2026-09-14 | docs: DeckLink PGM 404 troubleshooting (MEDIA vs INPUT) |
| [#53](https://github.com/tojemoc/sofie/pull/53) | 2026-09-14 | fix/docs: always emit DECKLINK DEVICE in playout AMCP |
| [#54](https://github.com/tojemoc/sofie/pull/54) | 2026-09-14 | docs: CAM ingest on Caspar ch5 (route://5 into looks) |
| [#55](https://github.com/tojemoc/sofie/pull/55) | 2026-09-14 | fix(spravy): show polish assets — ILU vol, závěr DoubleBox, topology docs |
| [#57](https://github.com/tojemoc/sofie/pull/57) | 2026-09-14 | fix(spravy): show polish-2 — headline_sfx, ilu-zaver, SJV wipe merge |
| [#58](https://github.com/tojemoc/sofie/pull/58) | 2026-09-14 | chore(assets): smoke rundown from 2026-09-14 RE export |
| [#59](https://github.com/tojemoc/sofie/pull/59) | 2026-09-15 | fix(spravy): SJV/SPORT CPS, volume defaults, BB weather, SQ-5 + ffmpeg docs |
| [#60](https://github.com/tojemoc/sofie/pull/60) | 2026-09-15 | fix(smoke): intro presenter L3D uses l3d-mod |
| [#61](https://github.com/tojemoc/sofie/pull/61) | 2026-09-15 | SPRÁVY: wipe/L3D/zaver docs + 15.9 smoke rundown |
| [#65](https://github.com/tojemoc/sofie/pull/65) | 2026-09-15 | Smoke: l3d-headlines until Take; document ffprobe Docker gap |
| [#67](https://github.com/tojemoc/sofie/pull/67) | 2026-09-16 | feat(assets): volume presets, SRC Zdroj, ILU name-from-file (+ wipe cutPoint) |
| [#68](https://github.com/tojemoc/sofie/pull/68) | 2026-09-24 | docs: wipe cutpoint countup + ZAVER stray DoubleBox |
| [#70](https://github.com/tojemoc/sofie/pull/70) | 2026-09-26 | docs(assets): Softie postroll needed for editorial wipe cutPoint |
| [#72](https://github.com/tojemoc/sofie/pull/72) | 2026-09-29 | docs(integration): durable Caspar map + wipe layers 205–208 |
| [#73](https://github.com/tojemoc/sofie/pull/73) | 2026-10-13 | Document STING and OVERLAY wipe modes |
| [#74](https://github.com/tojemoc/sofie/pull/74) | 2026-10-30 | Smoke rundown: sync with Export rundown.json |

</details>

<details><summary>tojemoc/sofie-core — 17 PRs merged since the tables above</summary>

| PR | Merged | Title |
|----|--------|-------|
| [#6](https://github.com/tojemoc/sofie-core/pull/6) | 2026-07-17 | feat(packageManager): expose rundown piece content status to peripheral devices |
| [#7](https://github.com/tojemoc/sofie-core/pull/7) | 2026-07-17 | fix: resolve sourceLayers from sourceLayersWithOverrides in rundown content status |
| [#9](https://github.com/tojemoc/sofie-core/pull/9) | 2026-09-12 | feat: expose rundown playout state to ingest peripherals |
| [#10](https://github.com/tojemoc/sofie-core/pull/10) | 2026-09-14 | fix: emit DECKLINK DEVICE in Caspar PlayDecklink AMCP |
| [#11](https://github.com/tojemoc/sofie-core/pull/11) | 2026-09-16 | Cursor/prompter qprompt keyboard speed a938 |
| [#12](https://github.com/tojemoc/sofie-core/pull/12) | 2026-10-09 | fix(casparcg): emit OVERLAY= for STING transitions via casparcg-state patch |
| [#13](https://github.com/tojemoc/sofie-core/pull/13) | 2026-10-10 | ci(release): log in to Docker Hub before buildx to avoid anonymous pull rate limits |
| [#14](https://github.com/tojemoc/sofie-core/pull/14) | 2026-10-12 | feat: expose per-part AUTO settings to ingest devices |
| [#16](https://github.com/tojemoc/sofie-core/pull/16) | 2026-10-12 | Implementing prompter control updates |
| [#17](https://github.com/tojemoc/sofie-core/pull/17) | 2026-10-12 | Copilot/cursorauto next part settings |
| [#19](https://github.com/tojemoc/sofie-core/pull/19) | 2026-10-13 | Add `peripheralDevice.ingest.getRundownPartAutoNext` for per-part autoNext |
| [#22](https://github.com/tojemoc/sofie-core/pull/22) | 2026-11-08 | fix: mark blueprint-context insertPiece pieces as dynamicallyInserted |
| [#38](https://github.com/tojemoc/sofie-core/pull/38) | 2026-11-15 | chore: integrate major dependency bumps (babel 8, eslint 10, code-standard-preset 4 + 5 more) |
| [#39](https://github.com/tojemoc/sofie-core/pull/39) | 2026-11-15 | Migrate workflows to Blacksmith |
| [#40](https://github.com/tojemoc/sofie-core/pull/40) | 2026-11-15 | Fix CI breakages from asyncapi-generator v3 and plugin-react v6 |
| [#41](https://github.com/tojemoc/sofie-core/pull/41) | 2026-11-15 | fix(playout): regenerate timeline after ingest part changes |
| [#45](https://github.com/tojemoc/sofie-core/pull/45) | 2026-11-16 | fix(webui): drop react-router-bootstrap to stop useNavigate crash |

</details>

<details><summary>tojemoc/sofie-demo-blueprints (develop) — 113 PRs merged since the tables above</summary>

| PR | Merged | Title |
|----|--------|-------|
| [#44](https://github.com/tojemoc/sofie-demo-blueprints/pull/44) | 2026-07-20 | feat: Intro overlay + controllable BG loop pieces |
| [#46](https://github.com/tojemoc/sofie-demo-blueprints/pull/46) | 2026-07-20 | Adopt muster-faithful smoke rundown (from #45) |
| [#47](https://github.com/tojemoc/sofie-demo-blueprints/pull/47) | 2026-07-22 | Remove shared RE manifests; load smoke rundown from sofie megarepo |
| [#48](https://github.com/tojemoc/sofie-demo-blueprints/pull/48) | 2026-07-22 | Cursor/pgm wipe uvc camera 3555 |
| [#49](https://github.com/tojemoc/sofie-demo-blueprints/pull/49) | 2026-07-22 | fix(tests): account for story-block wipe packages in smoke rundown |
| [#50](https://github.com/tojemoc/sofie-demo-blueprints/pull/50) | 2026-07-22 | fix(hypercomposed): PGM-only logo-bug and reliable wipe recognition |
| [#51](https://github.com/tojemoc/sofie-demo-blueprints/pull/51) | 2026-07-23 | fix(caspar): play Intro on PGM layer 210, never LED |
| [#52](https://github.com/tojemoc/sofie-demo-blueprints/pull/52) | 2026-07-23 | feat(ilu): prerendered/bypass modes for headline ILU playback |
| [#54](https://github.com/tojemoc/sofie-demo-blueprints/pull/54) | 2026-08-04 | Cursor/flat media paths d3e2 |
| [#55](https://github.com/tojemoc/sofie-demo-blueprints/pull/55) | 2026-08-05 | chore(assets): prefer sofie #20 pin for megarepo fetch |
| [#56](https://github.com/tojemoc/sofie-demo-blueprints/pull/56) | 2026-08-05 | fix(gfx): route l3d-syn to PGM lower-third |
| [#57](https://github.com/tojemoc/sofie-demo-blueprints/pull/57) | 2026-08-05 | Cursor/pgm camera led loop d3e2 |
| [#58](https://github.com/tojemoc/sofie-demo-blueprints/pull/58) | 2026-08-07 | fix(baseline): play LED loop from loops/bg_loop |
| [#59](https://github.com/tojemoc/sofie-demo-blueprints/pull/59) | 2026-08-08 | feat(doublebox): PGM story ILU, CAM left cover-crop, no squish |
| [#60](https://github.com/tojemoc/sofie-demo-blueprints/pull/60) | 2026-08-12 | Cursor/pm path and headline l3d fdc0 |
| [#61](https://github.com/tojemoc/sofie-demo-blueprints/pull/61) | 2026-08-13 | fix(graphics): keep PGM L3D source layer on GFX output track |
| [#62](https://github.com/tojemoc/sofie-demo-blueprints/pull/62) | 2026-08-14 | Cursor/l3d duration text fix d3bd |
| [#63](https://github.com/tojemoc/sofie-demo-blueprints/pull/63) | 2026-08-20 | Wire SPRÁVY bg music, wipe 760ms, and wipe audio ducking |
| [#64](https://github.com/tojemoc/sofie-demo-blueprints/pull/64) | 2026-08-20 | SPRÁVY playout: fullscreen cam, DoubleBox 80%, weather/outro bypass |
| [#65](https://github.com/tojemoc/sofie-demo-blueprints/pull/65) | 2026-08-21 | fix(caspar): LED-only bg_loop; stack ILU above DoubleBox CAM |
| [#66](https://github.com/tojemoc/sofie-demo-blueprints/pull/66) | 2026-08-21 | chore(assets): pin sofie megarepo assets to d04f0f8 |
| [#67](https://github.com/tojemoc/sofie-demo-blueprints/pull/67) | 2026-08-22 | fix(pgm): counter bug, wipe source layer, L3D attribute cleanup |
| [#69](https://github.com/tojemoc/sofie-demo-blueprints/pull/69) | 2026-08-24 | fix l3d generic graphic template normalization |
| [#70](https://github.com/tojemoc/sofie-demo-blueprints/pull/70) | 2026-08-31 | Cursor/kubo playout graphics audio 1ddf |
| [#71](https://github.com/tojemoc/sofie-demo-blueprints/pull/71) | 2026-08-31 | Cursor/spravy v2 caspar wire d6ac |
| [#72](https://github.com/tojemoc/sofie-demo-blueprints/pull/72) | 2026-09-01 | Wire blueprints to on-main v2 Caspar templates from demo-assets |
| [#73](https://github.com/tojemoc/sofie-demo-blueprints/pull/73) | 2026-09-01 | Cursor/fix v2 template wiring 7c93 |
| [#75](https://github.com/tojemoc/sofie-demo-blueprints/pull/75) | 2026-09-02 | Fix smoke rundown playout: tema L3D, countup sustain, wipe fallbacks |
| [#76](https://github.com/tojemoc/sofie-demo-blueprints/pull/76) | 2026-09-02 | Cursor/spravy playout fixes 5ddc |
| [#77](https://github.com/tojemoc/sofie-demo-blueprints/pull/77) | 2026-09-03 | Pre-build story looks on BG channels; wipe as PGM route STING |
| [#78](https://github.com/tojemoc/sofie-demo-blueprints/pull/78) | 2026-09-04 | fix: full-channel PGM route, single live cam, debug channel labels |
| [#79](https://github.com/tojemoc/sofie-demo-blueprints/pull/79) | 2026-09-04 | chore: pin sofie assets to restored smoke scripts |
| [#80](https://github.com/tojemoc/sofie-demo-blueprints/pull/80) | 2026-09-05 | ci: typecheck on PRs; build artifacts only on develop/main and tags |
| [#81](https://github.com/tojemoc/sofie-demo-blueprints/pull/81) | 2026-09-07 | fix: keep hard-cut looks on one BG channel for stable PGM route |
| [#82](https://github.com/tojemoc/sofie-demo-blueprints/pull/82) | 2026-09-07 | fix: DoubleBox→ch3 / Full+headlines→ch4 (semantic PGM routes) |
| [#83](https://github.com/tojemoc/sofie-demo-blueprints/pull/83) | 2026-09-08 | feat: lock PGM route CSV contract (Full overlay wipes, Full bg_loop, LED zoom) |
| [#84](https://github.com/tojemoc/sofie-demo-blueprints/pull/84) | 2026-09-08 | fix: keep DoubleBox CAM1 warm; emit MEDIA route://N |
| [#85](https://github.com/tojemoc/sofie-demo-blueprints/pull/85) | 2026-09-08 | fix: DoubleBox wipe uses PGM overlay + delayed MEDIA route://3 |
| [#86](https://github.com/tojemoc/sofie-demo-blueprints/pull/86) | 2026-09-09 | fix: weather HTML sits over loops/bg_loop, not dark bg_pocasie |
| [#87](https://github.com/tojemoc/sofie-demo-blueprints/pull/87) | 2026-09-10 | fix: raise DoubleBox Cam1 FILL and right-bias LED bg_loop zoom |
| [#88](https://github.com/tojemoc/sofie-demo-blueprints/pull/88) | 2026-09-13 | fix: Package Manager must not delete NAS media; show Script track |
| [#89](https://github.com/tojemoc/sofie-demo-blueprints/pull/89) | 2026-09-14 | Cursor/decklink pgm input a90d |
| [#90](https://github.com/tojemoc/sofie-demo-blueprints/pull/90) | 2026-09-14 | fix: drive PGM camera only from studio pgmCameraProducer |
| [#91](https://github.com/tojemoc/sofie-demo-blueprints/pull/91) | 2026-09-14 | fix: drive PGM camera only from studio pgmCameraProducer |
| [#92](https://github.com/tojemoc/sofie-demo-blueprints/pull/92) | 2026-09-14 | docs: clarify DeckLink DEVICE omission vs EnableVideoInput |
| [#93](https://github.com/tojemoc/sofie-demo-blueprints/pull/93) | 2026-09-14 | Cursor/decklink exclusive cam bb98 |
| [#94](https://github.com/tojemoc/sofie-demo-blueprints/pull/94) | 2026-09-14 | fix(spravy): wipe preroll/key, ILU vol 0.5, weather BG, LED FILL, pod |
| [#95](https://github.com/tojemoc/sofie-demo-blueprints/pull/95) | 2026-09-14 | Cursor/spravy take lag 3af4 |
| [#96](https://github.com/tojemoc/sofie-demo-blueprints/pull/96) | 2026-09-14 | fix(spravy): headline_sfx, rehearsal baseline, ilu-zaver, clean wipe |
| [#97](https://github.com/tojemoc/sofie-demo-blueprints/pull/97) | 2026-09-14 | fix(weather): map cities.condition to pocasie icon when image missing |
| [#98](https://github.com/tojemoc/sofie-demo-blueprints/pull/98) | 2026-09-15 | fix(spravy): alpha wipe keying, mic/SYN mute, ILU freeze, 2s koliska |
| [#99](https://github.com/tojemoc/sofie-demo-blueprints/pull/99) | 2026-09-15 | Cursor/spravy polish 7 12 1323 |
| [#100](https://github.com/tojemoc/sofie-demo-blueprints/pull/100) | 2026-09-15 | fix(spravy): wipe_pocasie CLEAR ch4, L3D STOP/ADD, outro mute, zaver LED |
| [#101](https://github.com/tojemoc/sofie-demo-blueprints/pull/101) | 2026-09-15 | fix(spravy): break clips/baseline/pgmLook init cycle on WIPE_CUT_POINT_MS |
| [#102](https://github.com/tojemoc/sofie-demo-blueprints/pull/102) | 2026-09-15 | fix(spravy): stop pre-wipe tear, weather CLEAR under sting, windowed zaver |
| [#103](https://github.com/tojemoc/sofie-demo-blueprints/pull/103) | 2026-09-15 | Cursor/spravy l3d wipe outro c257 |
| [#104](https://github.com/tojemoc/sofie-demo-blueprints/pull/104) | 2026-09-16 | fix(spravy): L3D CLEAR off exclusive GFX so SYN/SJV/ŠPORT play |
| [#105](https://github.com/tojemoc/sofie-demo-blueprints/pull/105) | 2026-09-16 | fix(spravy): stop double L3D ADD, weather ILU keepalive, music under … |
| [#106](https://github.com/tojemoc/sofie-demo-blueprints/pull/106) | 2026-09-16 | fix(spravy): weather stack, wipe order, hold-frame, sport mute/AUTO |
| [#107](https://github.com/tojemoc/sofie-demo-blueprints/pull/107) | 2026-09-16 | fix(spravy): omit wipe chroma AMCP; reassert mixer at cut |
| [#108](https://github.com/tojemoc/sofie-demo-blueprints/pull/108) | 2026-09-16 | Cursor/wipe 205 alpha mixer 010d |
| [#109](https://github.com/tojemoc/sofie-demo-blueprints/pull/109) | 2026-09-16 | Cursor/ship today bp frs d826 |
| [#110](https://github.com/tojemoc/sofie-demo-blueprints/pull/110) | 2026-09-16 | Cursor/ship today bp frs d826 |
| [#111](https://github.com/tojemoc/sofie-demo-blueprints/pull/111) | 2026-09-16 | fix(spravy): wipe InTransition preroll + ZAVER DB cam |
| [#112](https://github.com/tojemoc/sofie-demo-blueprints/pull/112) | 2026-09-17 | fix(spravy): ZAVER/AVIZo Full look — no DoubleBox |
| [#113](https://github.com/tojemoc/sofie-demo-blueprints/pull/113) | 2026-09-21 | fix(spravy): hold DB→DB ILU until wipe cut (no early LOAD) |
| [#114](https://github.com/tojemoc/sofie-demo-blueprints/pull/114) | 2026-09-23 | fix(spravy): play wipe cover before countup and route cut |
| [#115](https://github.com/tojemoc/sofie-demo-blueprints/pull/115) | 2026-09-23 | Cursor/spravy wipe hold full zaver 7fd1 |
| [#116](https://github.com/tojemoc/sofie-demo-blueprints/pull/116) | 2026-09-26 | fix(spravy): honour RE wipe cutPoint via full-sting look postroll |
| [#117](https://github.com/tojemoc/sofie-demo-blueprints/pull/117) | 2026-09-26 | fix(spravy): keep countup hidden until first wipe to DoubleBox |
| [#118](https://github.com/tojemoc/sofie-demo-blueprints/pull/118) | 2026-09-27 | fix(spravy): restore hard-cut look timing; keep wipe air-cut path |
| [#119](https://github.com/tojemoc/sofie-demo-blueprints/pull/119) | 2026-09-27 | Cursor/wipe cutpoint timing b29c |
| [#120](https://github.com/tojemoc/sofie-demo-blueprints/pull/120) | 2026-09-28 | fix(spravy): hard-cut 2f overlap + classical wipe cover window |
| [#121](https://github.com/tojemoc/sofie-demo-blueprints/pull/121) | 2026-09-28 | Cursor/wipe cut 11f hardcut overlap 8e15 |
| [#122](https://github.com/tojemoc/sofie-demo-blueprints/pull/122) | 2026-09-28 | fix(spravy): stop baseline bg_loop flashing on hard cuts / DB→Full wipes |
| [#123](https://github.com/tojemoc/sofie-demo-blueprints/pull/123) | 2026-09-29 | fix(spravy): same-slot wipe look lead + drop hard-cut look preroll |
| [#124](https://github.com/tojemoc/sofie-demo-blueprints/pull/124) | 2026-09-29 | fix(spravy): wipe cutpoints + preload-only PGM (sticky wipes, look ping-pong) |
| [#126](https://github.com/tojemoc/sofie-demo-blueprints/pull/126) | 2026-09-30 | fix(spravy): dual always-live PGM routes + sticky bg_loop (black frames / cam pane) |
| [#127](https://github.com/tojemoc/sofie-demo-blueprints/pull/127) | 2026-09-30 | fix(spravy): restore wipe premul FILTER on sticky/LOADBG cues |
| [#128](https://github.com/tojemoc/sofie-demo-blueprints/pull/128) | 2026-09-30 | fix(spravy): restore pre-#125 wipe.mov PLAY (drop sticky wipe baseline) |
| [#129](https://github.com/tojemoc/sofie-demo-blueprints/pull/129) | 2026-10-01 | fix(spravy): stop LOADBG EMPTY on wipe layers 205–208 |
| [#130](https://github.com/tojemoc/sofie-demo-blueprints/pull/130) | 2026-10-07 | fix(spravy): hold outgoing weather under wipe cover on leave-weather ZAVER |
| [#131](https://github.com/tojemoc/sofie-demo-blueprints/pull/131) | 2026-10-08 | feat(spravy): config-gated Caspar STING route-transition trial |
| [#132](https://github.com/tojemoc/sofie-demo-blueprints/pull/132) | 2026-10-09 | fix(spravy): scope the STING route-transition trial to the classical wipes/wipe only |
| [#133](https://github.com/tojemoc/sofie-demo-blueprints/pull/133) | 2026-10-10 | fix(spravy): split STING mask/overlay + +1 frame hard-cut overlap |
| [#135](https://github.com/tojemoc/sofie-demo-blueprints/pull/135) | 2026-10-11 | fix(spravy): STING-route wipe cut timing + premul overlay + preload |
| [#136](https://github.com/tojemoc/sofie-demo-blueprints/pull/136) | 2026-10-12 | feat(spravy): honor RE AUTO in auto-take decisions |
| [#137](https://github.com/tojemoc/sofie-demo-blueprints/pull/137) | 2026-10-13 | fix(spravy): do not force AUTO on weather GFX |
| [#138](https://github.com/tojemoc/sofie-demo-blueprints/pull/138) | 2026-10-14 | fix(pgm): CUT hold on hard-cut route PLAY to drop stale LOADBG frame |
| [#139](https://github.com/tojemoc/sofie-demo-blueprints/pull/139) | 2026-10-14 | fix: outro must not claim idle look slot (weather flash) |
| [#140](https://github.com/tojemoc/sofie-demo-blueprints/pull/140) | 2026-10-18 | fix: re-arm STING on the route the Take actually PLAYes |
| [#141](https://github.com/tojemoc/sofie-demo-blueprints/pull/141) | 2026-10-18 | revert: drop transition-bearing STING hot-cue PLAY (restores bare promote) |
| [#142](https://github.com/tojemoc/sofie-demo-blueprints/pull/142) | 2026-10-18 | fix: STING drop — no lookahead on the sting layer so each Take plays its own producer |
| [#144](https://github.com/tojemoc/sofie-demo-blueprints/pull/144) | 2026-10-21 | fix: STING path — delay dual-route flip past mask cover (empty src leak) |
| [#145](https://github.com/tojemoc/sofie-demo-blueprints/pull/145) | 2026-10-21 | feat: vMix program switcher for hypercomposed looks; retire Caspar STING trial |
| [#146](https://github.com/tojemoc/sofie-demo-blueprints/pull/146) | 2026-10-29 | fix: make vMix/ATEM/Sisyfos source tables editable; explicit vMix pro… |
| [#148](https://github.com/tojemoc/sofie-demo-blueprints/pull/148) | 2026-10-30 | test: pin smoke to Export rundown sync; rewrite stale smoke specs |
| [#149](https://github.com/tojemoc/sofie-demo-blueprints/pull/149) | 2026-11-01 | fix: lead vMix stingers with PREVIEW of the incoming look |
| [#150](https://github.com/tojemoc/sofie-demo-blueprints/pull/150) | 2026-11-05 | Fix/vmix stinger preview |
| [#151](https://github.com/tojemoc/sofie-demo-blueprints/pull/151) | 2026-11-06 | Fix/vmix stinger preview |
| [#152](https://github.com/tojemoc/sofie-demo-blueprints/pull/152) | 2026-11-07 | fix: play look-less takes to vMix camera input and reveal LED headline ILU |
| [#153](https://github.com/tojemoc/sofie-demo-blueprints/pull/153) | 2026-11-07 | fix: EMPTY outgoing L3D layer at Take so old template cannot stack under new |
| [#155](https://github.com/tojemoc/sofie-demo-blueprints/pull/155) | 2026-11-08 | feat: start vMix recording on first on-air Take + studio calibration baseline |
| [#157](https://github.com/tojemoc/sofie-demo-blueprints/pull/157) | 2026-11-08 | fix: keep vMix recording alive across Takes |
| [#158](https://github.com/tojemoc/sofie-demo-blueprints/pull/158) | 2026-11-08 | fix: keep vMix recording alive across takes and auto-next transitions |
| [#159](https://github.com/tojemoc/sofie-demo-blueprints/pull/159) | 2026-11-09 | fix: keep vMix recording alive across transitions, skip rehearsal parts |
| [#160](https://github.com/tojemoc/sofie-demo-blueprints/pull/160) | 2026-11-09 | fix: stop vMix recording at outro end, bake non-headline L3Ds into looks |
| [#161](https://github.com/tojemoc/sofie-demo-blueprints/pull/161) | 2026-11-10 | fix: end outro recording with an OFF object instead of piece updates |
| [#162](https://github.com/tojemoc/sofie-demo-blueprints/pull/162) | 2026-11-10 | fix: preload idle look media, mute off-air look audio, arm ilu-zaver + pause countup on jumps |
| [#163](https://github.com/tojemoc/sofie-demo-blueprints/pull/163) | 2026-11-11 | fix: paused foreground preview of incoming look on the off-air channel |
| [#164](https://github.com/tojemoc/sofie-demo-blueprints/pull/164) | 2026-11-11 | fix: l3d-mod on clean GFX, db_loop + off-air timing in idle preview |
| [#165](https://github.com/tojemoc/sofie-demo-blueprints/pull/165) | 2026-11-11 | fix: vMix looks — no shadowed incoming media, early unpause, phase-locked db_loop, constant beds |
| [#206](https://github.com/tojemoc/sofie-demo-blueprints/pull/206) | 2026-11-12 | feat(blueprints): arm idle-look preview at runtime via onSetAsNext |

</details>

<details><summary>tojemoc/unopus — 63 PRs merged since the tables above</summary>

| PR | Merged | Title |
|----|--------|-------|
| [#39](https://github.com/tojemoc/unopus/pull/39) | 2026-07-17 | Add l3d-headline to ILU part defaultPieces |
| [#40](https://github.com/tojemoc/unopus/pull/40) | 2026-07-17 | feat(readiness): prefer Sofie Core package status with fs fallback |
| [#41](https://github.com/tojemoc/unopus/pull/41) | 2026-07-20 | feat: Intro and BG-loop part/piece types for overlay control |
| [#43](https://github.com/tojemoc/unopus/pull/43) | 2026-07-20 | Adopt muster smoke rundown (resolve PR #42 conflicts) |
| [#44](https://github.com/tojemoc/unopus/pull/44) | 2026-07-21 | Remove shared type manifests; load from sofie megarepo assets/ |
| [#45](https://github.com/tojemoc/unopus/pull/45) | 2026-07-22 | fix: stop copying removed ../assets during backend build |
| [#46](https://github.com/tojemoc/unopus/pull/46) | 2026-07-22 | fix(typeManifests): allow part+piece to share the same id |
| [#47](https://github.com/tojemoc/unopus/pull/47) | 2026-07-23 | feat(media): ILU prerendered toggle, ffprobe duration, no WebM check |
| [#49](https://github.com/tojemoc/unopus/pull/49) | 2026-08-04 | feat(settings): delete-all types and true overwrite on reload |
| [#50](https://github.com/tojemoc/unopus/pull/50) | 2026-08-04 | refactor(media): scan clips|loops|wipes at ingest root |
| [#52](https://github.com/tojemoc/unopus/pull/52) | 2026-08-05 | chore(assets): pin sofie megarepo assets to #20 flat paths |
| [#53](https://github.com/tojemoc/unopus/pull/53) | 2026-08-06 | feat(readiness): observable Core content-status pipeline |
| [#54](https://github.com/tojemoc/unopus/pull/54) | 2026-08-07 | feat: daily template clone, bulk rewrite, readiness-aware media picker |
| [#55](https://github.com/tojemoc/unopus/pull/55) | 2026-08-15 | Sync story duration in RE before Sofie ingest |
| [#56](https://github.com/tojemoc/unopus/pull/56) | 2026-08-17 | Broadcast story duration sync to RE clients |
| [#57](https://github.com/tojemoc/unopus/pull/57) | 2026-08-20 | Fix doublebox-ilu iluFile lost on piece save |
| [#58](https://github.com/tojemoc/unopus/pull/58) | 2026-08-20 | Improve story part duration display and iluFile probing |
| [#59](https://github.com/tojemoc/unopus/pull/59) | 2026-08-20 | Add piece reorder within a part |
| [#60](https://github.com/tojemoc/unopus/pull/60) | 2026-08-20 | Show wipe cut point (0.76s) and audio mute info in piece UI |
| [#62](https://github.com/tojemoc/unopus/pull/62) | 2026-08-21 | Bump sofie assets pin for SPRÁVY show-flow L3Ds |
| [#63](https://github.com/tojemoc/unopus/pull/63) | 2026-08-21 | chore(assets): pin sofie megarepo to d04f0f8 + checksums |
| [#64](https://github.com/tojemoc/unopus/pull/64) | 2026-08-22 | Script reading-time, skip, and editor-checked status |
| [#65](https://github.com/tojemoc/unopus/pull/65) | 2026-08-31 | Cursor/kubo unopus rundown ux 1ddf |
| [#66](https://github.com/tojemoc/unopus/pull/66) | 2026-08-31 | Cursor/unopus single column script 1ddf |
| [#67](https://github.com/tojemoc/unopus/pull/67) | 2026-08-31 | Redesign expanded piece editor layout |
| [#68](https://github.com/tojemoc/unopus/pull/68) | 2026-09-01 | Add rundown settings cog and enlarge GFX preview |
| [#69](https://github.com/tojemoc/unopus/pull/69) | 2026-09-01 | Fix GFX preview base URL: allow clearing and relative paths |
| [#70](https://github.com/tojemoc/unopus/pull/70) | 2026-09-01 | fix: restore Sync to Sofie toggle and Daily rewrite view |
| [#71](https://github.com/tojemoc/unopus/pull/71) | 2026-09-02 | feat: CasparCG flat GFX templates with XML templateData preview |
| [#72](https://github.com/tojemoc/unopus/pull/72) | 2026-09-03 | fix: allow clearing On air and probe real clip length |
| [#74](https://github.com/tojemoc/unopus/pull/74) | 2026-09-04 | fix: lint no-useless-assignment in On air clock parse (unblocks CI) |
| [#75](https://github.com/tojemoc/unopus/pull/75) | 2026-09-04 | fix: trusted audit-skip gate + clear duration on media path change |
| [#76](https://github.com/tojemoc/unopus/pull/76) | 2026-09-05 | ci: typecheck+lint on PRs; production build only on main |
| [#77](https://github.com/tojemoc/unopus/pull/77) | 2026-09-08 | fix: On air empty clear sticks; fractional duration as 00:02.5 |
| [#78](https://github.com/tojemoc/unopus/pull/78) | 2026-09-09 | feat: exclusive story concurrency locks with kick-out confirmation |
| [#79](https://github.com/tojemoc/unopus/pull/79) | 2026-09-09 | feat: ignore Sofie media status while still syncing rundowns |
| [#80](https://github.com/tojemoc/unopus/pull/80) | 2026-09-11 | feat: per-part auto vs until-next-take + fix smoke script import |
| [#81](https://github.com/tojemoc/unopus/pull/81) | 2026-09-12 | feat: per-field maxLength for GFX titles |
| [#82](https://github.com/tojemoc/unopus/pull/82) | 2026-09-12 | Cursor/playout on air system locks b05a |
| [#83](https://github.com/tojemoc/unopus/pull/83) | 2026-09-12 | Revert "feat: per-field maxLength for GFX titles (#81)" |
| [#84](https://github.com/tojemoc/unopus/pull/84) | 2026-09-12 | feat: per-field maxLength for GFX titles |
| [#85](https://github.com/tojemoc/unopus/pull/85) | 2026-09-14 | feat: show smoke scripts on story rows and allow on-air read |
| [#86](https://github.com/tojemoc/unopus/pull/86) | 2026-09-14 | fix: omit skipped/floated parts from Sofie full sync |
| [#87](https://github.com/tojemoc/unopus/pull/87) | 2026-09-14 | fix(ui): promote ILU volume next to clip; bump megarepo asset pin |
| [#88](https://github.com/tojemoc/unopus/pull/88) | 2026-09-14 | feat(weather): sync Počasie from iMeteo Partner API |
| [#89](https://github.com/tojemoc/unopus/pull/89) | 2026-09-15 | fix(ui): allow text selection in expanded stories |
| [#90](https://github.com/tojemoc/unopus/pull/90) | 2026-09-15 | feat(spravy): volume slider, SJV/SPORT CPS, MM weather region |
| [#91](https://github.com/tojemoc/unopus/pull/91) | 2026-09-15 | Cursor/spravy part row auto 47f9 |
| [#92](https://github.com/tojemoc/unopus/pull/92) | 2026-09-15 | Cursor/spravy re editor ux 9fad |
| [#93](https://github.com/tojemoc/unopus/pull/93) | 2026-09-15 | Install ffmpeg in Docker so ffprobe can seed clip lengths |
| [#94](https://github.com/tojemoc/unopus/pull/94) | 2026-09-16 | Cursor/segment select part dedupe ccaf |
| [#95](https://github.com/tojemoc/unopus/pull/95) | 2026-09-16 | fix(ui): restore collapsed piece chip drag in script flow |
| [#96](https://github.com/tojemoc/unopus/pull/96) | 2026-09-16 | feat(ui): show precise blue caret for cue drops in script flow |
| [#97](https://github.com/tojemoc/unopus/pull/97) | 2026-09-16 | Cursor/ship today volume src ilu 341f |
| [#98](https://github.com/tojemoc/unopus/pull/98) | 2026-09-28 | feat(ui): Material dark broadcast redesign with custom Unopus icons |
| [#99](https://github.com/tojemoc/unopus/pull/99) | 2026-09-26 | fix(wipe): always export cutPoint ms to Sofie ingest |
| [#101](https://github.com/tojemoc/unopus/pull/101) | 2026-10-12 | feat(ui): show Sofie AUTO state alongside editor intent |
| [#102](https://github.com/tojemoc/unopus/pull/102) | 2026-10-13 | Show AUTO badge on parts Sofie forces to AUTO, driven by manifest flags |
| [#103](https://github.com/tojemoc/unopus/pull/103) | 2026-10-30 | chore: pin megarepo assets to smoke rundown synced with export |
| [#106](https://github.com/tojemoc/unopus/pull/106) | 2026-11-01 | test: stop asserting smoke rundown weather forecast text |
| [#107](https://github.com/tojemoc/unopus/pull/107) | 2026-11-06 | chore: bump server-core-integration to 26.9.2 for Core version check |
| [#108](https://github.com/tojemoc/unopus/pull/108) | 2026-11-08 | feat(ui): rework nav, fix export/story counts and generation UX bugs |
| [#125](https://github.com/tojemoc/unopus/pull/125) | 2026-11-15 | fix: use clip duration for AUTO SYN stories |

</details>

<details><summary>tojemoc/sofie-demo-assets — 18 PRs merged since the tables above</summary>

| PR | Merged | Title |
|----|--------|-------|
| [#11](https://github.com/tojemoc/sofie-demo-assets/pull/11) | 2026-06-27 | Play ILU via Caspar clip layer; headline template is overlay only |
| [#12](https://github.com/tojemoc/sofie-demo-assets/pull/12) | 2026-06-28 | Cursor/fix headline ilu play layer 715a |
| [#15](https://github.com/tojemoc/sofie-demo-assets/pull/15) | 2026-07-02 | Fix ILU video invisible when headline block slides in |
| [#16](https://github.com/tojemoc/sofie-demo-assets/pull/16) | 2026-07-08 | Add headline fallback overlay template for layered ILU playback |
| [#17](https://github.com/tojemoc/sofie-demo-assets/pull/17) | 2026-07-10 | Cloud agent setup and consolidated GitHub Actions dependency bumps |
| [#24](https://github.com/tojemoc/sofie-demo-assets/pull/24) | 2026-07-23 | fix(headline): drop HTML WebM ILU; harden L3D stop animation |
| [#26](https://github.com/tojemoc/sofie-demo-assets/pull/26) | 2026-08-04 | docs(media): flat sofie-demo-media layout (no spravy nesting) |
| [#27](https://github.com/tojemoc/sofie-demo-assets/pull/27) | 2026-08-14 | Fix L3D templates missing text when PLAY precedes UPDATE |
| [#28](https://github.com/tojemoc/sofie-demo-assets/pull/28) | 2026-08-17 | Fix l3d-headline bars staying off-screen on play |
| [#29](https://github.com/tojemoc/sofie-demo-assets/pull/29) | 2026-08-21 | Port Figma L3Ds: predstavovak, SJV/Sport shell, odporúčanie |
| [#30](https://github.com/tojemoc/sofie-demo-assets/pull/30) | 2026-08-31 | Fix l3d predstavovak Caspar data handling |
| [#32](https://github.com/tojemoc/sofie-demo-assets/pull/32) | 2026-08-31 | Address PR #30 review: predstavovak headline mapping and XML entity decoding |
| [#34](https://github.com/tojemoc/sofie-demo-assets/pull/34) | 2026-08-31 | Clean up to v2 graphics only (PR #33 fonts + source template) |
| [#35](https://github.com/tojemoc/sofie-demo-assets/pull/35) | 2026-09-02 | fix(pocasie): auto-play weather template on Caspar update |
| [#37](https://github.com/tojemoc/sofie-demo-assets/pull/37) | 2026-09-09 | fix: keep pocasie HTML transparent under CasparCEF |
| [#39](https://github.com/tojemoc/sofie-demo-assets/pull/39) | 2026-09-14 | fix(l3d): hide stage until play() so In animation runs |
| [#40](https://github.com/tojemoc/sofie-demo-assets/pull/40) | 2026-09-14 | Cursor/spravy l3d blip 3af4 |
| [#41](https://github.com/tojemoc/sofie-demo-assets/pull/41) | 2026-09-15 | fix(pocasie): use MM region code (alias BB) for Banská Bystrica |

</details>

---

## Counts (merged PRs)

| Repository | Merged PRs |
|------------|------------|
| `tojemoc/sofie` (this repo) | 60 |
| `tojemoc/sofie-core` | 22 |
| `tojemoc/sofie-demo-blueprints` | 153 |
| `tojemoc/unopus` | 101 |
| `tojemoc/sofie-demo-assets` | 30 |
| **Total** | **366** |

---

## Further reading

- [`AGENTS.md`](AGENTS.md) — toolchain, ports, lint/test/build, gotchas
- [`docs/integration/SPRAVY-V2-INTEGRATION.md`](docs/integration/SPRAVY-V2-INTEGRATION.md) — living integration log
- [`docs/integration/handoffs/blueprints-v2-wiring.md`](docs/integration/handoffs/blueprints-v2-wiring.md) — blueprints agent handoff
