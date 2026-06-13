#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/audacity_install.sh" >&2
	exit 1
fi

log "Updating apt index for Audacity installation"
apt-get update
log "Installing Audacity and GTK/GDK dependencies"
apt-get install -y --no-install-recommends \
	audacity \
	libgtk-3-0 \
	libgdk-pixbuf-2.0-0 \
	libxkbcommon0 \
	libxkbcommon-x11-0 \
	libgl1 \
	libglvnd0

log "Fixing any broken dependencies or incomplete installations"
apt-get install -y --fix-broken --fix-missing

if command -v audacity >/dev/null 2>&1; then
	log "Audacity binary found in PATH"
	audacity_version=$(audacity --version 2>&1 | head -n 1 || echo "Unable to get version")
	log "Audacity installed: $audacity_version"
else
	echo "Audacity installation verification failed: command not found" >&2
	exit 1
fi
