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

## Current pin (SPRÁVY piece types + smoke rundown)

Pin is the immutable Sofie commit with restored smoke part scripts, L3D
headline/subline fields, ILU headline manifest cleanup, logo-bug DoubleBox
timing, and smoke weather `cities` payloads.

| Item | Value |
|------|--------|
| Sofie commit | `729e11728170058673e69db1e98a8c045ee47e21` |
| unopus `PINNED_SOFIE_ASSETS_REF` | `729e11728170058673e69db1e98a8c045ee47e21` |
| sofie-demo-blueprints `PINNED_SOFIE_ASSETS_REF` | `729e11728170058673e69db1e98a8c045ee47e21` |
| unopus override (optional) | `SOFIE_ASSETS_REF` — if set, must be a full 40-char lowercase SHA; otherwise defaults to `PINNED_SOFIE_ASSETS_REF` |

Both consumer scripts must pin the **same** commit SHA, verify every file against
`EXPECTED_SHA256` (table below), and fail closed on download or checksum mismatch.

### Per-file SHA-256 (`assets/` at that commit)

| File | SHA-256 |
|------|---------|
| `spravy-v3-smoke-rundown.json` | `eada1218546339c8e624573fe784bfbcec61350d9e316230fd67998f1714a687` |
| `sofie-rundown-editor-piece-types.json` | `c6b939f306b8dfbcbd548c1dcdbf8f8b9f589276f40348bfc5646494f0d6c7bc` |
| `sofie-rundown-editor-part-types.json` | `74d89de9d65298a6d48054ca85cd7319bef56038a09b061f25e81f111040a7e6` |
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
