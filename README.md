# Sofie megarepo (`tojemoc/sofie`)

A **superproject** that aggregates the forks and assets used for the **SPRÁVY / 360 sekúnd** Sofie TV-automation demo stack. It is the coordination layer for local Cursor Cloud development: submodule pointers, agent instructions (`AGENTS.md`), and cross-repo integration docs.

Application code lives in the four component repositories below. This repo itself tracks documentation and `.gitmodules` — not application gitlinks (see [Workspace layout](#workspace-layout)).

## What’s in the stack

| Path | Repository | Upstream | Role |
|------|------------|----------|------|
| `core/` | [tojemoc/sofie-core](https://github.com/tojemoc/sofie-core) | [Sofie-Automation/sofie-core](https://github.com/Sofie-Automation/sofie-core) | Sofie Core — Meteor 3 + Node backend + React (Vite) WebUI |
| `blueprints/` | [tojemoc/sofie-demo-blueprints](https://github.com/tojemoc/sofie-demo-blueprints) | [SuperFlyTV/sofie-demo-blueprints](https://github.com/SuperFlyTV/sofie-demo-blueprints) | Demo blueprints — builds `*-bundle.js` uploaded into Core |
| `rundown-editor/` | [tojemoc/unopus](https://github.com/tojemoc/unopus) | [SuperFlyTV/sofie-automation-rundown-editor](https://github.com/SuperFlyTV/sofie-automation-rundown-editor) | Rundown Editor (Unopus) — Express + Socket.IO / React |
| `demo-assets/` | [tojemoc/sofie-demo-assets](https://github.com/tojemoc/sofie-demo-assets) | [mint-dewit/casparcg-vue-boilerplate](https://github.com/mint-dewit/casparcg-vue-boilerplate) (history base; not a GitHub fork) | CasparCG Vue/HTML templates + media scaffold |

**Playout path:** Rundown Editor → Sofie Core → Playout Gateway → CasparCG (v2 HTML templates from `demo-assets`).

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

Below are **merged pull requests** on the `tojemoc` forks (and this megarepo) that diverge from — or, for `demo-assets`, extend — the upstream baselines. Lists are current as of **2026-07-17**. Open/unmerged work is omitted.

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

Fork of [SuperFlyTV/sofie-demo-blueprints](https://github.com/SuperFlyTV/sofie-demo-blueprints). Active default branch: `develop` (SPRÁVY / Caspar work). Earlier line of work landed on `vmix-demo-blueprints` and briefly on `main` (some of those `main` PRs were reverted).

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

**Highlights vs boilerplate:** full SPRÁVY v2 template set (`gfx/headline`, `l3d-*`, weather, outro, logo-bug, headline-fallback), `assemble-caspar` deploy layout, media scaffold, CD pre-release zips.

---

## Counts (merged PRs)

| Repository | Merged PRs |
|------------|------------|
| `tojemoc/sofie` (this repo) | 6 |
| `tojemoc/sofie-core` | 5 |
| `tojemoc/sofie-demo-blueprints` | 40 |
| `tojemoc/unopus` | 38 |
| `tojemoc/sofie-demo-assets` | 12 |
| **Total** | **101** |

---

## Further reading

- [`AGENTS.md`](AGENTS.md) — toolchain, ports, lint/test/build, gotchas
- [`docs/integration/SPRAVY-V2-INTEGRATION.md`](docs/integration/SPRAVY-V2-INTEGRATION.md) — living integration log
- [`docs/integration/handoffs/blueprints-v2-wiring.md`](docs/integration/handoffs/blueprints-v2-wiring.md) — blueprints agent handoff
