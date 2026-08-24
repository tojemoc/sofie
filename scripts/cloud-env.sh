#!/usr/bin/env bash
# Shared runtime environment for the Sofie megarepo Cloud Agent.
# Source this (do not execute) from install/start/terminal commands:
#   source scripts/cloud-env.sh
#
# It selects the pinned Node.js, puts Meteor + nvm's node ahead of the VM
# default (/exec-daemon/node), enables Corepack, and points the Rundown Editor
# and Blueprints at the canonical megarepo assets/ directory.

SOFIE_NODE_VERSION="22.22.0"

# Fail loudly (nonzero) instead of silently falling back to the VM's older
# /exec-daemon/node, which is too old for Core and causes confusing downstream
# errors. This script is meant to be sourced, so the inline `return 1` unwinds
# the caller; `|| exit 1` covers the (unsupported) case of running it directly.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
	echo "cloud-env.sh: nvm not found at $NVM_DIR/nvm.sh; cannot provision Node $SOFIE_NODE_VERSION" >&2
	return 1 2>/dev/null || exit 1
fi
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"

# Ensure the pinned Node is installed. Idempotent: the directory check makes this
# a no-op once the version exists (so sourcing from terminals stays fast), and it
# only downloads on a fresh base image during the install phase.
if [ ! -d "$NVM_DIR/versions/node/v$SOFIE_NODE_VERSION" ]; then
	if ! nvm install "$SOFIE_NODE_VERSION"; then
		echo "cloud-env.sh: 'nvm install $SOFIE_NODE_VERSION' failed" >&2
		return 1 2>/dev/null || exit 1
	fi
fi
if ! nvm use "$SOFIE_NODE_VERSION" >/dev/null; then
	echo "cloud-env.sh: 'nvm use $SOFIE_NODE_VERSION' failed" >&2
	return 1 2>/dev/null || exit 1
fi

# The VM default node (/exec-daemon/node) is older than Core requires and is
# prepended to PATH, so explicitly put nvm's bin (and /usr/local/bin for the
# meteor launcher) first.
export PATH="$NVM_DIR/versions/node/v$SOFIE_NODE_VERSION/bin:/usr/local/bin:$PATH"

# Confirm the active node is the pinned version, not a fallback, before continuing.
if [ "$(node --version 2>/dev/null)" != "v$SOFIE_NODE_VERSION" ]; then
	echo "cloud-env.sh: expected Node v$SOFIE_NODE_VERSION but got '$(node --version 2>/dev/null || echo none)'" >&2
	return 1 2>/dev/null || exit 1
fi

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
