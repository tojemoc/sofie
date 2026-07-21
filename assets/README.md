# Shared Sofie manifests (megarepo source of truth)

Piece / part / segment type manifests and the SPRÁVY smoke rundown live **here** —
in the `tojemoc/sofie` megarepo — not in `sofie-demo-blueprints` or `unopus`.

| File | Purpose |
|------|---------|
| `sofie-rundown-editor-piece-types.json` | Piece type definitions and GFX preview templates |
| `sofie-rundown-editor-part-types.json` | Part presets (ILU, SYN, GFX, Intro, …) |
| `sofie-rundown-editor-segment-types.json` | Segment presets (Headlines, Opening, …) |
| `spravy-v3-smoke-rundown.json` | End-to-end smoke rundown (`spravy-v3-smoke`) |

### Consumers

- **Rundown Editor (`rundown-editor/` / unopus)** loads the three type JSON files at
  startup and via **Settings → Connection → Reload type manifests from assets**.
  When nested in this megarepo it resolves `../assets/` from the editor root.
- **Demo Blueprints (`blueprints/`)** uses `spravy-v3-smoke-rundown.json` as the
  ingest smoke-test fixture (same nested-megarepo resolution).

Do not reintroduce copies under `blueprints/assets/` or `rundown-editor/assets/`.
Edit these files in PRs against `tojemoc/sofie`.
