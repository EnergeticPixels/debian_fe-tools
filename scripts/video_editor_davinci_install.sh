#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
	echo "This script must run as root. Use: sudo bash scripts/video_editor_davinci_install.sh" >&2
	exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

load_optional_davinci_env() {
	# Support non-exported variables in .env so begin_here.sh works without manual export.
	if [[ -f "$ENV_FILE" ]]; then
		# shellcheck source=/dev/null
		source "$ENV_FILE"
	fi
}

resolve_target_home() {
	local target_user target_home
	target_user="${SUDO_USER:-}"
	target_home="$HOME"

	if [[ -n "$target_user" ]]; then
		target_home="$(getent passwd "$target_user" | cut -d: -f6 || true)"
	fi

	if [[ -z "$target_home" ]]; then
		target_home="$HOME"
	fi

	echo "$target_home"
}

download_zip_from_url() {
	local zip_url="$1"
	local target_home install_dir zip_name destination

	target_home="$(resolve_target_home)"
	install_dir="${DAVINCI_INSTALL_DIR:-$target_home/install/davinci}"
	zip_name="$(basename "$zip_url")"
	if [[ -z "$zip_name" || "$zip_name" == "/" ]]; then
		zip_name="davinci-resolve-linux.zip"
	fi
	destination="$install_dir/$zip_name"

	mkdir -p "$install_dir"

	log "Downloading DaVinci .zip to $destination"
	if command -v curl >/dev/null 2>&1; then
		curl -fL "$zip_url" -o "$destination"
	elif command -v wget >/dev/null 2>&1; then
		wget -O "$destination" "$zip_url"
	else
		echo "Neither curl nor wget is available to download DAVINCI_ZIP_URL" >&2
		return 1
	fi

	echo "$destination"
}

install_from_local_deb() {
	local deb_path="$1"

	if [[ ! -f "$deb_path" ]]; then
		echo "DaVinci installer .deb not found: $deb_path" >&2
		return 1
	fi

	log "Installing DaVinci from local .deb: $deb_path"
	apt-get install -y "$deb_path"
}

install_from_deb_url() {
	local deb_url="$1"
	local temp_deb

	temp_deb="$(mktemp /tmp/davinci-installer-XXXXXX.deb)"
	log "Downloading DaVinci installer from URL"
	if command -v curl >/dev/null 2>&1; then
		curl -fL "$deb_url" -o "$temp_deb"
	elif command -v wget >/dev/null 2>&1; then
		wget -O "$temp_deb" "$deb_url"
	else
		echo "Neither curl nor wget is available to download DAVINCI_DEB_URL" >&2
		return 1
	fi

	log "Installing downloaded DaVinci .deb package"
	apt-get install -y "$temp_deb"
	rm -f "$temp_deb"
}

resolve_makeresolvedeb_script() {
	local maker_source="$1"
	local work_dir="$2"
	local maker_script

	if [[ ! -f "$maker_source" ]]; then
		echo "makeresolvedeb source not found: $maker_source" >&2
		return 1
	fi

	case "$maker_source" in
		*.tar.gz|*.tgz)
			tar -xzf "$maker_source" -C "$work_dir"
			maker_script="$(find "$work_dir" -maxdepth 3 -type f -name 'makeresolvedeb*.sh' | head -n 1)"
			if [[ -z "$maker_script" ]]; then
				echo "Could not find makeresolvedeb script inside archive: $maker_source" >&2
				return 1
			fi
			;;
		*.sh)
			maker_script="$maker_source"
			;;
		*)
			echo "Unsupported DAVINCI_MAKERESOLVEDEB_PATH format: $maker_source" >&2
			echo "Use a .sh script or .tar.gz archive." >&2
			return 1
			;;
	esac

	echo "$maker_script"
}

install_from_run_with_makeresolvedeb() {
	local run_path="$1"
	local maker_source="$2"
	local work_dir run_copy maker_script deb_path

	if [[ ! -f "$run_path" ]]; then
		echo "DaVinci .run installer not found: $run_path" >&2
		return 1
	fi

	work_dir="$(mktemp -d /tmp/davinci-convert-XXXXXX)"
	run_copy="$work_dir/$(basename "$run_path")"
	cp "$run_path" "$run_copy"

	maker_script="$(resolve_makeresolvedeb_script "$maker_source" "$work_dir")" || {
		rm -rf "$work_dir"
		return 1
	}

	chmod +x "$maker_script" || true
	log "Converting DaVinci .run installer to .deb via makeresolvedeb"
	(
		cd "$work_dir"
		bash "$maker_script" "$run_copy"
	)

	deb_path="$(find "$work_dir" -maxdepth 3 -type f -name '*.deb' | head -n 1)"
	if [[ -z "$deb_path" ]]; then
		echo "makeresolvedeb did not produce a .deb package" >&2
		rm -rf "$work_dir"
		return 1
	fi

	log "Installing converted DaVinci .deb package"
	apt-get install -y "$deb_path"
	rm -rf "$work_dir"
}

extract_run_from_zip() {
	local zip_path="$1"
	local work_dir="$2"
	local run_path

	if [[ ! -f "$zip_path" ]]; then
		echo "DaVinci .zip installer not found: $zip_path" >&2
		return 1
	fi

	if ! command -v unzip >/dev/null 2>&1; then
		apt-get install -y unzip
	fi

	unzip -o "$zip_path" -d "$work_dir" >/dev/null
	run_path="$(find "$work_dir" -maxdepth 3 -type f -name '*.run' | head -n 1)"
	if [[ -z "$run_path" ]]; then
		echo "No .run file found in archive: $zip_path" >&2
		return 1
	fi

	echo "$run_path"
}

load_optional_davinci_env

log "Installing GTK/GDK, multimedia, and rendering dependencies for DaVinci Resolve"
apt-get install -y --no-install-recommends \
	libgtk-3-0 \
	libgdk-pixbuf-2.0-0 \
	libxkbcommon0 \
	libxkbcommon-x11-0 \
	libgl1 \
	libglvnd0 \
	libgl1-mesa-dri \
	libglib2.0-0 \
	libxext6 \
	libxrender1 \
	libxi6 \
	libsm6 \
	libfontconfig1 \
	libx11-6 \
	libasound2 \
	libgstreamer1.0-0 \
	gstreamer1.0-plugins-base \
	gstreamer1.0-plugins-good \
	gstreamer1.0-libav \
	ocl-icd-opencl-dev

log "Note: NVIDIA drivers are not auto-installed here; handle GPU drivers separately per host/WSL setup."

log "Attempting DaVinci Resolve installation"
apt-get update

if [[ -n "${DAVINCI_DEB_PATH:-}" ]]; then
	install_from_local_deb "$DAVINCI_DEB_PATH" || exit 1
elif [[ -n "${DAVINCI_DEB_URL:-}" ]]; then
	install_from_deb_url "$DAVINCI_DEB_URL" || exit 1
elif [[ -n "${DAVINCI_RUN_PATH:-}" ]]; then
	if [[ -z "${DAVINCI_MAKERESOLVEDEB_PATH:-}" ]]; then
		echo "DAVINCI_RUN_PATH is set but DAVINCI_MAKERESOLVEDEB_PATH is not set." >&2
		exit 1
	fi
	install_from_run_with_makeresolvedeb "$DAVINCI_RUN_PATH" "$DAVINCI_MAKERESOLVEDEB_PATH" || exit 1
elif [[ -n "${DAVINCI_ZIP_PATH:-}" ]]; then
	if [[ -z "${DAVINCI_MAKERESOLVEDEB_PATH:-}" ]]; then
		echo "DAVINCI_ZIP_PATH is set but DAVINCI_MAKERESOLVEDEB_PATH is not set." >&2
		exit 1
	fi
	temp_zip_dir="$(mktemp -d /tmp/davinci-zip-XXXXXX)"
	run_from_zip="$(extract_run_from_zip "$DAVINCI_ZIP_PATH" "$temp_zip_dir")" || {
		rm -rf "$temp_zip_dir"
		exit 1
	}
	install_from_run_with_makeresolvedeb "$run_from_zip" "$DAVINCI_MAKERESOLVEDEB_PATH" || {
		rm -rf "$temp_zip_dir"
		exit 1
	}
	rm -rf "$temp_zip_dir"
elif [[ -n "${DAVINCI_ZIP_URL:-}" ]]; then
	if [[ -z "${DAVINCI_MAKERESOLVEDEB_PATH:-}" ]]; then
		echo "DAVINCI_ZIP_URL is set but DAVINCI_MAKERESOLVEDEB_PATH is not set." >&2
		exit 1
	fi
	downloaded_zip_path="$(download_zip_from_url "$DAVINCI_ZIP_URL")" || exit 1
	temp_zip_dir="$(mktemp -d /tmp/davinci-zip-XXXXXX)"
	run_from_zip="$(extract_run_from_zip "$downloaded_zip_path" "$temp_zip_dir")" || {
		rm -rf "$temp_zip_dir"
		exit 1
	}
	install_from_run_with_makeresolvedeb "$run_from_zip" "$DAVINCI_MAKERESOLVEDEB_PATH" || {
		rm -rf "$temp_zip_dir"
		exit 1
	}
	rm -rf "$temp_zip_dir"
else
	candidate_package=""
	for package_name in davinci-resolve davinci-resolve-studio; do
		candidate_version="$(apt-cache policy "$package_name" | awk '/Candidate:/ {print $2}')"
		if [[ -n "$candidate_version" && "$candidate_version" != "(none)" ]]; then
			candidate_package="$package_name"
			break
		fi
	done

	if [[ -z "$candidate_package" ]]; then
		echo "DaVinci installation failed: no valid source found." >&2
		echo "Provide DAVINCI_DEB_PATH, DAVINCI_DEB_URL, DAVINCI_RUN_PATH (+ DAVINCI_MAKERESOLVEDEB_PATH), or DAVINCI_ZIP_PATH (+ DAVINCI_MAKERESOLVEDEB_PATH)." >&2
		exit 1
	fi

	log "Installing DaVinci package from apt source: $candidate_package"
	apt-get install -y "$candidate_package"
fi

log "Fixing any broken dependencies or incomplete installations"
apt-get install -y --fix-broken --fix-missing

if command -v resolve >/dev/null 2>&1; then
	log "DaVinci Resolve installed: command 'resolve' is available"
elif [[ -x "/opt/resolve/bin/resolve" ]]; then
	log "DaVinci Resolve installed at /opt/resolve/bin/resolve"
else
	echo "DaVinci Resolve installation verification failed: runtime executable not found" >&2
	exit 1
fi
