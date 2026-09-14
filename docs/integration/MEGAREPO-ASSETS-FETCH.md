# Megarepo `assets/` fetch contract (CI / Docker)

Canonical manifests live in this repo under [`assets/`](../../assets/). Nested clones
(`sofie/blueprints/`, `sofie/rundown-editor/`) resolve them via the filesystem. Standalone
CI, Docker builds, and local checkouts of **unopus** / **sofie-demo-blueprints** download
the same files with `scripts/fetch-sofie-megarepo-assets.sh` in each consumer.

## Why pins (not `main` / `cursor/…`)

Mutable refs (`main`, feature branches) can change under a running build. That caused
flaky CI and unverifiable Docker layers. Consumers **must**:

1. **Pin** downloads to an **immutable sofie commit SHA** (not a branch name).
2. **Verify** each downloaded file’s **SHA-256** against values committed next to the pin
   (fail the job and delete partial downloads on mismatch).

Reference implementation: [unopus PR #45](https://github.com/tojemoc/unopus/pull/45)
(`scripts/fetch-sofie-megarepo-assets.sh`).

| Mechanism | Role |
|-----------|------|
| Commit SHA in the raw URL | `raw.githubusercontent.com/tojemoc/sofie/<sha>/assets/…` — immutable tree |
| Per-file SHA-256 map | Detects truncated/corrupt downloads and accidental pin/checksum drift |
| Cleanup on failure | Removes partial files so a bad tree is never exported as `SOFIE_MEGAREPO_ASSETS` |

Do **not** fetch from `…/sofie/main/assets/…` or `…/sofie/cursor/…/assets/…` in CI or Docker.

## Current pin (SPRÁVY smoke — 2026-09-14 export, 4 topics)

Pin is the immutable Sofie commit that replaced the smoke baseline with Jakub’s
2026-09-14 RE export (Migaľ segment dropped). Piece/part type manifests are
unchanged from polish-2 (`ilu-zaver` types still present; smoke závěr in this
export uses `ilu`/`headline`).

| Item | Value |
|------|--------|
| Sofie commit | `PIN_PENDING_THIS_PR` |
| unopus `PINNED_SOFIE_ASSETS_REF` | `PIN_PENDING_THIS_PR` |
| sofie-demo-blueprints `PINNED_SOFIE_ASSETS_REF` | `PIN_PENDING_THIS_PR` |
| unopus override (optional) | `SOFIE_ASSETS_REF` — if set, must be a full 40-char lowercase SHA; otherwise defaults to `PINNED_SOFIE_ASSETS_REF` |

Both consumer scripts must pin the **same** commit SHA, verify every file against
`EXPECTED_SHA256` (table below), and fail closed on download or checksum mismatch.

### Per-file SHA-256 (`assets/` at that commit)

| File | SHA-256 |
|------|---------|
| `spravy-v3-smoke-rundown.json` | `3ce16c324d79101cb3a840d61fdb0d95d55c643c8da23420c7f5aee2e5da71a0` |
| `sofie-rundown-editor-piece-types.json` | `e8bfa1aa062965c98981982f02a4eb2d1233f63e0254f84c46ed7676e618b001` |
| `sofie-rundown-editor-part-types.json` | `2bd2c0c6f29e4f84575ba86e47ee20861cd4ffe75a2421d7a6b833d6dc5c991b` |
| `sofie-rundown-editor-segment-types.json` | `56f68da340a1029f4c31a1f69b6594e5d440f1e7223528cd2ce9dbaa8c1aaf7b` |

Checksums are owned by the consumer script (they must match that commit’s `assets/*.json`).
Recompute with:

```bash
git -C /path/to/sofie show <sha>:assets/<file>.json | sha256sum
```

**Both consumers:** set `PINNED_SOFIE_ASSETS_REF` and every `EXPECTED_SHA256[…]` in
`scripts/fetch-sofie-megarepo-assets.sh` in the **same** commit (no older-SHA fallback —
fail closed if that revision cannot be fetched or verified).

## Bumping when megarepo assets change

1. Merge the asset change into `tojemoc/sofie` `main` and record the **merge commit SHA**.
2. In each consumer (`unopus`, `sofie-demo-blueprints`):
   - Set the pin to that merge commit SHA.
   - Update every entry in the expected SHA-256 map.
   - Run the fetch script once; confirm exit 0.
   - Intentionally break one checksum (or the pin) and confirm exit 1 + cleaned dest.
3. Ship consumer PRs that bump **pin + checksums in the same commit**.

Do not pin unmerged feature-branch tips for the long-lived consumer default. When an
open megarepo PR changes `assets/`, bump the pin table and consumer scripts to the
immutable commit that introduced those bytes in the same change set (then retarget to
the merge commit on `main` once it exists, if different).

## Runtime env

After a successful fetch, consumers set `SOFIE_MEGAREPO_ASSETS` to the export path
printed by the script (CI via `$GITHUB_ENV`; local shells should
`eval "$(bash scripts/fetch-sofie-megarepo-assets.sh)"`). Blueprints exports the
`…/current` generation pointer (atomic symlink), not a directory that is updated
file-by-file. Nested megarepo layouts do not need the fetch script.
