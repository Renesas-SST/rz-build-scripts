#!/bin/bash
# Version: Default
# -----------------------------Yocto package------------------------------------
# Make sure that the following packages have been downloaded from the official website
# RZ/G Verified Linux Package [5.10-CIP] V3.0.5 update1
REN_LINUX_BSP_PKG="RTK0EF0045Z0021AZJ-v3.0.5-update1"
REN_LINUX_BSP_META="rzg_vlp_v3.0.5"

# RZ MPU Graphics Library Evaluation Version V1.1.2
REN_GPU_MALI_LIB_PKG="RTK0EF0045Z13001ZJ-v1.1.2_EN"
REN_GPU_MALI_LIB_META_FEATURE="meta-rz-features_graphics_v1.1.2"

# RZ MPU Codec Library Evaluation Version V1.1.0
REN_VEDIO_CODEC_LIB_PKG="RTK0EF0045Z15001ZJ-v1.1.0_EN"
REN_VEDIO_CODEC_LIB_META_FEATURE="meta-rz-features_codec_v1.1.0"

SUFFIX_ZIP=".zip"
SUFFIX_TAR=".tar.gz"

LSB_ID_OK="Ubuntu"
LSB_REL_OK="20.04"

TOP_DIR=`pwd`
JQ="$TOP_DIR/jq-linux-amd64"
PATCH_FILE="$TOP_DIR/git_patch.json"

# Target image for the build
# List of supported images:
#  - core-image-minimal
#  - core-image-bsp
#  - core-image-weston
#  - core-image-qt
#  - renesas-core-image-cli
#  - renesas-core-image-weston
#  - renesas-quickboot-cli
#  - renesas-quickboot-wayland

# Special case:
#  - all-supported-images (build all images listed above)

# Default is core-image-qt
: ${IMAGE:=core-image-qt}

# List of all supported images
supported_images=("core-image-minimal" "core-image-bsp" "core-image-weston" "core-image-qt" \
					"renesas-core-image-cli" "renesas-core-image-weston" "renesas-quickboot-cli" \
					"renesas-quickboot-wayland")
# ------------------------------------------------------------------------------

# -----------------------------Global variable------------------------------------
# ------------------------------------------------------------------------------

# Guidance
# Currently, this script supports for RZ SBC board
guideline() {
	echo "------------------------------------------------------------"
	echo "Syntax Error!!!"
	echo "How to use script:"
	echo "Syntax:"
	echo ""
	echo "========="
	echo "Build yocto"
	echo "$ IMAGE=<target_image> ./rzsbc_yocto.sh <target_build> <target_dir>"
	echo "--------------------------"
	echo " - <target_image>: the target Yocto build image. It can be one from the following list of supported images"
	echo "     1. core-image-minimal"
	echo "     2. core-image-bsp"
	echo "     3. core-image-weston"
	echo "     4. core-image-qt"
	echo "     5. renesas-core-image-cli"
	echo "     6. renesas-core-image-weston"
	echo "     7. renesas-quickboot-cli"
	echo "     8. renesas-quickboot-wayland"
	echo "     9. all-supported-images"
	echo "Note: If IMAGE is not set, the default image is core-image-qt."
	echo "      Special case: If IMAGE is set to 'all-supported-images', all the images listed above will be built."
	echo " - <target_build>: the build options. It can be an image build (1) or a SDK build (2) as follows"
	echo "     1. build"
	echo "     2. build-sdk"
	echo " - <target_dir>: the build directory"
	echo "     If not set <target_dir>: current directory will be selected"
	echo ""
	echo "For example: "
	echo "$ IMAGE=renesas-core-image-cli ./rzsbc_yocto.sh build ~/yocto-build"
	echo "------------------------------------------------------------"
}

clean_repository() {
	if [ -d ".git" ]; then
		echo "Cleaning the working directory..."
		git checkout .
		git clean -fdx
	fi
}

apply_patches() {
	local key="$1"

	echo "Applying patches for $key"

	# Get the list of patches from the JSON file
	local patch_list
	patch_list=$("${JQ}" -r --arg key "$key" '.[$key].patches[]?' "$PATCH_FILE")
	if [ $? -ne 0 ]; then
		echo "Error: Failed to parse JSON file."
		exit 1
	fi

	# Check if the patch list is empty or null
	if [ -z "$patch_list" ]; then
		echo "No patches to apply for $key"
		return 0
	fi

	echo "Patch list: $patch_list"

	# Apply each patch
	echo "$patch_list" | while IFS= read -r local_patch; do
	local_patch=$(echo "$local_patch" | xargs)
	if [ -f "$TOP_DIR/$local_patch" ]; then
		echo "Applying local patch: $TOP_DIR/$local_patch"
		if [ ! -d ".git" ]; then
			patch -p1 < "$TOP_DIR/$local_patch"
		else
			git apply "$TOP_DIR/$local_patch"
		fi
		if [ $? -ne 0 ]; then
			echo "Error: Failed to apply patch $TOP_DIR/$local_patch."
			exit 1
		fi
	fi
	done
}

check_and_set_dir() {
	if [ -n "$1" ]; then
		TARGET_DIR=$1
		if [ ! -d "$TARGET_DIR" ]; then
			echo "TARGET_DIR ($TARGET_DIR) not present. One will be created."
		fi
	else
		TARGET_DIR=`pwd`
		echo "Current directory is $TARGET_DIR"
	fi
	export WORKSPACE=`pwd`
	export RZ_TARGET_DIR="${TARGET_DIR}/yocto_rzsbc_board"

}

log_warning(){
	string=$1
	echo "\e[33m$string\e[0m\n"
}

log_error(){
	string=$1
	echo "\e[31m$string \e[0m\n"
}

check_pkg_require(){
	# check required pacakages are downloaded from Renesas website and local package
	check=0

	echo "Checking linux version: "
	lsb_id=`lsb_release -i | cut -f2`
	lsb_rel=`lsb_release -r | cut -f2`

	if [ ${lsb_id} != ${LSB_ID_OK} ] || [ ${lsb_rel} != ${LSB_REL_OK} ]; then
		echo "Only known working OS is ${LSB_OK}. Kindly ensure this script is run on a supported OS or docker container"
		exit 0
	fi

	echo "Checking package dependencies..."
	#if [ ! -e ${REN_LINUX_BSP_PKG}${SUFFIX_ZIP} ];then
	#    log_error "Cannot find ${REN_LINUX_BSP_PKG}${SUFFIX_ZIP} !"
	#    echo "Please download 'RZ/G Verified Linux Package' from Renesas RZ/G2L Website (https://www.renesas.com/us/en/document/swo/rzg-verified-linux-package-v305-update1rtk0ef0045z0021azj-v305-update1zip?r=1597481)"
	#    check=1
	#fi
	if [ ! -e ${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP} ];then
		log_error "Cannot find ${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP} !"
		echo "Please download 'RZ MPU Graphics Library' from Renesas RZ/G2L Website (https://www.renesas.com/us/en/document/swo/rz-mpu-graphics-library-evaluation-version-rzg2l-and-rzg2lc-rtk0ef0045z13001zj-v112enzip)"
		check=2
	fi
	if [ ! -e ${REN_VEDIO_CODEC_LIB_PKG}${SUFFIX_ZIP} ];then
		log_error "Cannot found ${REN_VEDIO_CODEC_LIB_PKG}${SUFFIX_ZIP} !"
		echo "Please download 'RZ MPU Codec Library' from Renesas RZ/G2L Website (https://www.renesas.com/us/en/document/swo/rz-mpu-video-codec-library-evaluation-version-rzg2l-rtk0ef0045z15001zj-v110xxzip?r=1535641)"
		check=3
	fi

	[ ${check} -ne 0 ] && echo "Package check failed. Fix errors and copy dependencies here." && exit
}

check_patch_require() {
	echo "Checking patch dependencies..."

	# Extract repository names from the JSON file
	repositories=$("${JQ}" -r 'keys[]' "$PATCH_FILE")

	# Loop through each repository
	for repository_name in $repositories; do
		echo "Checking patches for repository: $repository_name"

		# Extract patch paths for the current repository
		patch_list=$("${JQ}" -r --arg repo "$repository_name" '.[$repo].patches[]?' "$PATCH_FILE")

		# Check if each patch file exists
		for patch_path in $patch_list; do
			if [ -n "$patch_path" ]; then
				echo "Checking patch: $patch_path"
				if [ ! -e "${WORKSPACE}/${patch_path}" ]; then
					echo "Error: Patch ${patch_path} is not present in this workspace (${WORKSPACE}/${patch_path})."
					echo "This patch is essential for the build. Please check!"
					exit 1
				fi
			fi
		done
	done

	echo "All required patches are present.\n"
}

# Verify if the bsp layer is correctly checkout
bsp_checkout_verification() {
	echo "Checking tag, commit, and branch for each BSP layer"

	cd "${RZ_TARGET_DIR}"
	bsp_layers=$("${JQ}" -r 'keys[]' "$PATCH_FILE")

	for bsp_layer in $bsp_layers; do
		cd "$bsp_layer"

		local expected_branch expected_commit expected_tags
		expected_branch=$("${JQ}" -r --arg repo "$bsp_layer" '.[$repo].branch // empty' "$PATCH_FILE")
		expected_commit=$("${JQ}" -r --arg repo "$bsp_layer" '.[$repo].commit // empty' "$PATCH_FILE")
		expected_tags=$("${JQ}" -r --arg repo "$bsp_layer" '.[$repo].tag // empty' "$PATCH_FILE")

		# Check if the directory is a Git repository
		if [ ! -d ".git" ]; then
			echo "$bsp_layer is not a Git repository, skipping check."
			cd ..
			continue
		fi

		# Verify the tags if specified
		if [ -n "$expected_tags" ]; then
			current_commit=$(git rev-parse HEAD)
			current_tags=$(git tag --points-at "$current_commit")

			tag_found=false
			for tag in $current_tags; do
				if [ "$tag" = "$expected_tags" ]; then
					echo "Tag $expected_tags is correctly checked out in $bsp_layer."
					tag_found=true
					break
				fi
			done

			if [ "$tag_found" = false ]; then
				echo "Tag mismatch in $bsp_layer. Expected $expected_tags but not found."
				echo "Checking out to $expected_tags"
				clean_repository
				git checkout "$expected_tags"

				# Need to apply the necessary patches
				apply_patches "$bsp_layer"
			fi

			cd ..
			continue
		fi

		# Verify the commit hash if specified
		if [ -n "$expected_commit" ]; then
			current_commit=$(git rev-parse HEAD)
			if [ "$current_commit" = "$expected_commit" ]; then
				echo "Commit $expected_commit is checked out correctly in $bsp_layer."
				cd ..
				continue
			else
				echo "Commit mismatch in $bsp_layer. Expected $expected_commit but found $current_commit."
				echo "Checking out to $expected_commit"
				clean_repository
				git checkout $expected_commit

				# Need to apply the neccessary patches
				apply_patches $bsp_layer
				cd ..
				continue
			fi
		fi

		# Verify the branch if specified
		if [ -n "$expected_branch" ]; then
			current_branch=$(git rev-parse --abbrev-ref HEAD)
			if [ "$current_branch" = "$expected_branch" ]; then
				echo "Branch $expected_branch is checked out correctly in $bsp_layer."
				cd ..
				continue
			else
				echo "Branch mismatch in $bsp_layer. Expected $expected_branch but found $current_branch."
				echo "Checking out to $expected_branch"
				clean_repository
				git checkout $expected_branch

				# Need to apply the neccessary patches
				apply_patches $bsp_layer
				cd ..
				continue
			fi
		fi

		# If none of branch, tag, or commit are specified
		log_warning "WARNING: No tag, commit, or branch specified for $bsp_layer. The existing layer will be used. Please verify that this is acceptable.\033[0m"
		cd ..
	done

	echo ""
}

# Handle missing meta-layer repositories
check_and_clone_missing_layers() {
	cd "${RZ_TARGET_DIR}"

	missing_layers=""
	bsp_layers=$("${JQ}" -r 'keys[]' "$PATCH_FILE")

	# Check for missing meta-layer repositories
	for bsp_layer in $bsp_layers; do
		if [ ! -d "${bsp_layer}" ]; then
			echo "Layer ${bsp_layer} is missing."
			missing_layers="${missing_layers} ${bsp_layer}"
		fi
	done

	# Clone missing meta-layer repositories
	for missing_layer in $missing_layers; do
		local repo_url repo_branch repo_commit repo_type
		repo_url=$("${JQ}" -r --arg repo "$missing_layer" '.[$repo].url // empty' "$PATCH_FILE")
		repo_branch=$("${JQ}" -r --arg repo "$missing_layer" '.[$repo].branch // empty' "$PATCH_FILE")
		repo_commit=$("${JQ}" -r --arg repo "$missing_layer" '.[$repo].commit // empty' "$PATCH_FILE")
		repo_tag=$("${JQ}" -r --arg repo "$missing_layer" '.[$repo].tag // empty' "$PATCH_FILE")
		repo_type=$("${JQ}" -r --arg repo "$missing_layer" '.[$repo].type // empty' "$PATCH_FILE")

		# If the missing repos is local
		if [ "$repo_type" = "local" ]; then
			unpack_gpu
			unpack_codec
			cd "${RZ_TARGET_DIR}/$missing_layer"
		elif [ "$repo_type" = "git" ]; then
			if [ -z "$repo_url" ] || [ "$repo_url" = "null" ]; then
				log_error "Error: No URL specified for $missing_layer. Cannot clone repository. Please verify the 'url' key in $PATCH_FILE."
				exit 1
			fi

			echo "Cloning missing repository for $missing_layer from $repo_url..."
			clone_repo_with_retries "$repo_url" || {
				log_error "Failed to clone repository for $missing_layer. Exiting."
				exit 1
			}

			cd "${missing_layer}"

			# Checkout tag, commit or branch if specified
			if [ -n "$repo_tag" ]; then
				git checkout "$repo_tag"
			elif [ -n "$repo_commit" ]; then
				git checkout "$repo_commit"
			elif [ -n "$repo_branch" ]; then
				git checkout "$repo_branch"
			else
				echo "Please define a tag, commit, or branch for $repo_name in the $PATCH_FILE or this layer will use default branch"
			fi
		else 
			log_error "Error: Repository type $missing_layer is missing or unrecognized. Please specify 'git' or 'local'."
			exit 1
		fi

		# Apply necessary patches
		apply_patches $missing_layer
		cd ..
	done

	echo "All required repositories now exist.\n"
	return 0
}

# Function to clone a repository with a specific branch or tag and retry on failure
clone_repo_with_retries() {
	local url="$1"         # Repository URL
	local max_retries=5    # Maximum number of retries
	local attempt=1        # Initialize attempt count

	# Loop for retry attempts
	while [ $attempt -le $max_retries ]; do
		echo "Attempting to clone (Attempt $attempt/$max_retries)..."

		# Clone the default branch first, then check out once the clone is successful.
		git clone "$url"

		# Capture the exit status of git clone
		CLONE_STATUS=$?

		# Check if the git clone was successful
		if [ $CLONE_STATUS -eq 0 ]; then
			echo "Git clone successful!"
			echo "Cloning completed successfully."
			return 0
		else
			echo "Git clone failed (Attempt $attempt/$max_retries)."
		fi

		attempt=$((attempt + 1))

		# Wait a bit before retrying
		sleep 2
	done

	echo "Git clone failed after $max_retries attempts."
	echo "Error: Cloning failed after multiple attempts."
	exit 1
}

extract_to_meta(){
	local zipfile=$1
	local tarfile=$2
	local tardir=$3

	cd ${WORKSPACE}
	pwd
	unzip ${zipfile}
	tar -xzf ${tarfile} -C ${tardir}
	sync
}

unpack_bsp(){
	local pkg_file=${WORKSPACE}/${REN_LINUX_BSP_PKG}${SUFFIX_ZIP}
	local zip_dir=${REN_LINUX_BSP_PKG}

	local bsp=${REN_LINUX_BSP_META}${SUFFIX_TAR}

	extract_to_meta ${pkg_file} "${zip_dir}/${bsp}" ${RZ_TARGET_DIR}
	rm -fr ${zip_dir}
}

get_bsp() {
	cd "${RZ_TARGET_DIR}"

	repo_names=$("${JQ}" -r 'keys[]' "$PATCH_FILE")

	# Clone and set up each repository
	for repo_name in $repo_names; do
		local repo_url repo_branch repo_commit repo_type
		repo_url=$("${JQ}" -r --arg repo "$repo_name" '.[$repo].url // empty' "$PATCH_FILE")
		repo_branch=$("${JQ}" -r --arg repo "$repo_name" '.[$repo].branch // empty' "$PATCH_FILE")
		repo_commit=$("${JQ}" -r --arg repo "$repo_name" '.[$repo].commit // empty' "$PATCH_FILE")
		repo_tag=$("${JQ}" -r --arg repo "$repo_name" '.[$repo].tag // empty' "$PATCH_FILE")
		repo_type=$("${JQ}" -r --arg repo "$repo_name" '.[$repo].type // empty' "$PATCH_FILE")

		# Only clone the git repositories
		if [ "$repo_type" = "local" ]; then
			continue
		fi

		# Raise an error when a git repo doesn't have the 'url' field set
		if [ -z "$repo_url" ] || [ "$repo_url" = "null" ]; then
			log_error "Error: No URL specified for $repo_name. Cannot clone repository. Please verify the 'url' key in $PATCH_FILE."
			exit 1
		fi

		echo "Cloning and setting up $repo_name from $url"

		clone_repo_with_retries "$repo_url"
		cd "$repo_name"

		# Checkout tag, commit or branch if specified
		if [ -n "$repo_tag" ]; then
			git checkout "$repo_tag"
		elif [ -n "$repo_commit" ]; then
			git checkout "$repo_commit"
		elif [ -n "$repo_branch" ]; then
			git checkout "$repo_branch"
		else
			echo "Please define a tag, commit, or branch for $repo_name in the $PATCH_FILE or this layer will use default branch"
		fi

		# Apply patches
		apply_patches "$repo_name"
		cd ..
	done

	echo "---------------------- Download completed --------------------------------------"
}

unpack_gpu() {
	local pkg_file=${WORKSPACE}/${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP}
	local zip_dir=${REN_GPU_MALI_LIB_PKG}

	local gpu=${REN_GPU_MALI_LIB_META_FEATURE}${SUFFIX_TAR}

	extract_to_meta ${pkg_file} "${zip_dir}/${gpu}" ${RZ_TARGET_DIR}
	rm -fr ${zip_dir}
}

unpack_codec() {
	local pkg_file=${WORKSPACE}/${REN_VEDIO_CODEC_LIB_PKG}${SUFFIX_ZIP}
	local zip_dir=${REN_VEDIO_CODEC_LIB_PKG}

	local codec=${REN_VEDIO_CODEC_LIB_META_FEATURE}${SUFFIX_TAR}

	extract_to_meta ${pkg_file} "${zip_dir}/${codec}" ${RZ_TARGET_DIR}
	rm -fr ${zip_dir}
}

setup_conf(){
	# Build RZ
	cd ${RZ_TARGET_DIR}
	echo "In yocto. pwd = ${PWD}"
	#source poky/oe-init-build-env
	echo "Env setup completed. pwd = ${PWD}"

	# Legacy style
	#cp ../meta-renesas/docs/template/conf/rzpi/* conf/
	#bitbake core-image-qt

	# New style
	TEMPLATECONF=$PWD/meta-renesas/meta-rzg2l/docs/template/conf/rzpi . ./poky/oe-init-build-env build

	# Remove templateconf.cfg as it will reference the old workspace directory when installing the eSDK on another host PC
	rm -f "conf/templateconf.cfg"

	# Check local overrides file
	if [ ! -e "$WORKSPACE/site.conf" ]; then
		echo "Local site.conf file not present in this workspace ($WORKSPACE). Assuming developer default build!"
		# Copy default template overrides file as yocto doesnt copy site.conf.sample
		cp ../meta-renesas/meta-rzg2l/docs/template/conf/rzpi/site.conf.sample conf/site.conf
		echo "This build is a common build for rzsbc. It is not based on any release tag. Target image: ${IMAGE}"
	else
		# Copy local overrides file to yocto build conf folder
		cp ${WORKSPACE}/site.conf conf/site.conf
		# Read and store revision from site.conf
		site_file="conf/site.conf"
		revision_value=$(grep '^SRCREV_pn-linux-renesas =' "$site_file" | cut -d '=' -f2)
		revision_value=$(echo "$revision_value" | sed 's/"//g')
		echo "This build is based on release tag:$revision_value. Target image: ${IMAGE}"
	fi


}

# Main setup
setup() {
	# Check and note down directory locations
	check_and_set_dir $1

	log_warning "WARNING: The script will check tags first, then commits, and finally branches if all three are specified. \
	It will check out to the specified tag, commit, or branch as needed."

	check_patch_require

	# if targe directory is not present, we have to create and unpack the contents.
	if [ ! -d ${RZ_TARGET_DIR} ];then
		check_pkg_require
		mkdir -p ${RZ_TARGET_DIR}
		#unpack_bsp
		get_bsp
		unpack_gpu
		unpack_codec
	else
		echo "${RZ_TARGET_DIR} already exists! Checking for any missing layers..."
		check_and_clone_missing_layers
	fi

	bsp_checkout_verification

	echo "Target contents in ${RZ_TARGET_DIR}:"
	(ls ${RZ_TARGET_DIR})
	echo ""
	echo "Finished preparing the rz yocto build source repository for RZ SBC board"
	echo "========================================================================="
}

# Main build-sdk
build_sdk() {
	setup $1

	setup_conf

	# if targe directory is not present, we have to build common before building sdk.
	if [ ! -d "${RZ_TARGET_DIR}/build/tmp/deploy/images" ];then
		echo "This SDK build will start from scratch."
	fi

	# If IMAGE is set to 'all-supported-images', build SDK for all supported images
	if [ "$IMAGE" == "all-supported-images" ]; then
		echo "Building SDK for all supported images..."

		for img in "${supported_images[@]}"; do
			echo "Building SDK for ${img}..."
			MACHINE=rzpi bitbake ${img}  -c populate_sdk_ext
			echo "Finished building SDK for ${img}"
		done

		echo
		echo "Finished the rz yocto SDK build for RZ SBC board with all supported images."
		echo "========================================================================"
	else
		# Build SDK for the specific image if IMAGE is set to a single value
		echo "Building SDK for the specific image: ${IMAGE}"
		MACHINE=rzpi bitbake ${IMAGE} -c populate_sdk_ext

		echo
		echo "Finished the rz yocto SDK build for RZ SBC board. Target image: ${IMAGE}"
		echo "========================================================================"
	fi

	deploy_build_assets
	#output
}

# Main build
build() {
	setup $1

	setup_conf

	# If IMAGE is set to 'all-supported-images', build all images
	if [ "$IMAGE" == "all-supported-images" ]; then
		echo "Building all supported images..."

		for img in "${supported_images[@]}"; do
			echo "Building ${img}..."
			MACHINE=rzpi bitbake ${img}
			echo "Finished building ${img}"
		done

		echo
		echo "Finished building all supported images."
		echo "========================================================================"
	else
		# Build the specific image if IMAGE is set to a single value
		echo "Building the specific image: ${IMAGE}"
		MACHINE=rzpi bitbake ${IMAGE}

		echo
		echo "Finished the Yocto build for RZ SBC board. Target image: ${IMAGE}"
		echo "========================================================================"
	fi

	deploy_build_assets
	#output
}

deploy_build_assets() {
	local target_dir="${RZ_TARGET_DIR}/build/tmp/deploy/images/rzpi/host/src"

	# Check if the src directory already exists
	if [ ! -d ${target_dir} ];then
		mkdir -p ${target_dir}
	fi

	# Copy build assets to the src directory
	cp "${PATCH_FILE}" "$target_dir"
	cp "${JQ}" "$target_dir"
	cp -r "${TOP_DIR}/patches" "$target_dir"
	cp "${TOP_DIR}/rzsbc_yocto.sh" "$target_dir"
	if [ -e "${TOP_DIR}/site.conf" ]; then
		cp "${TOP_DIR}/site.conf" "$target_dir"
	fi
	cp "${TOP_DIR}/README.md" "$target_dir"
}

# Main output
output() {
	export OUTPUT=${WORKSPACE}/output

	if [ ! -d ${OUTPUT} ];then
		mkdir -p ${OUTPUT}
	fi

	# Collect final output
	cd ${OUTPUT}
	cp ${RZ_TARGET_DIR}/build/tmp/deploy/images/rzpi/fip-rzpi.srec $OUTPUT
	cp ${RZ_TARGET_DIR}/build/tmp/deploy/images/rzpi/rzpi.dtb $OUTPUT
	cp -r ${RZ_TARGET_DIR}/build/tmp/deploy/images/rzpi/overlays $OUTPUT
	cp ${RZ_TARGET_DIR}/build/tmp/deploy/images/rzpi/readme.txt $OUTPUT
	cp ${RZ_TARGET_DIR}/build/tmp/deploy/images/rzpi/uEnv.txt $OUTPUT
	cp ${RZ_TARGET_DIR}/build/tmp/deploy/images/rzpi/Image $OUTPUT
	cp ${RZ_TARGET_DIR}/build/tmp/deploy/images/rzpi/bl2_bp-rzpi.srec $OUTPUT
	cp ${RZ_TARGET_DIR}/build/tmp/deploy/images/rzpi/Flash_Writer_SCIF_rzpi.mot $OUTPUT
	cp ${RZ_TARGET_DIR}/build/tmp/deploy/images/rzpi/core-image-qt-rzpi.tar.bz2 $OUTPUT

	echo "The output located at: $OUTPUT"
	ls -la $OUTPUT
	echo
	echo "Finished collecting the rz yocto output for RZ SBC board"
	echo "======================================================================"
}

# Main process
echo "PWD=${TOP_DIR}"
echo "Jquerry = ${JQ}"
if [ ! -n "$1" ] ; then
	guideline
else
	if [ $1 = "build" ]; then
		build $2
	elif [ $1 = "build-sdk" ]; then
		build_sdk $2
	else
		guideline
	fi
fi

exit 1