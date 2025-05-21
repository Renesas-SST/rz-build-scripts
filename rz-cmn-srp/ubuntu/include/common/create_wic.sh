#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# The function creates a WIC (Windows Image) file from the Ubuntu root filesystem (rootfs)
# --------------------------------------------------------------------------#

# --------------------------------------------------------------------------#
# function create_wic contain 5 steps:
# Step 1: Create blank *.wic
# Step 2: Create 2 partition using fdisk
# Step 3: Format partition
# Step 4: Mount and copy data
# Step 5: Clean up
# Step 6: Create file tar.gz from .wic file
# --------------------------------------------------------------------------#

create_wic() {
	sudo apt-get update
	sudo apt-get install -y parted multipath-tools kpartx dosfstools e2fsprogs

	ROOTFS_DIR="./rootfs"
	# Set output wic file name to ubuntu-image-qt-rzpi.wic by default if not defined
	OUTPUT_WIC="${OUTPUT_WIC:=ubuntu-image-qt-rzpi.wic}"

	# Set boot size to 200MB by default if not defined
	BOOT_SIZE_MB=${BOOT_SIZE_MB:-200}

	# Set rootfs size to 5000MB by default if not defined
	ROOTFS_SPACE=${ROOTFS_SPACE:-5000}
	ROOTFS_SIZE_MB=$(du -s -B 1048576 "$ROOTFS_DIR" 2>/dev/null |awk '{print $1}')

	# Calculate total size for WIC, add space
	TOTAL_SIZE_MB=$((BOOT_SIZE_MB + ROOTFS_SIZE_MB + ROOTFS_SPACE))

	# Step 1: Create blank *.wic
	echo "Creating blank WIC file : ${TOTAL_SIZE_MB}MB..."
	dd if=/dev/zero of="$OUTPUT_WIC" bs=1M count="$TOTAL_SIZE_MB" status=progress
	if [ $? -eq 1 ]; then
		echo "Create WIC failed."
		return 1
	fi
	# Step 2: Create 2 partition using fdisk
	echo "Create 2 partition in $OUTPUT_WIC..."
	LOOP_DEVICE=$(sudo losetup -f --show "$OUTPUT_WIC")

	sudo parted "$LOOP_DEVICE" mklabel msdos
	sudo parted "$LOOP_DEVICE" mkpart primary fat32 1MiB "$((BOOT_SIZE_MB + 1))MiB"
	sudo parted "$LOOP_DEVICE" mkpart primary ext4 "$((BOOT_SIZE_MB + 1))MiB" "$((TOTAL_SIZE_MB - 1))MiB"

	# Reload partition
	# sudo partprobe "$LOOP_DEVICE"

	# Mount to loop device
	sudo losetup -d "$LOOP_DEVICE"
	LOOP_DEVICE=$(sudo losetup -f --show -P "$OUTPUT_WIC")
	sudo kpartx -av "$LOOP_DEVICE"
	LOOP_NAME=$(basename "$LOOP_DEVICE")

	BOOT_PART="/dev/mapper/${LOOP_NAME}p1"
	ROOTFS_PART="/dev/mapper/${LOOP_NAME}p2"

	# Step 3: Format partition
	echo "Format boot partition (FAT32)..."
	sudo mkfs.vfat "$BOOT_PART" -n boot

	echo "Format rootfs partition (EXT4)..."
	sudo mkfs.ext4 "$ROOTFS_PART" -L rootfs

	# Step 4: Mount and copy data
	MOUNT_DIR=$(mktemp -d)

	echo "Copy data to boot partition..."
	sudo mount "$BOOT_PART" "$MOUNT_DIR"
	sudo cp -r "$ROOTFS_DIR/boot/"* "$MOUNT_DIR"
	sudo mv "$MOUNT_DIR/Image"* "$MOUNT_DIR/Image"
	sudo mv "$MOUNT_DIR/rzpi"* "$MOUNT_DIR/rzpi.dtb"
	sync
	echo "Partition Boot has :"
	ls "$MOUNT_DIR"
	sudo umount "$MOUNT_DIR"

	echo "Copying rootfs..."
	sudo mount "$ROOTFS_PART" "$MOUNT_DIR"
	sudo cp -arf "$ROOTFS_DIR/"* "$MOUNT_DIR"
	sync
	echo "Partition Rootfs has :"
	ls "$MOUNT_DIR"
	sudo umount "$MOUNT_DIR"

	# Step 5: Clean up
	sync
	sudo kpartx -d "$LOOP_DEVICE"
	sudo losetup -d "$LOOP_DEVICE"
	rmdir "$MOUNT_DIR"

	# Step 6 : Create file tar.gz from .wic file
	sudo gzip "$OUTPUT_WIC" || { echo "Failed to compress .wic into .wic.gz"; return 1; }
	echo "File WIC has been created: $OUTPUT_WIC"
	return 0
}
