#!/bin/bash
# --------------------------------------------------------------------------------#
# Description:
# The main function orchestrates the entire process by calling a series of
# functions in sequence to prepare the Ubuntu base, configure the system,
# set up root and user passwords, and finally package the system into a WIC image.
# --------------------------------------------------------------------------------#

# Get the absolute path to the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PARENT_DIR=`realpath ..`

# Load config and environment scripts
. ${SCRIPT_DIR}/config.ini

source_env(){
	if [ "$UBUNTU_TYPE" = "CORE" ]; then
		. ${SCRIPT_DIR}/include/ubuntu_core/prepare_env.sh
		. ${SCRIPT_DIR}/include/ubuntu_core/prepare_rootfs_qt.sh
		. ${SCRIPT_DIR}/include/ubuntu_core/prepare_conf.sh
		. ${SCRIPT_DIR}/include/ubuntu_core/setup_dns.sh
	elif [ "$UBUNTU_TYPE" = "LXDE" ]; then
		. ${SCRIPT_DIR}/include/ubuntu_lxde/prepare_rootfs_qt.sh
		. ${SCRIPT_DIR}/include/ubuntu_lxde/prepare_conf.sh
		. ${SCRIPT_DIR}/include/ubuntu_lxde/create_swap.sh
	else
		echo "Invalid value passed for UBUNTU_TYPE . Set UBUNTU_TYPE to proper value (CORE / LXDE) in config.ini file."
		exit 1
	fi
}
. ${SCRIPT_DIR}/include/common/create_wic.sh
. ${SCRIPT_DIR}/include/common/mount.sh
. ${SCRIPT_DIR}/include/common/install_gstreamer.sh
. ${SCRIPT_DIR}/include/common/install_weston.sh
. ${SCRIPT_DIR}/include/common/yocto_working.sh
. ${SCRIPT_DIR}/include/common/prepare_ubuntu_base.sh
. ${SCRIPT_DIR}/include/common/allow_empty_password.sh
. ${SCRIPT_DIR}/include/common/prepare_env_rootfs.sh

#---------------------------Log helper functions--------------------------------
log_warning(){
        string=$1
        echo -e "\033[33;1;4m${string}\033[0m"
}

log_error(){
        string=$1
        echo -e "\033[31;1;4m${string}\033[0m"
}

log_info(){
        string=$1
        echo -e "\033[32;1;4m${string}\033[0m"
}

# Function to clean old build artifacts
cleanup_ubuntu_artifacts() {
    log_info "Cleaning up old Ubuntu rootfs artifacts..."
    rm -rf rootfs
}

# Main function for ubuntu core
main_ubuntu_core(){
	# Prepare the environment by checking for required files and directories
	prepare_env
	if [ $? -eq 1 ]; then
		echo "prepare_env failed."
		exit 1
	fi

	# Prepare the Ubuntu base system (install necessary binaries and setup rootfs)
	ubuntu_base_prepare
	if [ $? -eq 1 ]; then
		echo "ubuntu_base_prepare failed."
		exit 1
	fi

	# Prepare qt_rootfs_source by copying relevant binaries and folders to the Ubuntu OS
	rootfs_qt
	if [ $? -eq 1 ]; then
		echo "rootfs_qt failed."
		exit 1
	fi


	# Set configuration files
	set_config
	if [ $? -eq 1 ]; then
		echo "set_config failed."
		exit 1
	fi

	# Prepare env file for rootfs
	prepare_env_rootfs "${SCRIPT_DIR}/config.ini"

	# Run script to fix dpkg install lock if any
	chroot_run_1_script ${UBUNTU_COMMON_SCRIPT_PATH} "dpkg-install-lock-fix.sh"

	# Run the script 'apt_install_base.sh' inside chroot environment
	chroot_run_1_script ${UBUNTU_CORE_SCRIPT_PATH} "apt_install_base.sh"
	if [ $? -eq 1 ]; then
		echo "set_config failed."
		exit 1
	fi

	# Run the script 'set_root_password.sh' inside chroot environment
	chroot_run_1_script ${UBUNTU_CORE_SCRIPT_PATH} "set_root_password.sh"
	if [ $? -eq 1 ]; then
		echo "set_root_password failed."
		exit 1
	fi

	# Run the script 'link_to_leagcy_iptables.sh' inside chroot environment
	chroot_run_1_script ${UBUNTU_CORE_SCRIPT_PATH} "link_to_leagcy_iptables.sh"
	if [ $? -eq 1 ]; then
		echo "link_to_leagcy_iptables failed."
		exit 1
	fi

	# Set up configuration after install packages
	set_config_after_install
	if [ $? -eq 1 ]; then
		echo "set_config_after_install failed."
		exit 1
	fi

	# Allow user ssh without password
	allow_empty_password_ssh
	if [ $? -eq 1 ]; then
		echo "allow_empty_password_ssh failed."
		exit 1
	fi

	# Install gstreamer to ubuntu
	install_gstreamer "rootfs" "qt_rootfs_source"
	if [ $? -eq 1 ]; then
		echo "install_gstreamer failed."
		exit 1
	fi

	# Install weston to ubuntu
	install_weston "rootfs" "qt_rootfs_source"
	if [ $? -eq 1 ]; then
		echo "install_weston failed."
		exit 1
	fi

	chroot_run_1_script ${UBUNTU_COMMON_SCRIPT_PATH} "setup_dns_and_time.sh"
	if [ $? -eq 1 ]; then
		echo "setup dns and time failed."
		exit 1
	fi

	# Package the root filesystem into a compressed archive (tarball)
	package_rootfs
	if [ $? -eq 1 ]; then
		echo "package_rootfs failed."
		exit 1
	fi

	# Create a WIC image from the rootfs
	create_wic
	if [ $? -eq 1 ]; then
		echo "create_wic failed."
		exit 1
	fi

	# Move WIC output to output yocto folder
	move_ubuntu_to_yocto_output
	if [ $? -eq 1 ]; then
		echo "move_ubuntu_to_yocto_output failed."
		exit 1
	fi
}

#######################################
# Function main use to run all script to build ubuntu os with lxde-desktop.
# It will be config ubuntu OS, install applications define in script.
# It package rootfs to tar file after run all script.
#
# Globals:
#   ROOTFS
# Arguments:
#   None
#######################################
main_ubuntu_lxde(){
	# Prepare the environment by checking for required files and directories
	prepare_env
	if [ $? -eq 1 ]; then
		echo "prepare_env failed."
		exit 1
	fi

	# Install qemu-user-static
	install_qemu
	if [ $? -eq 1 ]; then
		echo "install_qemu failed."
		exit 1
	fi
	echo "install_qemu completed successfully."

	# Prepare ubuntu base
	ubuntu_base_prepare
	if [ $? -eq 1 ]; then
		echo "ubuntu_base_prepare failed."
		exit 1
	fi

	# Prepare rootfs qt
	rootfs_qt
	if [ $? -eq 1 ]; then
		echo "rootfs_qt failed."
		exit 1
	fi

	# Set config
	set_config
	if [ $? -eq 1 ]; then
		echo "set_config failed."
		exit 1
	fi

	# Prepare env file for rootfs
	prepare_env_rootfs "${SCRIPT_DIR}/config.ini"

	# Run script to fix dpkg install lock if any
	chroot_run_1_script ${UBUNTU_COMMON_SCRIPT_PATH} "dpkg-install-lock-fix.sh"

	# Mount chroot to install basic package
	chroot_run_1_script ${UBUNTU_LXDE_SCRIPT_PATH} "apt_install_base.sh"
	if [ $? -eq 1 ]; then
		echo "apt_install_base failed."
		exit 1
	fi

	# Create user - normal user
	chroot_run_1_script ${UBUNTU_LXDE_SCRIPT_PATH} "create_user.sh"
	if [ $? -eq 1 ]; then
		echo "create_user failed."
		exit 1
	fi

	# Set root password
	chroot_run_1_script ${UBUNTU_LXDE_SCRIPT_PATH} "set_root_password.sh"
	if [ $? -eq 1 ]; then
		echo "set_root_password failed."
		exit 1
	fi

	# Allow user ssh without password
	allow_empty_password_ssh
	if [ $? -eq 1 ]; then
		echo "allow_empty_password_ssh failed."
		exit 1
	fi

	# Install wifi and bluetooth packages
	chroot_run_1_script ${UBUNTU_LXDE_SCRIPT_PATH} "apt_wifi_ble.sh"
	if [ $? -eq 1 ]; then
		echo "apt_wifi_ble failed."
		exit 1
	fi

	# Install lxde desktop
	chroot_run_1_script ${UBUNTU_LXDE_SCRIPT_PATH} "apt_lxde_desktop.sh"
	if [ $? -eq 1 ]; then
		echo "apt_lxde_desktop failed."
		exit 1
	fi

	# Install blueman for bluetooth (on 20.04 and above)
	# Get the ubuntu version
	version=$(echo "$UBUNTU_BASE_FILE_NAME" | grep -oP '\d+\.\d+')
	major_version=$(echo "$version" | cut -d '.' -f 1)

	if [ "$major_version" -ge 20 ]; then
		chroot_run_1_script ${UBUNTU_LXDE_SCRIPT_PATH} "apt_blueman.sh"
	fi
	if [ $? -eq 1 ]; then
		echo "apt_blueman failed."
		exit 1
	fi

	# Install audio and video packages
	chroot_run_1_script ${UBUNTU_LXDE_SCRIPT_PATH} "apt_audio_video.sh"
	if [ $? -eq 1 ]; then
		echo "apt_audio_video failed."
		exit 1
	fi

	chroot_run_1_script ${UBUNTU_COMMON_SCRIPT_PATH} "setup_dns_and_time.sh"
	if [ $? -eq 1 ]; then
                echo "setup dns and time failed."
                exit 1
        fi

	# Set up configuration after install packages
	set_config_after_install
	if [ $? -eq 1 ]; then
		echo "set_config_after_install failed."
		exit 1
	fi

	# Package rootfs to tar file
	package_rootfs
	if [ $? -eq 1 ]; then
		echo "package_rootfs failed."
		exit 1
	fi

	# Create a WIC image from the rootfs
	create_wic
	if [ $? -eq 1 ]; then
		echo "create_wic failed."
		exit 1
	fi

	# Move WIC output to output yocto folder
	move_ubuntu_to_yocto_output
	if [ $? -eq 1 ]; then
		echo "move_ubuntu_to_yocto_output failed."
		exit 1
	fi
}

# Ensure the Yocto artifacts exist at the specified path
# Usage: check_yocto_artifacts <yocto_artifacts_dir>
check_yocto_artifacts() {
	local artifacts_dir="$1"
	local artifacts_path="${artifacts_dir}/${renesas_ubuntu_input_name}"

	# Check if artifacts dir is exist
	if [ ! -d "${artifacts_dir}" ]; then
		log_error "Yocto build directory not found: ${artifacts_dir}"
		log_error "Please ensure the Yocto build directory exists."
		guideline
		exit 1
	fi

	# Check if artifacts path is exist
	if [ ! -f "${artifacts_path}" ]; then
		log_error "Yocto artifact not found: ${artifacts_path}"
		log_error "Please ensure the build completed and the file exists."
		guideline
		exit 1
	fi

	log_info "Found Yocto artifact: ${artifacts_path}"
	cp "${artifacts_path}" "${renesas_ubuntu_input_name}"
}

# Run ubuntu build based on the first argument
run_ubuntu_build() {
	local ubuntu_type=$1

	case "$ubuntu_type" in
		ubuntu-core)
			UBUNTU_TYPE="CORE"
			OUTPUT_ROOTFS="ubuntu-core-image-rzg2l-sbc"
			OUTPUT_WIC="ubuntu-core-image-rzg2l-sbc.wic"
			cleanup_ubuntu_artifacts

			source_env
			main_ubuntu_core
			;;
		ubuntu-lxde)
			UBUNTU_TYPE="LXDE"
			OUTPUT_ROOTFS="ubuntu-lxde-image-rzg2l-sbc"
			OUTPUT_WIC="ubuntu-lxde-image-rzg2l-sbc.wic"
			cleanup_ubuntu_artifacts

			source_env
			main_ubuntu_lxde
			;;
		all-ubuntu-images)
			UBUNTU_TYPE="CORE"
			OUTPUT_ROOTFS="ubuntu-core-image-rzg2l-sbc"
			OUTPUT_WIC="ubuntu-core-image-rzg2l-sbc.wic"
			cleanup_ubuntu_artifacts

			source_env
			main_ubuntu_core

			# Clean old build artifacts before next build
			cleanup_ubuntu_artifacts

			UBUNTU_TYPE="LXDE"
			OUTPUT_ROOTFS="ubuntu-lxde-image-rzg2l-sbc"
			OUTPUT_WIC="ubuntu-lxde-image-rzg2l-sbc.wic"
			source_env
			main_ubuntu_lxde
			;;
		*)
			echo "Unknown UBUNTU_TYPE: $ubuntu_type. Please set it to CORE, LXDE, or ALL."
			return 1
			;;
	esac
}
