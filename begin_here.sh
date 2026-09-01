#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

normalize_boolean_value() {
	local raw_value normalized
	raw_value="$1"
	normalized="$(printf '%s' "$raw_value" | tr '[:upper:]' '[:lower:]')"

	case "$normalized" in
		1|true|yes|y|on)
			echo "true"
			;;
		0|false|no|n|off)
			echo "false"
			;;
		*)
			echo ""
			;;
	esac
}

require_root() {
	if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
		echo "This script must run as root. Use: sudo bash begin_here.sh" >&2
		exit 1
	fi
}

bootstrap_env_file() {
	local env_file="$SCRIPT_DIR/.env"
	local env_sample_file="$SCRIPT_DIR/.env.sample"

	if [[ ! -f "$env_file" && -f "$env_sample_file" ]]; then
		cp "$env_sample_file" "$env_file"
		log "Created $env_file from .env.sample. Update values before key generation if needed."
	fi
}

setup_logging() {
	local target_user target_home log_dir timestamp log_file_name latest_log_path

	target_user="${SUDO_USER:-}"
	target_home="$HOME"

	if [[ -n "$target_user" ]]; then
		target_home="$(getent passwd "$target_user" | cut -d: -f6 || true)"
	fi

	if [[ -z "$target_home" ]]; then
		target_home="$HOME"
	fi

	log_dir="$target_home/.debian_build/logs"
	timestamp="$(date +'%Y%m%d_%H%M%S')"
	LOG_FILE="$log_dir/provision_${timestamp}.log"
	log_file_name="$(basename "$LOG_FILE")"
	latest_log_path="$log_dir/latest.log"

	mkdir -p "$log_dir"
	touch "$LOG_FILE"
	ln -sfn "$log_file_name" "$latest_log_path"

	if [[ "${EUID:-$(id -u)}" -eq 0 && -n "$target_user" ]]; then
		chown "$target_user:$target_user" "$log_dir" "$LOG_FILE" "$latest_log_path" 2>/dev/null || true
	fi

	exec > >(tee -a "$LOG_FILE") 2>&1
	log "Writing detailed log to $LOG_FILE"
}

run_core_script() {
	local script_path="$1"
	local script_name
	script_name="$(basename "$script_path")"

	if [[ ! -f "$script_path" ]]; then
		log "Skipping missing script: $script_path"
		return 0
	fi

	# chmod +x "$script_path"
	log "Running $script_name"

	bash "$script_path"
}

load_editor_env() {
	local env_file normalized
	env_file="$SCRIPT_DIR/.env"

	if [[ -f "$env_file" ]]; then
		# shellcheck source=/dev/null
		source "$env_file"
	fi

	if [[ -z "${NEOVIM_ENABLE:-}" && -n "${neovim_enable:-}" ]]; then
		NEOVIM_ENABLE="$neovim_enable"
	fi

	NEOVIM_ENABLE="${NEOVIM_ENABLE:-true}"
	normalized="$(normalize_boolean_value "$NEOVIM_ENABLE")"
	if [[ -z "$normalized" ]]; then
		echo "Invalid NEOVIM_ENABLE '$NEOVIM_ENABLE'. Supported values: true/false" >&2
		exit 1
	fi

	NEOVIM_ENABLE="$normalized"
	export NEOVIM_ENABLE
}

main() {
	require_root
	export DEBIAN_FRONTEND=noninteractive
	
	# Configure display environment for WSL2 GUI applications
	if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
		if grep -qi microsoft /proc/version 2>/dev/null; then
			export DISPLAY=":0"
			log "WSL2 detected: Setting DISPLAY=:0 for GUI applications"
		fi
	fi
	
	setup_logging

	log "Starting Debian provisioning"
	apt-get update
	load_editor_env

	if [[ "$NEOVIM_ENABLE" == "true" ]]; then
		log "Starting editor setup (neovim)"
		run_core_script "$SCRIPTS_DIR/neovim_install.sh"
		log "Completed editor setup (neovim)"
	else
		log "NEOVIM_ENABLE=false. Skipping editor setup (neovim)"
	fi

	run_core_script "$SCRIPTS_DIR/frontend_apps_install.sh"
	log "Completed front-end creative apps setup"

	log "Provisioning complete"
}

main "$@"