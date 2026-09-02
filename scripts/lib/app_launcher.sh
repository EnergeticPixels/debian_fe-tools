#!/usr/bin/env bash
# Shared helpers for launching GUI apps with the same timestamped logging
# convention used by begin_here.sh during provisioning.

if ! command -v log >/dev/null 2>&1; then
	log() {
		printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
	}
fi

# Mirrors the WSL2 DISPLAY fallback in begin_here.sh so ad-hoc launches
# get the same GUI environment as provisioning runs.
ensure_wsl_display() {
	if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
		if grep -qi microsoft /proc/version 2>/dev/null; then
			export DISPLAY=":0"
			log "WSL2 detected: Setting DISPLAY=:0 for GUI applications"
		fi
	fi
}

# Launches an app in the background, redirecting stdout/stderr to a
# timestamped log file under ~/.debian_build/logs/apps (same log root
# provisioning uses) instead of spilling GTK/GDK warnings into the terminal.
launch_logged_app() {
	local app_name="$1"
	shift
	local binary_path="$1"
	shift

	local log_dir timestamp log_file latest_log_path pid

	log_dir="$HOME/.debian_build/logs/apps"
	timestamp="$(date +'%Y%m%d_%H%M%S')"
	log_file="$log_dir/${app_name}_${timestamp}.log"
	latest_log_path="$log_dir/${app_name}_latest.log"

	mkdir -p "$log_dir"
	touch "$log_file"
	ln -sfn "$(basename "$log_file")" "$latest_log_path"

	ensure_wsl_display

	log "Launching $app_name (log: $log_file)"
	nohup "$binary_path" "$@" > "$log_file" 2>&1 &
	pid=$!
	disown "$pid" 2>/dev/null || true

	log "$app_name started with PID $pid (detached from this terminal)"
	log "Tail live output with: tail -f $log_file"
}
