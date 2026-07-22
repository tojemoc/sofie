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

## Current pin (as of sofie #13)

| Item | Value |
|------|--------|
| Sofie commit | `cdc2d3b66407e920159a1f5772c616d0056ca990` (DoubleBox / wipe assets on `main`) |
| Env override | `SOFIE_ASSETS_REF` (unopus script) — override only together with matching checksums |

Checksums are owned by the consumer script (they must match that commit’s `assets/*.json`).
Recompute with:

```bash
git -C /path/to/sofie show <sha>:assets/<file>.json | sha256sum
```

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
