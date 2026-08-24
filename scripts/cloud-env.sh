#!/usr/bin/env bash
# Shared runtime environment for the Sofie megarepo Cloud Agent.
# Source this (do not execute) from install/start/terminal commands:
#   source scripts/cloud-env.sh
#
# It selects the pinned Node.js, puts Meteor + nvm's node ahead of the VM
# default (/exec-daemon/node), enables Corepack, and points the Rundown Editor
# and Blueprints at the canonical megarepo assets/ directory.

SOFIE_NODE_VERSION="22.22.0"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use "$SOFIE_NODE_VERSION" >/dev/null 2>&1 || true

# The VM default node (/exec-daemon/node) is older than Core requires and is
# prepended to PATH, so explicitly put nvm's bin (and /usr/local/bin for the
# meteor launcher) first.
export PATH="$NVM_DIR/versions/node/v$SOFIE_NODE_VERSION/bin:/usr/local/bin:$PATH"

# Don't block first-use yarn downloads on an interactive [Y/n] prompt.
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

# Canonical type manifests + smoke rundown live in this megarepo's assets/.
# Rundown Editor backend (manifest.ts) and Blueprints tests resolve them from
# here when the consumer repos are checked out as siblings rather than nested.
_sofie_env_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../assets" 2>/dev/null && pwd)"
if [ -n "$_sofie_env_dir" ]; then
	export SOFIE_MEGAREPO_ASSETS="$_sofie_env_dir"
fi
unset _sofie_env_dir
