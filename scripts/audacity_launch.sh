#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_LAUNCHER_LIB="$SCRIPT_DIR/lib/app_launcher.sh"

if [[ ! -f "$APP_LAUNCHER_LIB" ]]; then
	echo "Missing helper library: $APP_LAUNCHER_LIB" >&2
	exit 1
fi

# shellcheck source=/dev/null
source "$APP_LAUNCHER_LIB"

APP_NAME="audacity"
BINARY_NAME="audacity"

if ! BINARY_PATH="$(command -v "$BINARY_NAME")"; then
	echo "'$BINARY_NAME' is not installed or not in PATH. Install it first: sudo bash scripts/audacity_install.sh" >&2
	exit 1
fi

launch_logged_app "$APP_NAME" "$BINARY_PATH" "$@"
