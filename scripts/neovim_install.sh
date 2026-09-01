#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/neovim_install.sh" >&2
	exit 1
fi

log "Ensuring neovim is installed"
apt-get install -y neovim

log "Setting neovim as the system default editor"
update-alternatives --set editor /usr/bin/nvim 2>/dev/null || \
	update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60

# Persist EDITOR and VISUAL for login shells system-wide.
PROFILE_FILE="/etc/profile.d/editor.sh"
cat > "$PROFILE_FILE" <<'EOF'
export EDITOR=nvim
export VISUAL=nvim
EOF
chmod 644 "$PROFILE_FILE"

log "Neovim set as default editor (EDITOR=nvim, VISUAL=nvim)"