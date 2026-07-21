# AGENTS.md

## Cursor Cloud specific instructions

### What this repository is

This is a **superproject** that aggregates four Sofie TV‑automation projects, declared in
`.gitmodules`:

| Path | Upstream | Product |
|------|----------|---------|
| `core/` | `tojemoc/sofie-core` | **Sofie Core** — Meteor 3 + Node backend + React (Vite) WebUI |
| `blueprints/` | `tojemoc/sofie-demo-blueprints` | **Demo Blueprints** — builds `*-bundle.js` uploaded into Core |
| `rundown-editor/` | `tojemoc/unopus` | **Sofie Rundown Editor** — standalone Express + Socket.IO / React rundown tool |
| `demo-assets/` | `tojemoc/sofie-demo-assets` | **Demo Assets** — Vue/HTML CasparCG templates + media scaffold; `yarn build` → `deploy/` |

Each submodule has its own, more detailed `AGENTS.md` (e.g. `core/AGENTS.md`) — read it before
working inside that submodule.

> **Submodules are independent clones, not git‑linked.** The superproject tracks only `.gitmodules`
> (no committed gitlinks), so `git submodule update --init` does nothing. The four directories are
> full standalone clones that are provisioned by the VM environment / persisted in the snapshot. To
> update one, `cd` into it and use normal git. Do not `git add` these directories into the
> superproject.

### Shared type manifests & smoke rundown (`assets/`)

**Canonical home** for Rundown Editor piece / part / segment type JSON and the SPRÁVY smoke
rundown is this megarepo:

| Path | Purpose |
|------|---------|
| `assets/sofie-rundown-editor-piece-types.json` | Piece types + GFX preview templates |
| `assets/sofie-rundown-editor-part-types.json` | Part presets |
| `assets/sofie-rundown-editor-segment-types.json` | Segment presets |
| `assets/spravy-v3-smoke-rundown.json` | Smoke rundown fixture (`spravy-v3-smoke`) |

Do **not** keep or revive copies under `blueprints/assets/` or `rundown-editor/assets/`.
Edit here; blueprints tests and the Rundown Editor resolve these files when nested in the
megarepo (see those repos' `AGENTS.md`).

### Toolchain (already provisioned)

- **Node.js 22.22.0** via nvm. The VM's default `/exec-daemon/node` (v22.14.0) is too old and is
  shadowed: `~/.bashrc` sources nvm and prepends `~/.nvm/versions/node/v22.22.0/bin` to `PATH`.
  Interactive shells get the right node automatically; in a non‑interactive script run
  `. "$HOME/.nvm/nvm.sh" && nvm use 22.22.0`.
- **Yarn** is provided per‑repo via Corepack (`packageManager` field): Core `4.14.1`,
  Blueprints `4.12.0`, Rundown Editor `4.9.1`. `COREPACK_ENABLE_DOWNLOAD_PROMPT=0` is exported in
  `~/.bashrc` so first‑use yarn downloads don't hang on a `[Y/n]` prompt inside a TTY (e.g. tmux).
- **Meteor 3.4.1** is installed (`/usr/local/bin/meteor`); required by Core's `yarn install`
  postinstall.

The startup **update script** runs `yarn install` in each submodule to refresh dependencies. It does
**not** build or start anything — do that yourself (see below).

### Services, ports, and how to run them

Run long‑lived processes in **tmux** (use `tmux -f /exec-daemon/tmux.portal.conf`). `unset NODE_ENV`
before Core commands — a `production` value breaks dev installs/builds.

| Service | Dir | Port | Run |
|---------|-----|------|-----|
| Sofie Core (Meteor + Vite WebUI + workers) | `core` | 3000 (API/DDP), 3005 (WebUI) | `yarn dev` |
| Rundown Editor backend | `rundown-editor` | 3010 | `yarn dev:backend` (or `yarn dev` for both) |
| Rundown Editor frontend | `rundown-editor` | 5173 | `yarn dev:ui` |
| Blueprints docs (optional) | `blueprints` | 3030 | `yarn watch:docs` (base path `/sofie-demo-blueprints/`) |
| CasparCG template dev (optional) | `demo-assets` | 8080 | `yarn serve` → e.g. `http://localhost:8080/l3d-tema/index.html` |

- **Core** uses an embedded MongoDB managed by Meteor in dev — no separate DB to start. First run
  needs packages built once: `node ./scripts/install-and-build.mjs` (or `yarn build:packages`).
  `yarn start` = install + build + dev. WebUI is at `http://localhost:3005`; backend health at
  `http://localhost:3000/health`.
- **Rundown Editor** needs `backend/.env` (`cp backend/.env.example backend/.env`). It seeds an
  `admin` user and prints a dev bootstrap password in the backend log on first run. Uses embedded
  SQLite (`node:sqlite`; the `ExperimentalWarning` is harmless).
- **Blueprints** is a build‑time artifact producer, not a daemon: `cd packages/blueprints && yarn dist`
  writes `dist/*-bundle.js` for upload into Core.

### Lint / test / build (per submodule, from its root)

| Submodule | Lint | Test | Build |
|-----------|------|------|-------|
| `core` | `yarn lint` (`lint:packages` fast; `lint:meteor` is slow, several minutes) | `yarn unit:packages` (Jest, ~1000+ tests), `yarn unit:meteor` | `node ./scripts/install-and-build.mjs` |
| `blueprints` | `cd packages/blueprints && yarn lint` | `yarn test:blueprints` | `cd packages/blueprints && yarn dist` |
| `rundown-editor` | `yarn lint` | (no test suite) | `yarn build` |
| `demo-assets` | `yarn lint` | (none yet) | `yarn build` → `deploy/template-path` + `deploy/media-path` |

### SPRÁVY v2 integration (cross-repo)

**Integration log:** `docs/integration/SPRAVY-V2-INTEGRATION.md` — template catalogue,
deploy contract, repo status, verification checklist. Update when cross-repo progress changes.

**Blueprints handoff prompt:** `docs/integration/handoffs/blueprints-v2-wiring.md` — copy into
a Cursor agent session on `sofie-demo-blueprints`.

| Repo | Status (2026-06-24) |
|------|---------------------|
| `demo-assets` | **PR #3 merged** — 10 v2 templates + `assemble-caspar.mjs`; **PR #4 open** — CI pre-releases |
| `blueprints` | **Not wired** — still v1 `gfx/l3d` etc.; critical path for Friday demo |
| `rundown-editor` | Loads type manifests from megarepo `assets/`; minimal UI changes for demo |
| `core` / playout-gateway | No template code; upload blueprint bundle + apply studio config |

v2 Caspar `clipName` convention: `gfx/<template-folder>` (e.g. `gfx/l3d-tema`). Built layout:
`deploy/template-path/gfx/<name>/<name>.html`. See integration log for full payload table.

### Hypercomposed Caspar (WIP — post-demo PR2)

SPRÁVY targets a **single CasparCG server** compositing background loop, camera, ILU, HTML
graphics, and alpha wipes — without vision-mixer program cuts. Blueprint support lands in PR 2
(`hypercomposed` studio preset); templates and media are built from `demo-assets/`.

**LED ≠ PGM:** one Caspar can output **different content on different channels/consumers**
(e.g. ch1 → LED, ch2 → PGM). A second Caspar server is not required. See
`demo-assets/docs/OUTPUT_TOPOLOGY.md`.

### Gotchas

- A fresh Core dev DB reports `status: FAIL` / "Version mismatch … to fix, run migration" at
  `/health`. This is normal — run the migration in the WebUI (**Settings → Upgrade Database →
  Run automatic migration procedure**); the UI loads regardless. After migrating, `/health` may
  still report `FAIL`/`WARNING` from unconfigured demo blueprints ("Invalid configuration") and from
  a connected Rundown Editor peripheral reporting an older `server-core-integration` version — both
  are expected on a fresh dev instance and don't indicate a broken Core.
- The standalone `[TSC]` watcher in `core` `yarn dev` prints many `Cannot find module 'meteor/…'`
  errors. These are expected false‑positives (Meteor's own build resolves those modules) and do not
  stop the server.
- Rundown Editor logs `Core Initialization Error: connect ECONNREFUSED 127.0.0.1:3000` when Core is
  not running — benign; the editor is fully usable standalone.
- All four repos use Husky `lint-staged` pre‑commit hooks where configured.
- `demo-assets` webpack 4 needs OpenSSL legacy provider — `yarn build` sets it in `package.json` scripts.
