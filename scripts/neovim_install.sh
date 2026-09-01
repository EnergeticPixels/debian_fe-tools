#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/neovim_install.sh" >&2
	exit 1
fi

load_neovim_env() {
	local env_file major minor patch
	env_file="$SCRIPT_DIR/../.env"

	if [[ -f "$env_file" ]]; then
		# shellcheck source=/dev/null
		source "$env_file"
	fi

	if [[ -z "${NEOVIM_VERSION:-}" && -n "${neovim_version:-}" ]]; then
		NEOVIM_VERSION="$neovim_version"
	fi

	NEOVIM_VERSION="${NEOVIM_VERSION:-0.12.0}"
	if [[ ! "$NEOVIM_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		echo "Invalid NEOVIM_VERSION '$NEOVIM_VERSION'. Expected format: X.Y.Z (example: 0.12.0)" >&2
		exit 1
	fi

	IFS='.' read -r major minor patch <<< "$NEOVIM_VERSION"
	if (( major < 1 && minor < 12 )); then
		echo "NEOVIM_VERSION must be 0.12.0 or newer. Current value: '$NEOVIM_VERSION'" >&2
		exit 1
	fi

	export NEOVIM_VERSION
}

resolve_arch_suffix() {
	case "$(uname -m)" in
		x86_64) echo "x86_64" ;;
		aarch64|arm64) echo "arm64" ;;
		*)
			echo "Unsupported architecture for Neovim release tarball: $(uname -m)" >&2
			exit 1
			;;
	esac
}

load_neovim_env

log "Installing Neovim v${NEOVIM_VERSION} from upstream release"
apt-get install -y curl ca-certificates tar

ARCH_SUFFIX="$(resolve_arch_suffix)"
TARBALL="nvim-linux-${ARCH_SUFFIX}.tar.gz"
DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/${TARBALL}"
TARGET_DIR="/opt/nvim-linux-${ARCH_SUFFIX}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fL "$DOWNLOAD_URL" -o "$TMP_DIR/$TARBALL"
rm -rf "$TARGET_DIR"
tar -C /opt -xzf "$TMP_DIR/$TARBALL"
ln -sf "$TARGET_DIR/bin/nvim" /usr/local/bin/nvim

log "Setting neovim as the system default editor"
update-alternatives --set editor /usr/local/bin/nvim 2>/dev/null || \
	update-alternatives --install /usr/bin/editor editor /usr/local/bin/nvim 80

# Persist EDITOR and VISUAL for login shells system-wide.
PROFILE_FILE="/etc/profile.d/editor.sh"
cat > "$PROFILE_FILE" <<'EOF'
export EDITOR=nvim
export VISUAL=nvim
EOF
chmod 644 "$PROFILE_FILE"

log "Neovim set as default editor (EDITOR=nvim, VISUAL=nvim)"