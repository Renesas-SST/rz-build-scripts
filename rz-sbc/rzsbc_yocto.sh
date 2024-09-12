#!/bin/bash
# Version: Release
# -----------------------------Yocto package------------------------------------
# Make sure that the following packages have been downloaded from the official website
# RZ/G Verified Linux Package [5.10-CIP] V3.0.5 update1
REN_LINUX_BSP_PKG="RTK0EF0045Z0021AZJ-v3.0.5-update1"
REN_LINUX_BSP_META="rzg_vlp_v3.0.5"
REN_LOCAL_META="meta-renesas"
REN_LOCAL_REPO="https://github.com/Renesas-SST/meta-renesas.git"
REN_LOCAL_BRANCH="dunfell/rz-sbc"

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
    echo " ./rzsbc_yocto.sh <target_build> <target_dir>"
    echo "--------------------------"
    echo " - <target_build>: the build options. It can be an image build (1) or a SDK build (2) as follows"
    echo "     1. build"
    echo "     2. build-sdk"
    echo " - <target_dir>: the build directory"
    echo "     If not set <target_dir>: current directory will be selected"
    echo "------------------------------------------------------------"
}

apply_patches() {
    local key="$1"
    local target_dir="$2"

    echo "Applying patches for key: $key in directory: $target_dir"

    # Get the list of patches from the JSON file
    local patch_list
    patch_list=$("${JQ}" -r ".${key}[]" "$PATCH_FILE")
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON file."
        exit 1
    fi

    # Check if the patch list is empty or null
    if [ -z "$patch_list" ]; then
        echo "No patches to apply for key: $key"
        return 0
    fi

    echo "Patch list: $patch_list"  # Debugging line

    # Apply each patch
    while IFS= read -r local_patch; do
        # Remove any leading/trailing whitespace from patch file names
        local_patch=$(echo "$local_patch" | xargs)
        if [ -f "$TOP_DIR/$local_patch" ]; then
            echo "Applying local patch: $TOP_DIR/$local_patch"
            echo $PWD
            git apply "$TOP_DIR/$local_patch"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to apply patch $TOP_DIR/$local_patch."
                exit 1
            fi
        fi

    done <<< "$patch_list"
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

log_error(){
    local string=$1
    echo -ne "\e[31m $string \e[0m\n"
}

check_pkg_require(){
    # check required pacakages are downloaded from Renesas website and local package
    local check=0

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

    # Extract all patch paths from the JSON file and ignore empty entries
    local patch_list
    patch_list=$("${JQ}" -r '.[] | .[]' "$PATCH_FILE")

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

    cd ${RZ_TARGET_DIR}
    rm -rf ${REN_LOCAL_META}
    git clone ${REN_LOCAL_REPO} ${REN_LOCAL_META}
    cd ${REN_LOCAL_META} && git checkout ${REN_LOCAL_BRANCH} && rm -rf .git
}

setup_meta_chromium() {
    git clone https://github.com/kraj/meta-clang -b dunfell-clang12
    cd meta-clang
    apply_patches "clang"
    cd ..

    git clone https://github.com/OSSystems/meta-browser.git
    cd meta-browser
    git checkout f2d5539552b54099893a7339cbb2ab46b42ee754
    apply_patches "browser"
}

get_bsp() {
    cd ${RZ_TARGET_DIR}
    git clone ${REN_LOCAL_REPO} ${REN_LOCAL_META}
    cd ${REN_LOCAL_META} && git checkout ${REN_LOCAL_BRANCH}
    cd ..

    git clone https://git.yoctoproject.org/git/poky
    cd poky
    git checkout dunfell-23.0.26
    apply_patches "poky"
    cd ..

    git clone https://github.com/openembedded/meta-openembedded
    cd meta-openembedded
    git checkout 6334241447e461f849035c47f071fa4a2125fee1
    apply_patches "openembedded"
    cd ..

    git clone https://git.yoctoproject.org/git/meta-gplv2
    cd meta-gplv2
    git checkout 60b251c25ba87e946a0ca4cdc8d17b1cb09292ac
    apply_patches "gplv2"
    cd ..

    git clone https://github.com/meta-qt5/meta-qt5.git
    cd meta-qt5
    git checkout -b tmp c1b0c9f546289b1592d7a895640de103723a0305
    apply_patches "qt5"
    cd ..

    git clone https://git.yoctoproject.org/git/meta-virtualization
    cd meta-virtualization
    git checkout 521459bf588435e847d981657485bae8d6f003b5
    apply_patches "virtualization"
    cd ..

    git clone https://github.com/LairdCP/meta-summit-radio.git -b lrd-11.39.0.x
    # Add patch for meta-summit-radio to support eSDK build
    cd meta-summit-radio
    apply_patches summit
    cd ..

    setup_meta_chromium
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

    # Check local overrides file
    if [ ! -e "$WORKSPACE/site.conf" ]; then
        echo "Local site.conf file not present in this workspace ($WORKSPACE). Please prepare one!"
        exit
    fi

    # Copy local overrides file to yocto build conf folder
    cp ${WORKSPACE}/site.conf conf/site.conf

    # Read and store revision from site.conf
    site_file="conf/site.conf"
    revision_value=$(grep '^SRCREV_pn-linux-renesas =' "$site_file" | cut -d '=' -f2)
    revision_value=$(echo "$revision_value" | sed 's/"//g')

    echo "This build is based on release tag:$revision_value"
}

# Main setup
setup() {
    # Check and note down directory locations
    check_and_set_dir $1

    # if targe directory is not present, we have to create and unpack the contents.
    if [ ! -d ${RZ_TARGET_DIR} ];then
        check_pkg_require
        check_patch_require
        mkdir -p ${RZ_TARGET_DIR}
        #unpack_bsp
        get_bsp
        unpack_gpu
        unpack_codec
    else
        echo "${RZ_TARGET_DIR} exists! Skipping setup. Commencing build on exiting repo."
    fi
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

    #Initiate build sdk
    MACHINE=rzpi bitbake core-image-qt -c populate_sdk_ext

    echo
    echo "Finished the rz yocto sdk build for RZ SBC board"
    echo "========================================================================"

    #output
}

# Main build
build() {
    setup $1

    setup_conf

    # Initiate build
    MACHINE=rzpi bitbake core-image-qt

    echo
    echo "Finished the rz yocto build for RZ SBC board"
    echo "========================================================================"

    #output
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