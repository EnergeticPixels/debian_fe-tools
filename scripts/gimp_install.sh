#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/gimp_install.sh" >&2
	exit 1
fi

log "Updating apt index for GIMP installation"
apt-get update

log "Installing GIMP and GTK/GDK dependencies"
# Install explicit GTK/GDK core libraries required for GUI rendering
apt-get install -y --no-install-recommends \
	gimp \
	libgtk-3-0 \
	libgdk-pixbuf-2.0-0 \
	libxkbcommon0 \
	libxkbcommon-x11-0 \
	libgl1 \
	libglvnd0

log "Fixing any broken dependencies or incomplete installations"
apt-get install -y --fix-broken --fix-missing

log "Installing WSL-aware GIMP launcher wrapper"
cat > /usr/local/bin/gimp <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Under WSL2, GTK on Wayland can emit noisy xdg_foreign warnings.
# Prefer X11 backend by default, but allow callers to override.
if grep -qi microsoft /proc/version 2>/dev/null; then
	export GDK_BACKEND="${GDK_BACKEND:-x11}"
fi

exec /usr/bin/gimp "$@"
EOF
chmod 0755 /usr/local/bin/gimp

log "Creating optional Script-Fu locale directory to avoid first-run warning"
mkdir -p /usr/lib/x86_64-linux-gnu/gimp/3.0/plug-ins/test-sphere-v3/locale || true

# Set up display environment for WSL2/X11 if not already set
if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
	log "Configuring display environment variables for WSL2"
	# Try to detect WSL2 host IP or use default X11 display
	if grep -qi microsoft /proc/version 2>/dev/null; then
		export DISPLAY=":0"
		log "WSL2 detected: Setting DISPLAY=:0"
	fi
fi

log "Verifying GIMP installation"
if command -v gimp >/dev/null 2>&1; then
	log "GIMP binary found in PATH"
	gimp_version=$(gimp --version 2>&1 | head -n 1 || echo "Unable to get version")
	log "GIMP installed: $gimp_version"
else
	echo "GIMP installation verification failed: command not found" >&2
	log "Debugging: Checking if gimp is installed via dpkg"
	dpkg -l | grep gimp || true
	log "Debugging: Checking PATH: $PATH"
	exit 1
fi
