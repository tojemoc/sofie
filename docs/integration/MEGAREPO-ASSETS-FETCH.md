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

## Current pin (SPRÁVY smoke rundown demo fixes)

Pin is the immutable Sofie commit with smoke rundown updates: 8s intro,
`l3d-tema` on DoubleBox topics, ILU-style avízo/outro (no DoubleBox).

| Item | Value |
|------|--------|
| Sofie commit | `37bc380f3062b3503ac4beadbbed68e801e80f0b` |
| Unopus pin (committed) | `PINNED_SOFIE_ASSETS_REF` — bump with checksums |
| Unopus override (optional) | `SOFIE_ASSETS_REF` — if set, must be a full 40-char lowercase SHA; otherwise defaults to `PINNED_SOFIE_ASSETS_REF` |

### Per-file SHA-256 (`assets/` at that commit)

| File | SHA-256 |
|------|---------|
| `spravy-v3-smoke-rundown.json` | `24c32d2ddad0607a36a926bdae11bed58fae2c9a227ef166c39ad402febf3c4d` |
| `sofie-rundown-editor-piece-types.json` | `f2435a8172968e39b8075de76950793d4144d2a85a74a0ac20cb20b3415f203c` |
| `sofie-rundown-editor-part-types.json` | `74d89de9d65298a6d48054ca85cd7319bef56038a09b061f25e81f111040a7e6` |
| `sofie-rundown-editor-segment-types.json` | `56f68da340a1029f4c31a1f69b6594e5d440f1e7223528cd2ce9dbaa8c1aaf7b` |

Checksums are owned by the consumer script (they must match that commit’s `assets/*.json`).
Recompute with:

```bash
git -C /path/to/sofie show <sha>:assets/<file>.json | sha256sum
```

**unopus:** set `PINNED_SOFIE_ASSETS_REF` and every `EXPECTED_SHA256[…]` in the **same**
commit. **sofie-demo-blueprints:** set the single `PINNED_SOFIE_ASSETS_REF` in
`scripts/fetch-sofie-megarepo-assets.sh` in the same bump (no older-SHA fallback —
fail closed if that revision cannot be fetched).

## Bumping when megarepo assets change

1. Land the asset change in `tojemoc/sofie` (merge to `main` or note the commit SHA).
2. In each consumer (`unopus`, `sofie-demo-blueprints`):
   - Set the pin to that commit SHA.
   - Update every entry in the expected SHA-256 map (or equivalent; blueprints pin only).
   - Run the fetch script once; confirm exit 0.
   - Intentionally break one checksum (or the pin) and confirm exit 1 + cleaned dest.
3. Ship consumer PRs that bump **pin + checksums in the same commit**.

## Runtime env

After a successful fetch, consumers set `SOFIE_MEGAREPO_ASSETS` to the export path
printed by the script (CI via `$GITHUB_ENV`; local shells should
`eval "$(bash scripts/fetch-sofie-megarepo-assets.sh)"`). Blueprints exports the
`…/current` generation pointer (atomic symlink), not a directory that is updated
file-by-file. Nested megarepo layouts do not need the fetch script.
