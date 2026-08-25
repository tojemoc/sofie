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

# Locate a consumer repo by directory name. The Sofie superproject is checked
# out at different places depending on context (e.g. /agent/repos/sofie on a
# Cloud Agent VM, /workspace during an environment build), and the four consumer
# repos are provisioned as siblings via repositoryDependencies. Search the
# likely roots and echo the first match; echo nothing if not found.
find_repo() {
	local name="$1" candidate
	for candidate in \
		"$REPOS_ROOT/$name" \
		"/agent/repos/$name" \
		"$HOME/$name" \
		"/workspace/$name"; do
		if [ -d "$candidate" ]; then
			(cd "$candidate" && pwd)
			return 0
		fi
	done
	return 0
}

# Core's postinstall requires Meteor on PATH. cloud-env.sh already bootstrapped
# the pinned Node via nvm; install Meteor here if the base image lacks it.
if ! command -v meteor >/dev/null 2>&1; then
	echo "[setup] Installing Meteor 3.4.1..."
	curl -s "https://install.meteor.com/?release=3.4.1" | sh
fi

echo "[setup] node=$(node --version) meteor=$(meteor --version 2>/dev/null || echo missing)"
echo "[setup] SOFIE_MEGAREPO_ASSETS=${SOFIE_MEGAREPO_ASSETS:-<unset>}"

CORE="$(find_repo sofie-core)"
BLUEPRINTS="$(find_repo sofie-demo-blueprints)"
RUNDOWN="$(find_repo unopus)"
ASSETS="$(find_repo sofie-demo-assets)"

# --- Sofie Core: install deps (Meteor + monorepo) then build packages --------
if [ -n "$CORE" ] && [ -d "$CORE" ]; then
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
if [ -n "$BLUEPRINTS" ] && [ -d "$BLUEPRINTS" ]; then
	echo "[setup] === sofie-demo-blueprints ==="
	cd "$BLUEPRINTS"
	corepack enable
	yarn install
else
	echo "[setup] skip sofie-demo-blueprints (not checked out)"
fi

# --- Rundown Editor: install deps + seed backend/.env ------------------------
if [ -n "$RUNDOWN" ] && [ -d "$RUNDOWN" ]; then
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
if [ -n "$ASSETS" ] && [ -d "$ASSETS" ]; then
	echo "[setup] === sofie-demo-assets ==="
	cd "$ASSETS"
	corepack enable
	yarn install
	yarn build
else
	echo "[setup] skip sofie-demo-assets (not checked out)"
fi

echo "[setup] Cloud Agent install complete."
