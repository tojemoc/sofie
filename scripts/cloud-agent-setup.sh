#!/usr/bin/env bash
# Cloud Agent install script for the Sofie megarepo.
#
# Runs from the sofie superproject root after checkout. Refreshes dependencies
# and builds source-derived artifacts for the four consumer repos, which are
# checked out as siblings (repositoryDependencies):
#
#   ../sofie-core            (Sofie Core — Meteor 3 + Vite WebUI)
#   ../sofie-demo-blueprints (Demo Blueprints — *-bundle.js producer)
#   ../unopus                (Sofie Rundown Editor — Express + React)
#   ../sofie-demo-assets     (Demo Assets — CasparCG HTML templates)
#
# Idempotent: safe to re-run and safe if a consumer repo is not present.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOFIE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPOS_ROOT="$(cd "$SOFIE_ROOT/.." && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/cloud-env.sh"

# Core's postinstall requires Meteor on PATH. It is normally baked into the
# base snapshot; install it if a fresh base image is missing it.
if ! command -v meteor >/dev/null 2>&1; then
	echo "[setup] Installing Meteor 3.4.1..."
	curl -s "https://install.meteor.com/?release=3.4.1" | sh
fi

echo "[setup] node=$(node --version) meteor=$(meteor --version 2>/dev/null || echo missing)"
echo "[setup] SOFIE_MEGAREPO_ASSETS=${SOFIE_MEGAREPO_ASSETS:-<unset>}"

CORE="$REPOS_ROOT/sofie-core"
BLUEPRINTS="$REPOS_ROOT/sofie-demo-blueprints"
RUNDOWN="$REPOS_ROOT/unopus"
ASSETS="$REPOS_ROOT/sofie-demo-assets"

# --- Sofie Core: install deps (Meteor + monorepo) then build packages --------
if [ -d "$CORE" ]; then
	echo "[setup] === sofie-core ==="
	# NODE_ENV=production breaks Core's dev install/build.
	unset NODE_ENV
	cd "$CORE"
	corepack enable
	yarn install
	node ./scripts/install-and-build.mjs
else
	echo "[setup] skip sofie-core (not checked out)"
fi

# --- Demo Blueprints: install deps ------------------------------------------
if [ -d "$BLUEPRINTS" ]; then
	echo "[setup] === sofie-demo-blueprints ==="
	cd "$BLUEPRINTS"
	corepack enable
	yarn install
else
	echo "[setup] skip sofie-demo-blueprints (not checked out)"
fi

# --- Rundown Editor: install deps + seed backend/.env ------------------------
if [ -d "$RUNDOWN" ]; then
	echo "[setup] === unopus (rundown-editor) ==="
	cd "$RUNDOWN"
	corepack enable
	yarn install
	if [ ! -f backend/.env ] && [ -f backend/.env.example ]; then
		cp backend/.env.example backend/.env
		echo "[setup] created backend/.env from example"
	fi
else
	echo "[setup] skip unopus (not checked out)"
fi

# --- Demo Assets: install deps + build CasparCG templates -> deploy/ ---------
if [ -d "$ASSETS" ]; then
	echo "[setup] === sofie-demo-assets ==="
	cd "$ASSETS"
	corepack enable
	yarn install
	yarn build
else
	echo "[setup] skip sofie-demo-assets (not checked out)"
fi

echo "[setup] Cloud Agent install complete."
