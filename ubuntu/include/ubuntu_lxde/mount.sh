#!/bin/bash
##############################################################################
# This script use to run script in ubuntu os after mount chroot.
# It will be config ubuntu OS, install applications define in script.
# It package rootfs to tar file after run all script.
##############################################################################

#######################################
# Function mount_chroot use to mount the ubuntu filesystem.
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
mount_chroot() {
	echo "Mounting chroot environment..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Mount folder
	sudo mount -t proc /proc ./rootfs/proc || { echo "Failed to mount /proc"; return 1; }
	sudo mount -t sysfs /sys ./rootfs/sys || { echo "Failed to mount /sys"; return 1; }
	sudo mount -o bind /dev ./rootfs/dev || { echo "Failed to bind mount /dev"; return 1; }
	sudo mount -o bind /dev/pts ./rootfs/dev/pts || { echo "Failed to bind mount /dev/pts"; return 1; }

	echo "Mount chroot completed successfully."

	return 0
}

#######################################
# Function umount_chroot use to umount the ubuntu filesystem.
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
umount_chroot() {
	echo "Unmounting chroot environment..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Unmount and check error
	sudo umount ./rootfs/proc || { echo "Failed to unmount /rootfs/proc"; return 1; }
	sudo umount ./rootfs/sys || { echo "Failed to unmount /rootfs/sys"; return 1; }
	sudo umount ./rootfs/dev/pts || { echo "Failed to unmount /rootfs/dev/pts"; return 1; }
	sudo umount ./rootfs/dev || { echo "Failed to unmount /rootfs/dev"; return 1; }

	# Sync after unmount
	sync
	echo "umount_chroot completed successfully."
	return 0
}

#######################################
# Function copy_script use to copy script to rootfs.
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
copy_script() {
	# Define local variables
	input_folder="./script/ubuntu_lxde"
	destination="./rootfs/script/ubuntu_lxde"

	# Check input script
	if [ ! -e $input_folder/"$1" ]; then
		echo "File $input_folder/$1 not found"
		return 1
	fi

	# Change permission
	chmod a+x $input_folder/"$1"

	# Create target folder
	if [ ! -d "$destination" ]; then
		echo "Directory $destination does not exist. Creating it..."
		mkdir -p "$destination"
		if [ $? -ne 0 ]; then
			echo "Failed to create directory $destination."
			return 1
		fi
	else
		echo "Directory $destination already exists. Skipping creation."
	fi

	# Copy script to target folder
	cp "$input_folder/$1" "$destination" || { echo "Failed to copy $input_folder/$1"; return 1; }
	return 0

}

#######################################
# Function chroot_run_1_script use to run 1 file script in chroot-mode.
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
chroot_run_1_script() {
	# Copy script to rootfs
	copy_script "$1"
	if [ $? -eq 1 ]; then
		echo "copy_script $1 failed."
		exit 1
	fi

	# Mount chroot
	mount_chroot
	script_dir="/script/ubuntu_lxde"

	# Create command file script
	script_commands="$script_dir/$1; "

	# Chroot and excute script
	sudo chroot ./rootfs /bin/bash -c "
		chmod 777 /tmp
		chmod 777 $script_dir/$1
		cd /
		$script_commands
	" || { echo "Failed to execute scripts in chroot"; umount_chroot; return 1; }

	# Unmount chroot
	umount_chroot

	return 0
}

#######################################
# Function package_rootfs use to package rootfs to tar file.
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
package_rootfs() {
	echo "Packaging rootfs..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Check folder rootfs exist
	if [ ! -d "rootfs" ]; then
		echo "Directory rootfs not found"
		return 1
	fi

	# Check and remove old rootfs file if exist
	if [ -e "${OUTPUT_ROOTFS}.tar.bz2" ]; then
		rm "${OUTPUT_ROOTFS}.tar.bz2"
	fi

	# Create file tar.bz2 from folder rootfs and check error
	sudo tar -cjf "${OUTPUT_ROOTFS}.tar.bz2" -C rootfs/ . || { echo "Failed to package rootfs into rootfs.tar.bz2"; return 1; }

	echo "package_rootfs completed successfully."
	return 0
}
