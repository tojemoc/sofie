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

## Current pins

Consumers may temporarily pin **different** Sofie commits when one repo’s tests still
depend on an older smoke ID schema. Prefer converging on one tip once blueprints smoke
specs are rewritten for the 2026-09-14 RE export.

### unopus (SPRÁVY smoke — 2026-09-14 export + SJV/SPORT CPS + BB weather label)

| Item | Value |
|------|--------|
| Sofie commit | `a1c6b9b727bba9cb9898eff1d3f1b3bc4879740c` |
| unopus `PINNED_SOFIE_ASSETS_REF` | `a1c6b9b727bba9cb9898eff1d3f1b3bc4879740c` |
| unopus override (optional) | `SOFIE_ASSETS_REF` — if set, must be a full 40-char lowercase SHA; otherwise defaults to `PINNED_SOFIE_ASSETS_REF` |

### Per-file SHA-256 at unopus pin (`a1c6b9b…`)

| File | SHA-256 |
|------|---------|
| `spravy-v3-smoke-rundown.json` | `efd3e6b3f6d98b4f1f0f755905989ab349642cee752b0da338cf1964e560f4ad` |
| `sofie-rundown-editor-piece-types.json` | `dce7e9b7b49a338826864b7f289b8e73a62c38ef04a3fa6dd42bd2c908e6a52d` |
| `sofie-rundown-editor-part-types.json` | `676ed7eb27f9111dc4c1c173b85a5ccfee6f309db0ed2e351c2190d1d40040fb` |
| `sofie-rundown-editor-segment-types.json` | `56f68da340a1029f4c31a1f69b6594e5d440f1e7223528cd2ce9dbaa8c1aaf7b` |

### sofie-demo-blueprints (pre-619a6f7 smoke IDs)

Blueprint vitest fixtures still expect `part-hl-*` / `part-tema-1-db` / `seg-tema-5`.
Until those specs are updated, blueprints pins polish-2 smoke:

| Item | Value |
|------|--------|
| Sofie commit | `15dd9742ff31958494247f538152d3a126a0d191` |
| sofie-demo-blueprints `PINNED_SOFIE_ASSETS_REF` | `15dd9742ff31958494247f538152d3a126a0d191` |

### Per-file SHA-256 at blueprints pin (`15dd974…`)

| File | SHA-256 |
|------|---------|
| `spravy-v3-smoke-rundown.json` | `953ef26d858047efbe1621672633e12e033ca60a6507ce5441678ed431d7928a` |
| `sofie-rundown-editor-piece-types.json` | `e8bfa1aa062965c98981982f02a4eb2d1233f63e0254f84c46ed7676e618b001` |
| `sofie-rundown-editor-part-types.json` | `2bd2c0c6f29e4f84575ba86e47ee20861cd4ffe75a2421d7a6b833d6dc5c991b` |
| `sofie-rundown-editor-segment-types.json` | `56f68da340a1029f4c31a1f69b6594e5d440f1e7223528cd2ce9dbaa8c1aaf7b` |

Checksums are owned by the consumer script (they must match that commit’s `assets/*.json`).
Recompute with:

```bash
git -C /path/to/sofie show <sha>:assets/<file>.json | sha256sum
```

**Each consumer:** set `PINNED_SOFIE_ASSETS_REF` and every `EXPECTED_SHA256[…]` in
`scripts/fetch-sofie-megarepo-assets.sh` in the **same** commit (no older-SHA fallback —
fail closed if that revision cannot be fetched or verified).

## Bumping when megarepo assets change

1. Merge the asset change into `tojemoc/sofie` `main` and record the **merge commit SHA**.
2. In each consumer (`unopus`, `sofie-demo-blueprints`):
   - Set the pin to that merge commit SHA (or keep a documented older pin if tests require it).
   - Update every entry in the expected SHA-256 map.
   - Run the fetch script once; confirm exit 0.
   - Intentionally break one checksum (or the pin) and confirm exit 1 + cleaned dest.
3. Ship consumer PRs that bump **pin + checksums in the same commit**.

Do not pin unmerged feature-branch tips for the long-lived consumer default. When an
open megarepo PR changes `assets/`, bump the pin table and consumer scripts to the
immutable commit that introduced those bytes in the same change set (then retarget to
the merge commit on `main` once it exists, if different).

## Runtime env

Set `SOFIE_MEGAREPO_ASSETS` to the fetch script’s `…/current` symlink (or a nested megarepo
`assets/` directory). Consumers must never observe a mixed old/new tree mid-fetch.
