#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/frontend_apps_install.sh" >&2
	exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_LIB="$SCRIPT_DIR/lib/frontend_apps.sh"
VIDEO_EDITOR_SCRIPT="$SCRIPT_DIR/video_editor_install.sh"

if [[ ! -f "$FRONTEND_LIB" ]]; then
	echo "Missing helper library: $FRONTEND_LIB" >&2
	exit 1
fi

# shellcheck source=/dev/null
source "$FRONTEND_LIB"
load_frontend_apps_env

preflight_davinci_install_source() {
	local candidate_package candidate_version package_name

	if [[ "$VIDEO_EDITOR" != "davinci" ]]; then
		return 0
	fi

	log "Preflight: validating DaVinci installation source"

	if [[ -n "${DAVINCI_DEB_PATH:-}" ]]; then
		if [[ ! -f "$DAVINCI_DEB_PATH" ]]; then
			echo "DaVinci preflight failed: DAVINCI_DEB_PATH does not exist: $DAVINCI_DEB_PATH" >&2
			exit 1
		fi
		log "DaVinci preflight passed: local installer found at DAVINCI_DEB_PATH"
		return 0
	fi

	if [[ -n "${DAVINCI_DEB_URL:-}" ]]; then
		log "DaVinci preflight passed: DAVINCI_DEB_URL is configured"
		return 0
	fi

	if [[ -n "${DAVINCI_RUN_PATH:-}" ]]; then
		if [[ ! -f "$DAVINCI_RUN_PATH" ]]; then
			echo "DaVinci preflight failed: DAVINCI_RUN_PATH does not exist: $DAVINCI_RUN_PATH" >&2
			exit 1
		fi
		if [[ -z "${DAVINCI_MAKERESOLVEDEB_PATH:-}" ]]; then
			echo "DaVinci preflight failed: DAVINCI_RUN_PATH is set but DAVINCI_MAKERESOLVEDEB_PATH is empty." >&2
			echo "Set DAVINCI_MAKERESOLVEDEB_PATH to makeresolvedeb .sh or .tar.gz." >&2
			exit 1
		fi
		if [[ ! -f "$DAVINCI_MAKERESOLVEDEB_PATH" ]]; then
			echo "DaVinci preflight failed: DAVINCI_MAKERESOLVEDEB_PATH does not exist: $DAVINCI_MAKERESOLVEDEB_PATH" >&2
			exit 1
		fi
		log "DaVinci preflight passed: DAVINCI_RUN_PATH and DAVINCI_MAKERESOLVEDEB_PATH are configured"
		return 0
	fi

	if [[ -n "${DAVINCI_ZIP_PATH:-}" ]]; then
		if [[ ! -f "$DAVINCI_ZIP_PATH" ]]; then
			echo "DaVinci preflight failed: DAVINCI_ZIP_PATH does not exist: $DAVINCI_ZIP_PATH" >&2
			exit 1
		fi
		if [[ -z "${DAVINCI_MAKERESOLVEDEB_PATH:-}" ]]; then
			echo "DaVinci preflight failed: DAVINCI_ZIP_PATH is set but DAVINCI_MAKERESOLVEDEB_PATH is empty." >&2
			echo "Set DAVINCI_MAKERESOLVEDEB_PATH to makeresolvedeb .sh or .tar.gz." >&2
			exit 1
		fi
		if [[ ! -f "$DAVINCI_MAKERESOLVEDEB_PATH" ]]; then
			echo "DaVinci preflight failed: DAVINCI_MAKERESOLVEDEB_PATH does not exist: $DAVINCI_MAKERESOLVEDEB_PATH" >&2
			exit 1
		fi
		log "DaVinci preflight passed: DAVINCI_ZIP_PATH and DAVINCI_MAKERESOLVEDEB_PATH are configured"
		return 0
	fi

	if [[ -n "${DAVINCI_ZIP_URL:-}" ]]; then
		if [[ -z "${DAVINCI_MAKERESOLVEDEB_PATH:-}" ]]; then
			echo "DaVinci preflight failed: DAVINCI_ZIP_URL is set but DAVINCI_MAKERESOLVEDEB_PATH is empty." >&2
			echo "Set DAVINCI_MAKERESOLVEDEB_PATH to makeresolvedeb .sh or .tar.gz." >&2
			exit 1
		fi
		if [[ ! -f "$DAVINCI_MAKERESOLVEDEB_PATH" ]]; then
			echo "DaVinci preflight failed: DAVINCI_MAKERESOLVEDEB_PATH does not exist: $DAVINCI_MAKERESOLVEDEB_PATH" >&2
			exit 1
		fi
		log "DaVinci preflight passed: DAVINCI_ZIP_URL and DAVINCI_MAKERESOLVEDEB_PATH are configured"
		return 0
	fi

	candidate_package=""
	for package_name in davinci-resolve davinci-resolve-studio; do
		candidate_version="$(apt-cache policy "$package_name" | awk '/Candidate:/ {print $2}')"
		if [[ -n "$candidate_version" && "$candidate_version" != "(none)" ]]; then
			candidate_package="$package_name"
			break
		fi
	done

	if [[ -n "$candidate_package" ]]; then
		log "DaVinci preflight passed: apt candidate available ($candidate_package)"
		return 0
	fi

	echo "DaVinci preflight failed: VIDEO_EDITOR=davinci but no install source is configured." >&2
	echo "Set one of: DAVINCI_DEB_PATH, DAVINCI_DEB_URL, DAVINCI_RUN_PATH (+ DAVINCI_MAKERESOLVEDEB_PATH), DAVINCI_ZIP_PATH (+ DAVINCI_MAKERESOLVEDEB_PATH), DAVINCI_ZIP_URL (+ DAVINCI_MAKERESOLVEDEB_PATH)." >&2
	echo "Example: DAVINCI_ZIP_PATH=/mnt/c/Users/<you>/Downloads/DaVinci_Resolve_20.0.0_Linux.zip" >&2
	echo "Example: DAVINCI_ZIP_URL=https://example.com/DaVinci_Resolve_20.0.0_Linux.zip" >&2
	echo "Example: DAVINCI_MAKERESOLVEDEB_PATH=/mnt/c/Users/<you>/Downloads/makeresolvedeb_20.0.0.sh" >&2
	exit 1
}

log "=== Front-end Creative Apps Installation Starting ==="
log "INKSCAPE_ENABLE=$INKSCAPE_ENABLE"
log "GIMP_ENABLE=$GIMP_ENABLE"
log "BLENDER_ENABLE=$BLENDER_ENABLE"
log "AUDACITY_ENABLE=$AUDACITY_ENABLE"
log "VIDEO_EDITOR=$VIDEO_EDITOR"

if [[ "$INKSCAPE_ENABLE" == "false" && "$GIMP_ENABLE" == "false" && "$BLENDER_ENABLE" == "false" && "$AUDACITY_ENABLE" == "false" && "$VIDEO_EDITOR" == "none" ]]; then
	log "All front-end creative apps are disabled. Skipping installation."
	exit 0
fi

preflight_davinci_install_source

if [[ "$INKSCAPE_ENABLE" == "true" ]]; then
	log "Installing Inkscape"
	bash "$SCRIPT_DIR/inkscape_install.sh"
fi

if [[ "$GIMP_ENABLE" == "true" ]]; then
	log "Installing GIMP"
	bash "$SCRIPT_DIR/gimp_install.sh"
fi

if [[ "$BLENDER_ENABLE" == "true" ]]; then
	log "Installing Blender"
	bash "$SCRIPT_DIR/blender_install.sh"
fi

if [[ "$AUDACITY_ENABLE" == "true" ]]; then
	log "Installing Audacity"
	bash "$SCRIPT_DIR/audacity_install.sh"
fi

if [[ "$VIDEO_EDITOR" != "none" ]]; then
	if [[ ! -f "$VIDEO_EDITOR_SCRIPT" ]]; then
		echo "Missing video editor dispatcher: $VIDEO_EDITOR_SCRIPT" >&2
		exit 1
	fi

	log "Installing configured video editor: $VIDEO_EDITOR"
	bash "$VIDEO_EDITOR_SCRIPT"
else
	log "VIDEO_EDITOR=none. Skipping video editor installation."
fi

log "=== Front-end Creative Apps Installation Complete ==="
