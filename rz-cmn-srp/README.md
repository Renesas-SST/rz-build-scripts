# rz-sbc build package

This directory contains automated build scripts and resources for performing Yocto and Ubuntu builds for the RZ/G2L-SBC (RZ/G2L - Single Board Computer) platforms.

## Hierarchy

```
$ tree -L 3
.
├── git_patch.json
├── images.json
├── jq-linux-amd64
├── patches
│   ├── meta-summit-radio
│   │   ├── 0001-rzsbc-summit-radio-pre-3.4-support-eSDK-build.patch
│   │   └── 0002-rzsbc-summit-radio-pre-3.4-enable-usb-bt-support.patch
│   └── poky
│       └── 0001-meta-classes-esdk-explicitly-address-the-location-of.patch
├── README.md
├── rzsbc_builder.sh
├── site.conf       /* (optional) */
└── ubuntu
    ├── config
    │   ├── ubuntu_core
    │   └── ubuntu_lxde
    ├── config.ini
    ├── docs
    │   ├── ubuntu_core
    │   └── ubuntu_lxde
    ├── include
    │   ├── common
    │   ├── ubuntu_core
    │   └── ubuntu_lxde
    ├── README.md
    ├── setup_ubuntu_environment.sh
    └── script
        ├── ubuntu_core
        └── ubuntu_lxde

17 directories, 12 files
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
    - `core-image-qt`
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
- type: Defines whether the repository is hosted remotely (e.g., "git") or is local (e.g., "local").

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
| RTK0EF0045Z13001ZJ-v1.1.2_EN.zip | RZ Mali GPU driver and HAL package.  |
| RTK0EF0045Z15001ZJ-v1.1.0_EN.zip | RZ codec driver and HAL package.    |

> [!IMPORTANT]
> Simply running the script `rzsbc_builder.sh` will tell you the command options.
> Running the script with `build` parameter (`rzsbc_builder.sh build`) will give you the download url's of the missing packages.

> [!IMPORTANT]
> Please ensure that you are making this build in an ubuntu 20.04 OS environment through docker/VM/native-OS installations.

Once you download the packages, place the zip files here.
Then rerun the build script and it will take care of everything else.

## Build output

The following output is an example of the build artifacts generated for the `all-supported-images` target. These images will be located in the `tmp/deploy/images/rzpi/` directory within your Yocto build folder. If you use the default build location and run the script with only the `build` argument, the images will be found at `yocto_rzsbc_board/build/tmp/deploy/images/rzpi/`

```
.
├── host
│   ├── build
│   │   ├── core-image-bsp-rzpi-20250516152539.rootfs.manifest
│   │   ├── core-image-bsp-rzpi-20250516152539.testdata.json
│   │   ├── core-image-bsp-rzpi.manifest -> core-image-bsp-rzpi-20250516152539.rootfs.manifest
│   │   ├── core-image-bsp-rzpi.testdata.json -> core-image-bsp-rzpi-20250516152539.testdata.json
│   │   ├── core-image-minimal-rzpi-20250516152445.rootfs.manifest
│   │   ├── core-image-minimal-rzpi-20250516152445.testdata.json
│   │   ├── core-image-minimal-rzpi.manifest -> core-image-minimal-rzpi-20250516152445.rootfs.manifest
│   │   ├── core-image-minimal-rzpi.testdata.json -> core-image-minimal-rzpi-20250516152445.testdata.json
│   │   ├── core-image-qt-rzpi-20250516152816.rootfs.manifest
│   │   ├── core-image-qt-rzpi-20250516152816.testdata.json
│   │   ├── core-image-qt-rzpi.manifest -> core-image-qt-rzpi-20250516152816.rootfs.manifest
│   │   ├── core-image-qt-rzpi.testdata.json -> core-image-qt-rzpi-20250516152816.testdata.json
│   │   ├── core-image-weston-rzpi-20250516152636.rootfs.manifest
│   │   ├── core-image-weston-rzpi-20250516152636.testdata.json
│   │   ├── core-image-weston-rzpi.manifest -> core-image-weston-rzpi-20250516152636.rootfs.manifest
│   │   ├── core-image-weston-rzpi.testdata.json -> core-image-weston-rzpi-20250516152636.testdata.json
│   │   ├── renesas-core-image-cli-rzpi-20250516153041.rootfs.manifest
│   │   ├── renesas-core-image-cli-rzpi-20250516153041.testdata.json
│   │   ├── renesas-core-image-cli-rzpi.manifest -> renesas-core-image-cli-rzpi-20250516153041.rootfs.manifest
│   │   ├── renesas-core-image-cli-rzpi.testdata.json -> renesas-core-image-cli-rzpi-20250516153041.testdata.json
│   │   ├── renesas-core-image-weston-rzpi-20250516153223.rootfs.manifest
│   │   ├── renesas-core-image-weston-rzpi-20250516153223.testdata.json
│   │   ├── renesas-core-image-weston-rzpi.manifest -> renesas-core-image-weston-rzpi-20250516153223.rootfs.manifest
│   │   ├── renesas-core-image-weston-rzpi.testdata.json -> renesas-core-image-weston-rzpi-20250516153223.testdata.json
│   │   ├── renesas-quickboot-cli-rzpi-20250516153447.rootfs.manifest
│   │   ├── renesas-quickboot-cli-rzpi-20250516153447.testdata.json
│   │   ├── renesas-quickboot-cli-rzpi.manifest -> renesas-quickboot-cli-rzpi-20250516153447.rootfs.manifest
│   │   ├── renesas-quickboot-cli-rzpi.testdata.json -> renesas-quickboot-cli-rzpi-20250516153447.testdata.json
│   │   ├── renesas-quickboot-wayland-rzpi-20250516153601.rootfs.manifest
│   │   ├── renesas-quickboot-wayland-rzpi-20250516153601.testdata.json
│   │   ├── renesas-quickboot-wayland-rzpi.manifest -> renesas-quickboot-wayland-rzpi-20250516153601.rootfs.manifest
│   │   └── renesas-quickboot-wayland-rzpi.testdata.json -> renesas-quickboot-wayland-rzpi-20250516153601.testdata.json
│   ├── env
│   │   ├── core-image-bsp.env
│   │   ├── core-image-minimal.env
│   │   ├── core-image-qt.env
│   │   ├── core-image-weston.env
│   │   ├── Readme.md
│   │   ├── renesas-core-image-cli.env
│   │   ├── renesas-core-image-weston.env
│   │   ├── renesas-quickboot-cli.env
│   │   └── renesas-quickboot-wayland.env
│   ├── Readme.md
│   ├── src
│   │   └── rz-cmn-srp
│   │       ├── git_patch.json
│   │       ├── images.json
│   │       ├── jq-linux-amd64
│   │       ├── patches
│   │       │   ├── meta-summit-radio
│   │       │   │   ├── 0001-rzsbc-summit-radio-pre-3.4-support-eSDK-build.patch
│   │       │   │   └── 0002-rzsbc-summit-radio-pre-3.4-enable-usb-bt-support.patch
│   │       │   └── poky
│   │       │       └── 0001-meta-classes-esdk-explicitly-address-the-location-of.patch
│   │       ├── README.md
│   │       ├── rzsbc_builder.sh
│   │       └── ubuntu
│   │           ├── config
│   │           │   ├── ubuntu_core
│   │           │   │   ├── network_interfaces.conf
│   │           │   │   └── resolved.conf
│   │           │   └── ubuntu_lxde
│   │           │       ├── interfaces
│   │           │       ├── lightdm.conf
│   │           │       ├── NetworkManager.conf
│   │           │       ├── rsyslog
│   │           │       ├── ttyS0.conf
│   │           │       └── v4l2-init.sh
│   │           ├── config.ini
│   │           ├── docs
│   │           │   ├── ubuntu_core
│   │           │   │   └── README.md
│   │           │   └── ubuntu_lxde
│   │           │       ├── Pictures
│   │           │       │   ├── audacity.png
│   │           │       │   ├── bluetooth_0.png
│   │           │       │   ├── bluetooth_1.png
│   │           │       │   ├── bluetooth_2.png
│   │           │       │   ├── bluetooth_3.png
│   │           │       │   ├── bluetooth_4.png
│   │           │       │   ├── csi_0.png
│   │           │       │   ├── csi_1.png
│   │           │       │   ├── csi_2.png
│   │           │       │   ├── eth_1.png
│   │           │       │   ├── eth_2.png
│   │           │       │   ├── eth_3.png
│   │           │       │   ├── eth_4.png
│   │           │       │   ├── eth_5.png
│   │           │       │   ├── eth.png
│   │           │       │   ├── save_audio_0.png
│   │           │       │   ├── save_audio_1.png
│   │           │       │   ├── save_audio_2.png
│   │           │       │   ├── vlc_open_0.png
│   │           │       │   ├── vlc_open_1.png
│   │           │       │   ├── vlc_open_2.png
│   │           │       │   ├── vlc.png
│   │           │       │   ├── vlc_video_1.png
│   │           │       │   ├── vlc_video.png
│   │           │       │   ├── web_1.png
│   │           │       │   ├── web_2.png
│   │           │       │   ├── web_lxterm_htop.png
│   │           │       │   ├── web.png
│   │           │       │   └── wifi_0.png
│   │           │       └── README.md
│   │           ├── include
│   │           │   ├── common
│   │           │   │   ├── allow_empty_password.sh
│   │           │   │   ├── create_wic.sh
│   │           │   │   ├── install_gstreamer.sh
│   │           │   │   ├── install_weston.sh
│   │           │   │   ├── prepare_ubuntu_base.sh
│   │           │   │   └── yocto_working.sh
│   │           │   ├── ubuntu_core
│   │           │   │   ├── mount.sh
│   │           │   │   ├── prepare_conf.sh
│   │           │   │   ├── prepare_env.sh
│   │           │   │   ├── prepare_rootfs_qt.sh
│   │           │   │   └── setup_dns.sh
│   │           │   └── ubuntu_lxde
│   │           │       ├── create_swap.sh
│   │           │       ├── mount.sh
│   │           │       ├── prepare_conf.sh
│   │           │       └── prepare_rootfs_qt.sh
│   │           ├── script
│   │           │   ├── ubuntu_core
│   │           │   │   ├── apt_install_base.sh
│   │           │   │   ├── link_to_leagcy_iptables.sh
│   │           │   │   └── set_root_password.sh
│   │           │   └── ubuntu_lxde
│   │           │       ├── apt_audio_video.sh
│   │           │       ├── apt_blueman.sh
│   │           │       ├── apt_install_base.sh
│   │           │       ├── apt_lxde_desktop.sh
│   │           │       ├── apt_wifi_ble.sh
│   │           │       ├── create_rzpi_user.sh
│   │           │       ├── set_root_password.sh
│   │           │       ├── set_swap_enable.sh
│   │           │       └── setup-set-permissions.sh
│   │           └── setup_ubuntu_environment.sh
│   └── tools
│       ├── bootloader-flasher
│       │   ├── linux
│       │   │   ├── bootloader_flash.py
│       │   │   └── Readme.md
│       │   ├── Readme.md
│       │   └── windows
│       │       ├── config.ini
│       │       ├── flash_bootloader.bat
│       │       ├── Readme.md
│       │       └── tools
│       │           ├── cygterm.cfg
│       │           ├── flash_bootloader.ttl
│       │           ├── TERATERM.INI
│       │           ├── ttermpro.exe
│       │           ├── ttpcmn.dll
│       │           ├── ttpfile.dll
│       │           ├── ttpmacro.exe
│       │           ├── ttpset.dll
│       │           └── ttxssh.dll
│       ├── Readme.md
│       ├── sd-creator
│       │   ├── linux
│       │   │   ├── Readme.md
│       │   │   └── sd_flash.sh
│       │   ├── Readme.md
│       │   └── windows
│       │       ├── config.ini
│       │       ├── flash_filesystem.bat
│       │       ├── Readme.md
│       │       └── tools
│       │           ├── AdbWinApi.dll
│       │           ├── cygterm.cfg
│       │           ├── fastboot.bat
│       │           ├── fastboot.exe
│       │           ├── flash_system_image.ttl
│       │           ├── TERATERM.INI
│       │           ├── ttermpro.exe
│       │           ├── ttpcmn.dll
│       │           ├── ttpfile.dll
│       │           ├── ttpmacro.exe
│       │           ├── ttpset.dll
│       │           └── ttxssh.dll
│       └── uload-bootloader
│           ├── linux
│           │   ├── Readme.md
│           │   └── uload_bootloader_flash.py
│           ├── Readme.md
│           └── windows
│               ├── config.ini
│               ├── Readme.md
│               ├── tools
│               │   ├── cygterm.cfg
│               │   ├── TERATERM.INI
│               │   ├── ttermpro.exe
│               │   ├── ttpcmn.dll
│               │   ├── ttpfile.dll
│               │   ├── ttpmacro.exe
│               │   ├── ttpset.dll
│               │   ├── ttxssh.dll
│               │   └── uload-flash_bootloader.ttl
│               └── uload-flash_bootloader.bat
├── license
│   ├── Disclaimer051.pdf
│   └── Disclaimer052.pdf
├── r11qs0062eu0110-rz-srp-yocto3-um-quick-start-guide.pdf
├── r12uz0177eu0110-rz-srp-yocto3-um.pdf
├── README.md
├── RZ_System_Release_Package_Evaluation_license.pdf
└── target
    ├── env
    │   ├── Readme.md
    │   └── uEnv.txt
    ├── images
    │   ├── bl2_bp-rzpi.bin
    │   ├── bl2_bp-rzpi.srec
    │   ├── bl2-rzpi.bin
    │   ├── core-image-bsp-rzpi.wic
    │   ├── core-image-minimal-rzpi.wic
    │   ├── core-image-qt-rzpi.wic
    │   ├── core-image-weston-rzpi.wic
    │   ├── dtbs
    │   │   ├── overlays
    │   │   │   ├── Readme.md
    │   │   │   ├── rzpi-can.dtbo
    │   │   │   ├── rzpi-dsi.dtbo
    │   │   │   ├── rzpi-ext-i2c.dtbo
    │   │   │   ├── rzpi-ext-spi.dtbo
    │   │   │   └── rzpi-ov5640.dtbo
    │   │   ├── Readme.md
    │   │   ├── rzpi--5.10.184-cip36+gitAUTOINC+ad250e7c25-r1-rzpi-20250515120636.dtb
    │   │   └── rzpi.dtb -> rzpi--5.10.184-cip36+gitAUTOINC+ad250e7c25-r1-rzpi-20250515120636.dtb
    │   ├── fip-rzpi.bin
    │   ├── fip-rzpi.srec
    │   ├── Flash_Writer_SCIF_rzpi.mot
    │   ├── Image -> Image--5.10.184-cip36+gitAUTOINC+ad250e7c25-r1-rzpi-20250515120636.bin
    │   ├── Image--5.10.184-cip36+gitAUTOINC+ad250e7c25-r1-rzpi-20250515120636.bin
    │   ├── Readme.md
    │   ├── renesas-core-image-cli-rzpi.wic
    │   ├── renesas-core-image-weston-rzpi.wic
    │   ├── renesas-quickboot-cli-rzpi.wic
    │   ├── renesas-quickboot-wayland-rzpi.wic
    │   ├── rootfs
    │   │   ├── core-image-bsp-rzpi.tar.bz2
    │   │   ├── core-image-minimal-rzpi.tar.bz2
    │   │   ├── core-image-qt-rzpi.tar.bz2
    │   │   ├── core-image-weston-rzpi.tar.bz2
    │   │   ├── Readme.md
    │   │   ├── renesas-core-image-cli-rzpi.tar.bz2
    │   │   ├── renesas-core-image-weston-rzpi.tar.bz2
    │   │   ├── renesas-quickboot-cli-rzpi.tar.bz2
    │   │   ├── renesas-quickboot-wayland-rzpi.tar.bz2
    │   │   ├── renesas-ubuntu-rzpi.tar.bz2
    │   │   ├── ubuntu-core-image-qt-rzpi.tar.bz2
    │   │   └── ubuntu-lxde-image-qt-rzpi.tar.bz2
    │   ├── ubuntu-core-image-qt-rzpi.wic.gz
    │   └── ubuntu-lxde-image-qt-rzpi.wic.gz
    └── Readme.md

44 directories, 216 files

```
## User Manual

The build provides comprehensive documentation of the supported board and all the features in a user manual having the name `rz-g2l-sbc-single-board-computer.pdf`.

> [!IMPORTANT]
> The user manual name is prefixed with an internal code that we use for tracking and version within our systems. The actual filename would have a prefix looking like :
> `xxxxxx-rz-g2l-sbc-single-board-computer.pdf`
>
> The document gets updated with each official release.
