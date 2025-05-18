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
