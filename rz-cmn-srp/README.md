# rz-sbc build package

This directory contains automated build scripts and resources for performing Yocto and Ubuntu builds for the RZ/G2L-SBC (RZ/G2L - Single Board Computer) platforms.

## Hierarchy

```
$ tree -L 3
.
├── files_to_add
│   └── meta-rz-features
│       ├── 0001-rzg2l-sbc-Bring-compat_alloc_user_space-back.patch
│       └── 0004-rzg2l-sbc-Get-interrupt-number.patch
├── git_patch.json
├── images.json
├── jq-linux-amd64
├── patches
│   ├── meta-rz-features
│   │   └── 0001-support-codec-for-linux-6.10-and-yocto-styhead.patch
│   └── meta-summit-radio
│       ├── 0001-rz-sbc-meta-summit-radio-Support-build-in-yocto-styh.patch
│       └── 0002-rz-sbc-summit-radio-support-eSDK-build.patch
├── README.md
├── rzsbc_builder.sh
└── ubuntu
    ├── config
    │   ├── ubuntu_core
    │   └── ubuntu_lxde
    ├── config.ini
    ├── docs
    │   ├── ubuntu_core
    │   └── ubuntu_lxde
    ├── include
    │   ├── common
    │   ├── ubuntu_core
    │   └── ubuntu_lxde
    ├── README.md
    ├── script
    │   ├── ubuntu_core
    │   └── ubuntu_lxde
    └── setup_ubuntu_environment.sh

19 directories, 13 files
``` 

## Organization:

| File                 | Description                                                                                                                                                     |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| git_patch.json        | Contains json keys and repository configuration such as: url, branch, tag, commit, repo type and patch paths to apply.                                          |
| images.json           | Contains the available build image options grouped by build type, including Yocto images, Ubuntu images, and static image collections (all-yocto-images, all-ubuntu-images, all-supported-images).|
| jq-linux-amd64        | JSON querry oss binary to perform reads of git_patch.json from shell script.                                                                                    |
| patches/              | Folder containing patches. This should ideally be organized into sub directories named after the json key.                                                      |
| rzsbc_builder.sh      | The main build script that performs setup, configuration, and build operations for both Ubuntu and Yocto build processes.                                       |
| site.conf [optional]  | An optional overrride site.conf. If present, this will be used as the override file. If not, the template conf site.conf will be used from meta-renesas layer.  |
| ubuntu/               | Directory containing files and scripts related to building Ubuntu-based images for the platform, supporting variants such as ubuntu_core and ubuntu_lxde.  |
| README.md             | This document. This document provides an overview of the rz-sbc build package. It serves as a guide for users to understand how to set up and execute the Yocto build process, as well as how to manage and utilize the build artifacts and patches.|

## Image Categories

The `images.json` file contains the list of available build image options categorized by build system and image groups.

- **yocto**: Lists individual Yocto-based images you can build, such as:
    - `core-image-minimal`
    - `core-image-bsp`
    - `core-image-weston`
    - `renesas-core-image-cli`
    - `renesas-core-image-weston`
    - `renesas-quickboot-cli`
    - `renesas-quickboot-wayland`

- **ubuntu**: Lists Ubuntu-based images available for building, such as:
    - `ubuntu-core`
    - `ubuntu-lxde`

- **static**: Defines groups of images to build multiple targets in one command, including:
    - `all-yocto-images`
    - `all-ubuntu-images`
    - `all-supported-images`

Only categories and images that are actively supported and integrated in the build process are included in `images.json`. Others might not exist yet or aren’t supported.

## Managing Repositories and Applying Patches

In the `git_patch.json` file, you will find a list of repositories, their branches or tags, and any patches that need to be applied. This section will guide you through how to use this information for successful builds.

### Repository Information
The `git_patch.json` contains the following fields for each repository:

- url: The URL to clone the repository.
- branch/tag/commit: Specifies the branch, tag, or commit to check out.
- patches: Lists the patches that need to be applied to this repository.
- add_files: Lists of additional files that should be copied into the meta layer, specifying their source and target locations.
- type: Defines whether the repository is hosted remotely (e.g., "git") or is local (e.g., "local").
- enable: A flag indicating whether the repository should be cloned and included in the Yocto build process. A value of true enables the repository, while false excludes it.

### Note

When checking out a repository, the order of priority is:

- First, it will look for a tag.
- If no tag is specified, it will check for a commit.
- If neither a tag nor a commit is found, it will look for a branch.
- If none of these are found, it will use the default branch if the layer is not already present. If the layer exists, it will leave the existing folder unchanged.

## Yocto Build

You can perform the yocto build right here or by moving this directorys contents to your chosed location.
To perform yocto build with all RZ SOc's IP's functioning, you will need to download the following going through the click through agreements.

| File                             |   Description                                                                                                                |
|----------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| RTK0EF0045Z15001ZJ-v1.1.0_EN.zip | RZ codec driver and HAL package.    |

> [!IMPORTANT]
> Simply running the script `rzsbc_builder.sh` will tell you the command options.
> Running the script with `build` parameter (`rzsbc_builder.sh build`) will give you the download url's of the missing packages.

> [!IMPORTANT]
> Please ensure that you are making this build in an ubuntu 24.04 OS environment through docker/VM/native-OS installations.

Once you download the packages, place the zip files here.
Then rerun the build script and it will take care of everything else.

## Build output

The following output is an example of the build artifacts generated for the `all-supported-images` target. These images will be located in the `tmp/deploy/images/<machine_name>/` directory within your Yocto build folder. If you use the default build location and run the script with only the `build` argument, the images will be found at `yocto_rzcmn_board/build/tmp/deploy/images/<machine_name>/`

```
.
|-- README.md
|-- RZG2L-SBC_Evaluation_license.pdf
|-- host
|   |-- Readme.md
|   |-- build
|   |   |-- core-image-bsp-<timestamp>.rootfs.manifest
|   |   |-- core-image-bsp-<timestamp>.testdata.json
|   |   |-- core-image-bsp.manifest -> core-image-bsp-<timestamp>.rootfs.manifest
|   |   |-- core-image-bsp.testdata.json -> core-image-bsp-<timestamp>.testdata.json
|   |   |-- core-image-minimal-<timestamp>.rootfs.manifest
|   |   |-- core-image-minimal-<timestamp>.testdata.json
|   |   |-- core-image-minimal.manifest -> core-image-minimal-<timestamp>.rootfs.manifest
|   |   |-- core-image-minimal.testdata.json -> core-image-minimal-<timestamp>.testdata.json
|   |   |-- core-image-weston-<timestamp>.rootfs.manifest
|   |   |-- core-image-weston-<timestamp>.testdata.json
|   |   |-- core-image-weston.manifest -> core-image-weston-<timestamp>.rootfs.manifest
|   |   |-- core-image-weston.testdata.json -> core-image-weston-<timestamp>.testdata.json
|   |   |-- renesas-core-image-cli-<timestamp>.rootfs.manifest
|   |   |-- renesas-core-image-cli-<timestamp>.testdata.json
|   |   |-- renesas-core-image-cli.manifest -> renesas-core-image-cli-<timestamp>.rootfs.manifest
|   |   |-- renesas-core-image-cli.testdata.json -> renesas-core-image-cli-<timestamp>.testdata.json
|   |   |-- renesas-core-image-weston-<timestamp>.rootfs.manifest
|   |   |-- renesas-core-image-weston-<timestamp>.testdata.json
|   |   |-- renesas-core-image-weston.manifest -> renesas-core-image-weston-<timestamp>.rootfs.manifest
|   |   |-- renesas-core-image-weston.testdata.json -> renesas-core-image-weston-<timestamp>.testdata.json
|   |   |-- renesas-quickboot-cli-<timestamp>.rootfs.manifest
|   |   |-- renesas-quickboot-cli-<timestamp>.testdata.json
|   |   |-- renesas-quickboot-cli.manifest -> renesas-quickboot-cli-<timestamp>.rootfs.manifest
|   |   |-- renesas-quickboot-cli.testdata.json -> renesas-quickboot-cli-<timestamp>.testdata.json
|   |   |-- renesas-quickboot-wayland-<timestamp>.rootfs.manifest
|   |   |-- renesas-quickboot-wayland-<timestamp>.testdata.json
|   |   |-- renesas-quickboot-wayland.manifest -> renesas-quickboot-wayland-<timestamp>.rootfs.manifest
|   |   |-- renesas-quickboot-wayland.testdata.json -> renesas-quickboot-wayland-<timestamp>.testdata.json
|   |   |-- renesas-ubuntu-<timestamp>.rootfs.manifest
|   |   |-- renesas-ubuntu-<timestamp>.testdata.json
|   |   |-- renesas-ubuntu.manifest -> renesas-ubuntu-<timestamp>.rootfs.manifest
|   |   `-- renesas-ubuntu.testdata.json -> renesas-ubuntu-<timestamp>.testdata.json
|   |-- env
|   |   |-- Readme.md
|   |   |-- core-image-bsp.env
|   |   |-- core-image-minimal.env
|   |   |-- core-image-weston.env
|   |   |-- renesas-core-image-cli.env
|   |   |-- renesas-core-image-weston.env
|   |   |-- renesas-quickboot-cli.env
|   |   `-- renesas-quickboot-wayland.env
|   |-- src
|   |   `-- rz-cmn-srp
|   |       |-- README.md
|   |       |-- git_patch.json
|   |       |-- images.json
|   |       |-- jq-linux-amd64
|   |       |-- patches
|   |       |   |-- meta-rz-features
|   |       |   |   `-- 0001-support-codec-for-linux-6.10-and-yocto-styhead.patch
|   |       |   `-- meta-summit-radio
|   |       |       |-- 0001-rz-sbc-meta-summit-radio-Support-build-in-yocto-styh.patch
|   |       |       `-- 0002-rz-sbc-summit-radio-support-eSDK-build.patch
|   |       |-- rzsbc_builder.sh
|   |       `-- ubuntu
|   |           |-- config
|   |           |   |-- ubuntu_core
|   |           |   |   |-- network_interfaces.conf
|   |           |   |   `-- resolved.conf
|   |           |   `-- ubuntu_lxde
|   |           |       |-- NetworkManager.conf
|   |           |       |-- connman-gtk.desktop
|   |           |       |-- interfaces
|   |           |       |-- lightdm.conf
|   |           |       |-- rsyslog
|   |           |       |-- ttyS0.conf
|   |           |       `-- v4l2-init.sh
|   |           |-- config.ini
|   |           |-- docs
|   |           |   |-- ubuntu_core
|   |           |   |   `-- README.md
|   |           |   `-- ubuntu_lxde
|   |           |       |-- Pictures
|   |           |       |   |-- audacity.png
|   |           |       |   |-- bluetooth_0.png
|   |           |       |   |-- bluetooth_1.png
|   |           |       |   |-- bluetooth_2.png
|   |           |       |   |-- bluetooth_3.png
|   |           |       |   |-- bluetooth_4.png
|   |           |       |   |-- csi_0.png
|   |           |       |   |-- csi_1.png
|   |           |       |   |-- csi_2.png
|   |           |       |   |-- eth.png
|   |           |       |   |-- eth_1.png
|   |           |       |   |-- eth_2.png
|   |           |       |   |-- eth_3.png
|   |           |       |   |-- eth_4.png
|   |           |       |   |-- eth_5.png
|   |           |       |   |-- save_audio_0.png
|   |           |       |   |-- save_audio_1.png
|   |           |       |   |-- save_audio_2.png
|   |           |       |   |-- vlc.png
|   |           |       |   |-- vlc_open_0.png
|   |           |       |   |-- vlc_open_1.png
|   |           |       |   |-- vlc_open_2.png
|   |           |       |   |-- vlc_video.png
|   |           |       |   |-- vlc_video_1.png
|   |           |       |   |-- web.png
|   |           |       |   |-- web_1.png
|   |           |       |   |-- web_2.png
|   |           |       |   |-- web_lxterm_htop.png
|   |           |       |   `-- wifi_0.png
|   |           |       `-- README.md
|   |           |-- include
|   |           |   |-- common
|   |           |   |   |-- allow_empty_password.sh
|   |           |   |   |-- create_wic.sh
|   |           |       |-- mount.sh
|   |           |   |   |-- install_gstreamer.sh
|   |           |   |   |-- install_weston.sh
|   |           |   |   |-- prepare_env.sh
|   |           |   |   |-- prepare_env_rootfs.sh
|   |           |   |   |-- prepare_ubuntu_base.sh
|   |           |   |   `-- yocto_working.sh
|   |           |   |-- ubuntu_core
|   |           |   |   |-- prepare_conf.sh
|   |           |   |   |-- prepare_env.sh
|   |           |   |   |-- prepare_rootfs_qt.sh
|   |           |   |   `-- setup_dns.sh
|   |           |   `-- ubuntu_lxde
|   |           |       |-- create_swap.sh
|   |           |       |-- prepare_conf.sh
|   |           |       `-- prepare_rootfs_qt.sh
|   |           |-- script
|   |           |   |-- common
|   |           |   |   |-- dpkg-install-lock-fix.sh
|   |           |   |   `-- setup_dns_and_time.sh
|   |           |   |-- ubuntu_core
|   |           |   |   |-- apt_install_base.sh
|   |           |   |   |-- link_to_leagcy_iptables.sh
|   |           |   |   `-- set_root_password.sh
|   |           |   `-- ubuntu_lxde
|   |           |       |-- apt_audio_video.sh
|   |           |       |-- apt_blueman.sh
|   |           |       |-- apt_install_base.sh
|   |           |       |-- apt_lxde_desktop.sh
|   |           |       |-- apt_wifi_ble.sh
|   |           |       |-- create_user.sh
|   |           |       |-- set_root_password.sh
|   |           |       |-- set_swap_enable.sh
|   |           |       `-- setup-set-permissions.sh
|   |           `-- setup_ubuntu_environment.sh
|   `-- tools
|       |-- Readme.md
|       |-- bootloader-flasher
|       |   |-- Readme.md
|       |   |-- linux
|       |   |   |-- Readme.md
|       |   |   `-- bootloader_flash.py
|       |   `-- windows
|       |       |-- Readme.md
|       |       |-- config.ini
|       |       |-- flash_bootloader.bat
|       |       `-- tools
|       |           |-- TERATERM.INI
|       |           |-- cygterm.cfg
|       |           |-- flash_bootloader.ttl
|       |           |-- ttermpro.exe
|       |           |-- ttpcmn.dll
|       |           |-- ttpfile.dll
|       |           |-- ttpmacro.exe
|       |           |-- ttpset.dll
|       |           `-- ttxssh.dll
|       |-- sd-creator
|       |   |-- Readme.md
|       |   |-- linux
|       |   |   |-- Readme.md
|       |   |   `-- sd_flash.sh
|       |   `-- windows
|       |       |-- Readme.md
|       |       |-- config.ini
|       |       |-- flash_filesystem.bat
|       |       `-- tools
|       |           |-- AdbWinApi.dll
|       |           |-- TERATERM.INI
|       |           |-- cygterm.cfg
|       |           |-- fastboot.bat
|       |           |-- fastboot.exe
|       |           |-- flash_system_image.ttl
|       |           |-- ttermpro.exe
|       |           |-- ttpcmn.dll
|       |           |-- ttpfile.dll
|       |           |-- ttpmacro.exe
|       |           |-- ttpset.dll
|       |           `-- ttxssh.dll
|       `-- uload-bootloader
|           |-- Readme.md
|           |-- linux
|           |   |-- Readme.md
|           |   `-- uload_bootloader_flash.py
|           `-- windows
|               |-- Readme.md
|               |-- config.ini
|               |-- tools
|               |   |-- TERATERM.INI
|               |   |-- cygterm.cfg
|               |   |-- ttermpro.exe
|               |   |-- ttpcmn.dll
|               |   |-- ttpfile.dll
|               |   |-- ttpmacro.exe
|               |   |-- ttpset.dll
|               |   |-- ttxssh.dll
|               |   `-- uload-flash_bootloader.ttl
|               `-- uload-flash_bootloader.bat
|-- license
|   |-- Disclaimer051.pdf
|   `-- Disclaimer052.pdf
|-- r11qs0062eu0200-rz-srp-yocto5-um-quick-start-guide.pdf
|-- r12uz0177eu0200-rz-srp-yocto5-um.pdf
`-- target
    |-- Readme.md
    |-- env
    |   |-- Readme.md
    |   `-- uEnv.txt
    `-- images
        |-- Flash_Writer_SCIF_rzg2l-sbc.mot
        |-- Flash_Writer_SCIF_rzg2l-sbc_PMIC.mot
        |-- Image -> Image--6.10.14+git0+<commit-hash>-r0-rz-cmn-<timestamp>.bin
        |-- Image--6.10.14+git0+<commit-hash>-r0-rz-cmn-<timestamp>.bin
        |-- Readme.md
        |-- bl2-rzg2l-sbc.bin
        |-- bl2_bp-rzg2l-sbc.bin
        |-- bl2_bp-rzg2l-sbc.srec
        |-- core-image-bsp.wic
        |-- core-image-minimal.wic
        |-- core-image-weston.wic
        |-- dtbs
        |   |-- Readme.md
        |   |-- overlays
        |   |   |-- Readme.md
        |   |   |-- rzg2l-sbc-can.dtbo
        |   |   |-- rzg2l-sbc-dsi.dtbo
        |   |   |-- rzg2l-sbc-ext-i2c.dtbo
        |   |   |-- rzg2l-sbc-ext-spi.dtbo
        |   |   `-- rzg2l-sbc-ov5640.dtbo
        |   |-- rzg2l-sbc--6.10.14+git0+<commit-hash>-r0-rzg2l-sbc-<timestamp>.dtbo
        |   `-- rzg2l-sbc.dtb -> rzg2l-sbc--6.10.14+git0+<commit-hash>-r0-rzg2l-sbc-<timestamp>.dtbo
        |-- fip-rzg2l-sbc.bin
        |-- fip-rzg2l-sbc.srec
        |-- renesas-core-image-cli.wic
        |-- renesas-core-image-weston.wic
        |-- renesas-quickboot-cli.wic
        |-- renesas-quickboot-wayland.wic
        |-- rootfs
        |   |-- Readme.md
        |   |-- core-image-bsp.tar.bz2
        |   |-- core-image-minimal.tar.bz2
        |   |-- core-image-weston.tar.bz2
        |   |-- renesas-core-image-cli.tar.bz2
        |   |-- renesas-core-image-weston.tar.bz2
        |   |-- renesas-quickboot-cli.tar.bz2
        |   |-- renesas-quickboot-wayland.tar.bz2
        |   |-- renesas-ubuntu.tar.bz2
        |   |-- ubuntu-core-image.tar.bz2
        |   `-- ubuntu-lxde-image.tar.bz2
        |-- ubuntu-core-image.wic.gz
        `-- ubuntu-lxde-image.wic.gz

43 directories, 216 files

```
## User Manual

The build provides comprehensive documentation of the supported board and all the features in a user manual having the name `rz-srp-yocto5-um.pdf`.

> [!IMPORTANT]
> The user manual name is prefixed with an internal code that we use for tracking and version within our systems. The actual filename would have a prefix looking like :
> `xxxxxx-rz-srp-yocto5-um.pdf`
>
> The document gets updated with each official release.
