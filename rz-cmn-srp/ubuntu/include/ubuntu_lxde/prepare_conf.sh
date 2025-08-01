#!/bin/bash
##############################################################################
# This script sets up the Ubuntu OS configuration by performing the following:
# 1. Copy qemu-aarch64-static
# 2. Copy resolv.conf
# 3. Set up log file for syslog
# 4. Set LightDM configuration
# 5. Configure network interfaces
# 6. Configure network manager
# 7. Configure camera ov5640
##############################################################################

# Define global variables
WORK_DIR=$(pwd)
ROOTFS="./rootfs"
BIN_PATH="$ROOTFS/usr/bin"
ETC_PATH="$ROOTFS/etc"

#######################################
# Function copy_qemu use to copy qemu-aarch64-static to ubuntu os.
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
copy_qemu() {
	echo "Copying qemu-aarch64-static..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Check BIN_PATH
	if [ -z "$BIN_PATH" ]; then
		echo "BIN_PATH is not set."
		return 1
	fi

	# Create folder BIN_PATH
	mkdir -p "$BIN_PATH" || { echo "Failed to create $BIN_PATH"; return 1; }

	# Copy qemu-aarch64-static
	cp /usr/bin/qemu-aarch64-static "$BIN_PATH/" || { echo "Failed to copy qemu-aarch64-static"; return 1; }
	echo "Copied qemu-aarch64-static successfully."
	return 0
}


#######################################
# Function copy_resolv_conf use to copy resolv.conf to ubuntu os.
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
copy_resolv_conf() {
	echo "Copying resolv.conf..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Check ETC_PATH
	if [ -z "$ETC_PATH" ]; then
		echo "ETC_PATH is not set."
		return 1
	fi

	# Create folder ETC_PATH
	mkdir -p "$ETC_PATH" || { echo "Failed to create $ETC_PATH"; return 1; }

	# Copy resolv.conf
	cp /etc/resolv.conf "$ETC_PATH/resolv.conf" || { echo "Failed to copy resolv.conf"; return 1; }
	echo "Copied resolv.conf successfully."
	return 0
}

#######################################
# Function copy_file_conf use to copy conf target dir in ubuntu os.
# Globals:
#   WORK_DIR
# Arguments:
#    - file name in folder config
#    - target folder in ubuntu os
#    - permission of file
#######################################
copy_file_conf() {
	file_name="$1"
	target_folder="$2"
	file_permission="$3"

	# Check if file exists in the config folder
	if [ ! -f "${SCRIPT_DIR}/config/ubuntu_lxde/${file_name}" ]; then
		echo "File ${file_name} does not exist in the config folder."
		return 1
	fi

	# Check if target folder exists
	if [ ! -d "${target_folder}" ]; then
		echo "Target folder ${target_folder} does not exist. Creating it..."
		mkdir -p "${target_folder}"
		if [ $? -ne 0 ]; then
			echo "Failed to create target folder ${target_folder}."
			return 1
		fi
	fi

	# Copy the file to the target folder
	cp "${SCRIPT_DIR}/config/ubuntu_lxde/${file_name}" "${target_folder}"
	if [ $? -ne 0 ]; then
		echo "Failed to copy file ${file_name} to ${target_folder}."
		return 1
	fi

	# Set the permissions of the copied file
	chmod "${file_permission}" "${target_folder}/${file_name}"
	if [ $? -ne 0 ]; then
		echo "Failed to set permissions for file ${target_folder}/${file_name}."
		return 1
	fi

	echo "File ${file_name} successfully copied to ${target_folder} with permissions ${file_permission}."
	return 0
}

#######################################
# Copy qt lib from renesas-ubuntu (yocto output) to rootfs
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
copy_qt() {
	echo "Copying qt files..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	local src_qt="rootfs_qt/usr"
	local target_dir="rootfs/usr"

	# Copy folder boot
	cp -rd "$src_qt/share/qt"* "$target_dir/share" || { echo "Failed to copy 'qt lib' directory"; return 1; }
	cp -rd "$src_qt/libexec/qt"* "$target_dir/libexec" || { echo "Failed to copy 'qt libexec' directory"; return 1; }
	cp -rd "$src_qt/lib/libQt"* "$target_dir/lib/aarch64-linux-gnu/" || { echo "Failed to copy 'aarch64-linux-gnu' directory"; return 1; }
	mkdir -p "$target_dir/lib/aarch64-linux-gnu/pkgconfig/" || { echo "Failed to mkdir 'lib/aarch64-linux-gnu/pkgconfig' directory"; return 1; }
	cp -rd "$src_qt/lib/pkgconfig/Qt"* "$target_dir/lib/aarch64-linux-gnu/pkgconfig/" || { echo "Failed to copy 'pkgconfig' directory"; return 1; }
	cp -rd "$src_qt/lib/libicui18n.so.75" "$src_qt/lib/libicuuc.so.75" "$src_qt/lib/libicudata.so.75" "$src_qt/lib/libxcb"* "$target_dir/lib/aarch64-linux-gnu/" || { echo "Failed to copy to directory"; return 1; }
	mkdir -p "$target_dir/lib/plugins" || { echo "Failed to mkdir 'lib/plugins' directory"; return 1; }
	cp -rd "$src_qt/lib/plugins/qt"* "$target_dir/lib/plugins/"

	echo "copy completed successfully."
	return 0
}

#######################################
# Function check_and_remove_file use to check and remove file in ubuntu os.
# Globals:
#   WORK_DIR
# Arguments:
#    - file name in folder config
#    - target folder in ubuntu os
#######################################
check_and_remove_file() {
	file_path="$1"

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Check if the file exists in the target folder
	if [ -f "${file_path}" ]; then
		echo "File ${file_path} exists. Removing it..."
		rm "${file_path}"
		if [ $? -ne 0 ]; then
			echo "Failed to remove file ${file_path}."
			return 1
		fi
		echo "File ${file_path} removed successfully."
	else
		echo "File ${file_path} does not exist. Skipping removal."
	fi

	return 0
}

#######################################
# Function set_config use to copy config file to ubuntu os.
# 1. Copy qemu-aarch64-static
# 2. Copy resolv.conf
# 3. Set up log file for syslog
# 4. Set LightDM configuration
# 5. Configure network interfaces
# 6. Configure network manager
# 7. Configure camera ov5640
#######################################
set_config() {
	echo "Setting configuration..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Copy qemu-aarch64-static
	copy_qemu
	if [ $? -eq 1 ]; then
		echo "Failed to copy qemu-aarch64-static. Exiting."
		return 1
	fi

	# Copy resolv.conf
	copy_resolv_conf
	if [ $? -eq 1 ]; then
		echo "Failed to copy resolv.conf. Exiting."
		return 1
	fi

	# Set up rsyslog file
	copy_file_conf "rsyslog" "rootfs/var/log" "666"
	if [ $? -eq 1 ]; then
		echo "Failed to set up log file. Exiting."
		return 1
	fi

	# Set LightDM configuration
	copy_file_conf "lightdm.conf" "rootfs/etc/lightdm" "644"
	if [ $? -eq 1 ]; then
		echo "Failed to configure LightDM. Exiting."
		return 1
	fi

	# Configure network interfaces
	copy_file_conf "interfaces" "rootfs/etc/network" "644"
	if [ $? -eq 1 ]; then
		echo "Failed to configure network interfaces. Exiting."
		return 1
	fi

	# Configure network manager
	copy_file_conf "NetworkManager.conf" "rootfs/etc/NetworkManager" "644"
	if [ $? -eq 1 ]; then
		echo "Failed to configure network manager. Exiting."
		return 1
	fi

	# Configure camera ov5640
	copy_file_conf "v4l2-init.sh" "rootfs/etc/profile.d" "755"
	if [ $? -eq 1 ]; then
		echo "Failed to configure camera ov5640. Exiting."
		return 1
	fi

	# Configure audio
	copy_file_conf "audio-init.sh" "rootfs/etc/profile.d" "755"
	if [ $? -eq 1 ]; then
	        echo "Failed to configure audio-init. Exiting."
	        return 1
	fi

	# Configure connman-gtk to appear at System Tray
	copy_file_conf "connman-gtk.desktop" "rootfs/etc/xdg/autostart" "755"
	if [ $? -eq 1 ]; then
		echo "Failed to configure connman-gtk. Exiting."
		return 1
	fi

	echo "Configuration completed successfully."
	return 0
}

#######################################
# Some configs need to be set after install
#######################################
set_config_after_install() {
	echo "Setting configuration after install..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Configure lxpanel LXDE
	copy_file_conf "panel" "${ROOTFS}/etc/xdg/lxpanel/LXDE/panels" "644"
	if [ $? -eq 1 ]; then
		echo "Failed to configure lxpanel LXDE setting. Exiting."
		return 1
	fi

	# Configure lxpanel default
	copy_file_conf "panel" "${ROOTFS}/etc/xdg/lxpanel/default/panels" "644"
	if [ $? -eq 1 ]; then
		echo "Failed to configure lxpanel default setting. Exiting."
		return 1
	fi

	# Configure force xorg display service
	copy_file_conf "force-display-xorg.sh" "${ROOTFS}/usr/local/bin/" "755"
	if [ $? -eq 1 ]; then
		echo "Failed to copy force-display-xorg.sh to /usr/local/bin. Exiting."
		return 1
	fi
	copy_file_conf "force-xorg-display.service" "${ROOTFS}/etc/systemd/system/" "755"
	if [ $? -eq 1 ]; then
		echo "Failed to configure force-xorg-display.service. Exiting."
		return 1
	fi

	# Remove blueman-aplet icon
	check_and_remove_file "${ROOTFS}/etc/xdg/autostart/blueman.desktop"
	if [ $? -eq 1 ]; then
		echo "Failed to Remove blueman-aplet icon. Exiting."
		return 1
	fi

	echo "Starting copy_qt..."
	# Call copy_qt to copy qt files for the system
	copy_qt
	if [[ $? -eq 1 ]]; then
		echo "copy_qt failed."
		return 1
	fi
	echo "copy_qt completed successfully."

	echo "Configuration completed successfully."
	return 0
}
