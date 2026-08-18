#######################################
# Function: prepare_env_rootfs
# Purpose : Copy a essential environment file into the rootfs environment.
# Globals : None
# Arguments:
#   $1 - Full path to the input environment file
# Returns:
#   0 on success, non-zero on failure
#######################################
prepare_env_rootfs() {
	local input_file="$1"
	local destination="./rootfs/script/"

	# Validate arguments
	if [[ -z "${input_file}" ]]; then
		log_error "Usage: prepare_env_rootfs <input_file>"
		return 1
	fi

	if [[ ! -f "${input_file}" ]]; then
		log_error "Error: File not found: ${input_file}"
		return 1
	fi

	# Create the destination directory if it doesn't exist
	if [[ ! -d "${destination}" ]]; then
		echo "Creating directory: ${destination}"
		mkdir -p "${destination}" || {
			log_error "Error: Failed to create directory ${destination}"
			return 1
		}
	else
		log_info "Directory ${destination} already exists"
	fi

	# Copy the file
	cp "${input_file}" "${destination}/" || {
		log_error "Error: Failed to copy ${input_file} to ${destination}"
		return 1
	}

	echo "Script successfully copied to ${destination}"
	return 0
}

#######################################
# Copy firmware from renesas-ubuntu (yocto output) to rootfs
# Globals:
#   WORK_DIR
# Arguments:
#   $1: src rootfs
#   $2: dest rootfs
#######################################
copy_firmware() {
	source_dir="./$1/lib/firmware/"
	dest_dir="./$2/lib/firmware/"

	# Change dir WORK_DIR
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Check source folder
	if [ ! -d "$source_dir" ]; then
		echo "Source directory $source_dir does not exist."
		return 1
	fi

	# Check destination folder
	if [ ! -d "$dest_dir" ]; then
		echo "Destination directory $dest_dir does not exist. Creating it..."
		mkdir -p "$dest_dir" || { echo "Failed to create destination directory $dest_dir"; return 1; }
	fi

	# Copy folder from source to destination
	echo "Copying firmware from $source_dir to $dest_dir..."
	cp -r "$source_dir"* "$dest_dir" || { echo "Failed to copy firmware to $dest_dir."; return 1; }
	echo "Firmware copied successfully to $dest_dir."

	# Create symlinks for NXP WiFi driver
	nxp_dir="$dest_dir/nxp"
	if [ -d "$nxp_dir/murata/files/1XK" ]; then
		echo "Creating NXP WiFi firmware symlinks..."
		ln -sf murata/files/1XK/txpower_EU.bin "$nxp_dir/txpower_EU.bin"
		ln -sf murata/files/1XK/ed_mac.bin "$nxp_dir/ed_mac.bin"
		echo "NXP WiFi firmware symlinks created."
	fi

	return 0
}

#######################################
# Copy modprobe conf from renesas-ubuntu (yocto output) to rootfs
# Globals:
#   WORK_DIR
# Arguments:
#   $1: src rootfs
#   $2: dest rootfs
#######################################
copy_modprobe_conf() {
	source_dir="./$1/etc/modprobe.d/"
	dest_dir="./$2/etc/modprobe.d"

	# Change dir WORK_DIR
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Check source folder
	if [ ! -d "$source_dir" ]; then
		echo "Source directory $source_dir does not exist."
		return 1
	fi

	# Check destination folder
	if [ ! -d "$dest_dir" ]; then
		echo "Destination directory $dest_dir does not exist. Creating it..."
		mkdir -p "$dest_dir" || { echo "Failed to create destination directory $dest_dir"; return 1; }
	fi

	# Merge folder from source to destination (preserves existing files, adds new ones)
	echo "Merging modprobe conf from $source_dir to $dest_dir..."
	rsync -av "$source_dir" "$dest_dir" --backup-dir="$dest_dir/.backup" || { echo "Failed to merge modprobe conf to $dest_dir."; return 1; }
	echo "modprobe conf merged successfully to $dest_dir."

	return 0
}

#######################################
#######################################
# Copy systemd-networkd config files
# Globals:
#   WORK_DIR
# Arguments:
#   $1: src rootfs
#   $2: dest rootfs
#######################################
copy_network_interface_conf() {
	local SRC_ROOT="$1"
	local DST_ROOT="$2"

	local source_dir="${WORK_DIR}/${SRC_ROOT}/usr/lib/systemd/network"
	local dest_dir="${WORK_DIR}/${DST_ROOT}/usr/lib/systemd/network"

	local list_files="19-end0.network.disabled 19-end1.network.disabled 19-wired.network 21-ap.network.disabled 25-wlan.network"

	echo "Copying systemd-networkd configs..."
	echo "SRC: $source_dir"
	echo "DST: $dest_dir"

	[[ -d "$source_dir" ]] || { echo "ERROR: Source directory does not exist: $source_dir"; return 1; }
	mkdir -p "$dest_dir" || { echo "ERROR: Failed to create $dest_dir"; return 1; }

	local f
	for f in $list_files; do
		if [[ -f "$source_dir/$f" ]]; then
			echo "Copying $f"
			cp -a "$source_dir/$f" "$dest_dir/" || return 1
		else
			echo "WARNING: Missing $source_dir/$f"
		fi
	done

	echo "Network config copy done."
}

#######################################
# Copy systemd modules-load.d config files
# Globals:
#   WORK_DIR
# Arguments:
#   $1: src rootfs
#   $2: dest rootfs
#######################################
copy_modules_load_d() {
	local SRC_ROOT="$1"
	local DST_ROOT="$2"

	local source_dir="${WORK_DIR}/${SRC_ROOT}/usr/lib/modules-load.d"
	local dest_dir="${WORK_DIR}/${DST_ROOT}/usr/lib/modules-load.d"

	echo "Copying modules-load.d..."
	echo "SRC: $source_dir"
	echo "DST: $dest_dir"

	if [[ ! -d "$source_dir" ]]; then
		echo "ERROR: Source directory does not exist: $source_dir"
		return 1
	fi

	mkdir -p "$dest_dir" || return 1

 	# Copy everything inside (including subdirs if any)
	cp -a "$source_dir/." "$dest_dir/" || return 1

	echo "modules-load.d copy done."
	return 0
}
