#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/inkscape_install.sh" >&2
	exit 1
fi

log "Updating apt index for Inkscape installation"
apt-get update
log "Installing Inkscape and GTK/GDK dependencies"
apt-get install -y --no-install-recommends \
	inkscape \
	libgtk-3-0 \
	libgdk-pixbuf-2.0-0 \
	libxkbcommon0 \
	libxkbcommon-x11-0 \
	libgl1 \
	libglvnd0

log "Fixing any broken dependencies or incomplete installations"
apt-get install -y --fix-broken --fix-missing

if command -v inkscape >/dev/null 2>&1; then
	log "Inkscape binary found in PATH"
	inkscape_version=$(inkscape --version 2>&1 | head -n 1 || echo "Unable to get version")
	log "Inkscape installed: $inkscape_version"
else
	echo "Inkscape installation verification failed: command not found" >&2
	exit 1
fi
