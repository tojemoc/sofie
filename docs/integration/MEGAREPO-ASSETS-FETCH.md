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

## Current pin (production media rename)

Pin is the immutable sofie commit that contains the renamed smoke/mediaPick assets
(HEADLINEs, `wipes/wipe*`, `assets/intro_michal`, `loops/bg_loop`). After sofie
[#25](https://github.com/tojemoc/sofie/pull/25) merges, if GitHub creates a different
merge commit with the **same** `assets/` tree, either SHA is fine; prefer the merge
commit on `main` once available and keep the checksums below.

| Item | Value |
|------|--------|
| Sofie commit | `83234e65d118a4c7e0b5b57e35321d7b19852419` |
| Env override | `SOFIE_ASSETS_REF` (unopus) — full 40-char SHA only; bump with checksums |

### Per-file SHA-256 (`assets/` at that commit)

| File | SHA-256 |
|------|---------|
| `spravy-v3-smoke-rundown.json` | `39db9c74f952848e0da989bfee79c6d6a9df9ca88a0bde2b6b1f20c338272de3` |
| `sofie-rundown-editor-piece-types.json` | `69ab2a662488ea246d039185863d7c16fd282fe33ceda21caa233b8da9dc6f59` |
| `sofie-rundown-editor-part-types.json` | `aa3c8c899b499ce1c4c431ec4c904e8475980b139bdf4dfefa54c7ee52167846` |
| `sofie-rundown-editor-segment-types.json` | `56f68da340a1029f4c31a1f69b6594e5d440f1e7223528cd2ce9dbaa8c1aaf7b` |

Checksums are owned by the consumer script (they must match that commit’s `assets/*.json`).
Recompute with:

```bash
git -C /path/to/sofie show <sha>:assets/<file>.json | sha256sum
```

**unopus:** set `PINNED_SOFIE_ASSETS_REF` and every `EXPECTED_SHA256[…]` in the **same**
commit. **sofie-demo-blueprints:** prepend the Sofie commit to `REFS=(…)` in the same
bump (baseline `loops/bg_loop` already landed in
[blueprints#58](https://github.com/tojemoc/sofie-demo-blueprints/pull/58)).

## Bumping when megarepo assets change

1. Land the asset change in `tojemoc/sofie` (merge to `main` or note the commit SHA).
2. In each consumer (`unopus`, `sofie-demo-blueprints`):
   - Set the pin to that commit SHA.
   - Update every entry in the expected SHA-256 map (or equivalent).
   - Run the fetch script once; confirm exit 0.
   - Intentionally break one checksum and confirm exit 1 + cleaned dest.
3. Ship consumer PRs that bump **pin + checksums in the same commit**.

Blueprints may keep a short **fallback SHA list** for resilience, but each ref must still be
an immutable commit — never a branch — and preferred path is the same pin + checksum
model as unopus.

## Runtime env

After a successful fetch, consumers set `SOFIE_MEGAREPO_ASSETS` to the download directory
(CI via `$GITHUB_ENV`; local shells should `eval "$(bash scripts/fetch-sofie-megarepo-assets.sh)"`
where the script prints an `export` line, or export manually). Nested megarepo layouts do
not need the fetch script.
