#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/blender_install.sh" >&2
	exit 1
fi

log "Updating apt index for Blender installation"
apt-get update
log "Installing Blender and GTK/GDK dependencies"
apt-get install -y --no-install-recommends \
	blender \
	libgtk-3-0 \
	libgdk-pixbuf-2.0-0 \
	libxkbcommon0 \
	libxkbcommon-x11-0 \
	libgl1 \
	libglvnd0

log "Fixing any broken dependencies or incomplete installations"
apt-get install -y --fix-broken --fix-missing

if command -v blender >/dev/null 2>&1; then
	log "Blender binary found in PATH"
	blender_version=$(blender --version 2>&1 | head -n 1 || echo "Unable to get version")
	log "Blender installed: $blender_version"
else
	echo "Blender installation verification failed: command not found" >&2
	exit 1
fi
