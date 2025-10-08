# RZ Build Package

This directory contains automated build scripts and resources for performing Yocto and Ubuntu builds for the RZ platforms.

## Hierarchy

```
$ tree -L 3
.
├── config.json
├── files_to_add
│   └── meta-rz-features
│       ├── 0001-rzg2l-sbc-Bring-compat_alloc_user_space-back.patch
│       └── 0004-rzg2l-sbc-Get-interrupt-number.patch
├── git_patch.json
├── jq-linux-amd64
├── patches
│   ├── meta-rz-features
│   │   └── 0001-support-codec-for-linux-6.10-and-yocto-styhead.patch
│   ├── meta-summit-radio
│   │   ├── 0001-rz-sbc-meta-summit-radio-Support-build-in-yocto-styh.patch
│   │   └── 0002-rz-sbc-summit-radio-support-eSDK-build.patch
│   └── poky
│       └── 0001-uboot-config-Fix-devtool-modify.patch
├── README.md
├── rz_builder.sh
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
    ├── script
    │   ├── common
    │   ├── ubuntu_core
    │   └── ubuntu_lxde
    └── setup_ubuntu_environment.sh

21 directories, 13 files

``` 

## Organization:

| File                 | Description                                                                                                                                                     |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| git_patch.json        | Contains json keys and repository configuration such as: url, branch, tag, commit, repo type and patch paths to apply.                                          |
| config.json           | Contains the config options including available build image options grouped by build type, including Yocto images, Ubuntu images, and static image collections (all-yocto-images, all-ubuntu-images, all-supported-images).|
| jq-linux-amd64        | JSON querry oss binary to perform reads of git_patch.json from shell script.                                                                                    |
| patches/              | Folder containing patches. This should ideally be organized into sub directories named after the json key.                                                      |
| files_to_add/              | A folder containing additional files that need to be added to the meta layer. These files are specified in the `add_files` field of `git_patch.json`, which defines their source locations and target destinations. For example: <br><br>**meta-rz-features/** <br>• 0001-rzg2l-sbc-Bring-compat_alloc_user_space-back.patch<br>• 0004-rzg2l-sbc-Get-interrupt-number.patch|
| rz_builder.sh      | The main build script that performs setup, configuration, and build operations for both Ubuntu and Yocto build processes.                                       |
| site.conf [optional]  | An optional overrride site.conf. If present, this will be used as the override file. If not, the template conf site.conf will be used from meta-renesas layer.  |
| ubuntu/               | Directory containing files and scripts related to building Ubuntu-based images for the platform, supporting variants such as ubuntu_core and ubuntu_lxde.  |
| README.md             | This document. This document provides an overview of the rz-sbc build package. It serves as a guide for users to understand how to set up and execute the Yocto build process, as well as how to manage and utilize the build artifacts and patches.|

## Image Categories

The `config.json` file contains the list of available build options such as machine types and image options categorized by build system and image groups meant for the build script to verify against.

The user can use this config in three ways:

    1. Read it to check available options.
    2. Alter the lists and values to control the build with changed defaults
    3. Alter the lists to build new user images without changing any build code. 

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

Only categories and images that are actively supported and integrated in the build process are included in `config.json`. Others might not exist yet or aren’t supported.

It also lists the available `machine` types

- **machine**: Lists the available target machine:
    - `rz-cmn` : This is the default target and is meant for common platform support.
    - `rzg2l-sbc`: Legacy machine that supports the reference RZ/G2L-SBC.

- **defaults**: Lists the default options for differnt parameters.
    - `machine` : Specify the default machine chosen when no machine is passed as arguement.
    - `image` : Specify the default image to build where none is specified.

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
> Simply running the script `rz_builder.sh` will tell you the command options.
> Running the script with `build` parameter (`rz_builder.sh build`) will give you the download url's of the missing packages.

> [!IMPORTANT]
> Please ensure that you are making this build in an ubuntu 24.04 OS environment through docker/VM/native-OS installations.

Once you download the packages, place the zip files here.
Then rerun the build script and it will take care of everything else.

## Build output

The following output is an example of the build artifacts generated for the `all-supported-images` target. These images will be located in the `tmp/deploy/images/<machine_name>/` directory within your Yocto build folder. If you use the default build location and run the script with only the `build` argument, the images will be found at `yocto_rzcmn_board/build/tmp/deploy/images/<machine_name>/`

```
renesas@builder-pc:~/renesas/rz-cmn-srp/yocto_rzcmn_board/build/tmp/deploy/images/rz-cmn$ tree
.
├── host
│   ├── build
│   │   ├── <image-name>-<timestamp>.rootfs.manifest
│   │   ├── <image-name>-<timestamp>.testdata.json
│   │   ├── <image-name>.manifest -> <image-name>-<timestamp>.rootfs.manifest
│   │   └── <image-name>.testdata.json -> <image-name>-<timestamp>.testdata.json
│   ├── env
│   │   ├── core-image-bsp.env
│   │   ├── core-image-minimal.env
│   │   ├── core-image-weston.env
│   │   ├── Readme.md
│   │   ├── renesas-core-image-cli.env
│   │   ├── renesas-core-image-weston.env
│   │   ├── renesas-quickboot-cli.env
│   │   └── renesas-quickboot-wayland.env
│   ├── Readme.md
│   ├── src
│   │   └── rz-cmn-srp
│   │       ├── config.json
│   │       ├── files_to_add
│   │       │   └── meta-rz-features
│   │       │       ├── 0001-rzg2l-sbc-Bring-compat_alloc_user_space-back.patch
│   │       │       └── 0004-rzg2l-sbc-Get-interrupt-number.patch
│   │       ├── git_patch.json
│   │       ├── jq-linux-amd64
│   │       ├── patches
│   │       │   ├── poky
│   │       │   │   └── 0001-uboot-config-Fix-devtool-modify.patch
│   │       │   ├── meta-rz-features
│   │       │   │   └── 0001-support-codec-for-linux-6.10-and-yocto-styhead.patch
│   │       │   └── meta-summit-radio
│   │       │       ├── 0001-rz-sbc-meta-summit-radio-Support-build-in-yocto-styh.patch
│   │       │       └── 0002-rz-sbc-summit-radio-support-eSDK-build.patch
│   │       ├── README.md
│   │       ├── rz_builder.sh
│   │       └── ubuntu
│   │           ├── config
│   │           │   ├── ubuntu_core
│   │           │   │   ├── audio-init-core.sh
│   │           │   │   ├── network_interfaces.conf
│   │           │   │   ├── NetworkManager.conf
│   │           │   │   └── resolved.conf
│   │           │   └── ubuntu_lxde
│   │           │       ├── audio-init-lxde.sh
│   │           │       ├── connman-gtk.desktop
│   │           │       ├── force-display-xorg.sh
│   │           │       ├── force-xorg-display.service
│   │           │       ├── interfaces
│   │           │       ├── lightdm.conf
│   │           │       ├── NetworkManager.conf
│   │           │       ├── panel
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
│   │           │       │   ├── audio_settings.png
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
│   │           │   │   ├── mount.sh
│   │           │   │   ├── prepare_env_rootfs.sh
│   │           │   │   ├── prepare_env.sh
│   │           │   │   ├── prepare_ubuntu_base.sh
│   │           │   │   └── yocto_working.sh
│   │           │   ├── ubuntu_core
│   │           │   │   ├── prepare_conf.sh
│   │           │   │   ├── prepare_env.sh
│   │           │   │   ├── prepare_rootfs.sh
│   │           │   │   └── setup_dns.sh
│   │           │   └── ubuntu_lxde
│   │           │       ├── create_swap.sh
│   │           │       ├── prepare_conf.sh
│   │           │       └── prepare_rootfs_qt.sh
│   │           ├── README.md
│   │           ├── script
│   │           │   ├── common
│   │           │   │   ├── dpkg-install-lock-fix.sh
│   │           │   │   └── setup_dns_and_time.sh
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
│   │           │       ├── create_user.sh
│   │           │       ├── enable_service.sh
│   │           │       ├── set_root_password.sh
│   │           │       ├── set_swap_enable.sh
│   │           │       └── setup-set-permissions.sh
│   │           └── setup_ubuntu_environment.sh
│   └── tools
│       ├── bin
│       │   ├── linux
│       │   │   ├── bpgen
│       │   │   ├── fiptool
│       │   │   └── Readme.md
│       │   ├── Readme.md
│       │   └── windows
│       │       ├── bpgen.exe
│       │       ├── fiptool.exe
│       │       └── Readme.md
│       ├── bootloader_flasher
│       │   ├── bootloader_flash.py
│       │   └── README.md
│       ├── config
│       │   ├── boards_flash_config.toml
│       │   └── README.md
│       ├── firmware_compile
│       │   ├── firmware_compile.py
│       │   └── Readme.md
│       ├── flash_images.json
│       ├── README.md
│       ├── sd_creator
│       │   ├── README.md
│       │   ├── sd_flash.py
│       │   └── tools
│       │       ├── AdbWinApi.dll
│       │       └── fastboot.exe
│       ├── uload_bootloader
│       │   ├── README.md
│       │   └── uload_bootloader_flash.py
│       └── universal_flash.py
├── license
│   └── Disclaimer051.pdf
├── <code>-rz-cmn-srp-um-quick-start-guide.pdf
├── <code>-rz-cmn-srp-um.pdf
├── README.md
├── RZ_System_Release_Package_Evaluation_license.pdf
└── target
    ├── env
    │   ├── Readme.md
    │   └── uEnv.txt
    ├── images
    │   ├── atf
    │   │   ├── bl2-rz-cmn.bin
    │   │   ├── bl31-rz-cmn.bin
    │   │   ├── fdts
    │   │   │   ├── <board-name>.dtb
    │   │   │   └── Readme.md
    │   │   └── Readme.md
    │   ├── core-image-bsp.wic
    │   ├── core-image-minimal.wic
    │   ├── core-image-weston.wic
    │   ├── Flash_Writer_SCIF_<board-name>.mot
    │   ├── Flash_Writer_SCIF_<board-name>_PMIC.mot
    │   ├── linux
    │   │   ├── dtbs
    │   │   │   ├── overlays
    │   │   │   │   ├── Readme.md
    │   │   │   │   ├── rzg2l-sbc-can.dtbo
    │   │   │   │   ├── rzg2l-sbc-dsi.dtbo
    │   │   │   │   ├── rzg2l-sbc-ext-i2c.dtbo
    │   │   │   │   ├── rzg2l-sbc-ext-spi.dtbo
    │   │   │   │   └── rzg2l-sbc-ov5640.dtbo
    │   │   │   ├── <board-name>--<kernel-version>-rz-cmn-<timestamp>.dtbo
    │   │   │   ├── <board-name>.dtb -> <board-name>--<kernel-version>-rz-cmn-<timestamp>.dtbo
    │   │   │   └── Readme.md
    │   │   ├── Image -> Image--<kernel-version>-rz-cmn-<timestamp>.bin
    │   │   ├── Image--<kernel-version>-rz-cmn-<timestamp>.bin
    │   │   └── Readme.md
    │   ├── Readme.md
    │   ├── renesas-core-image-cli.wic
    │   ├── renesas-core-image-weston.wic
    │   ├── renesas-quickboot-cli.wic
    │   ├── renesas-quickboot-wayland.wic
    │   ├── rootfs
    │   │   ├── core-image-bsp.tar.bz2
    │   │   ├── core-image-minimal.tar.bz2
    │   │   ├── core-image-weston.tar.bz2
    │   │   ├── Readme.md
    │   │   ├── renesas-core-image-cli.tar.bz2
    │   │   ├── renesas-core-image-weston.tar.bz2
    │   │   ├── renesas-quickboot-cli.tar.bz2
    │   │   └── renesas-quickboot-wayland.tar.bz2
    │   ├── <board>-<version>-platform-settings.bin
    │   ├── <board>-<version>-platform-settings.srec
    │   └── u-boot
    │       ├── dtbs
    │       │   ├── Readme.md
    │       │   └── <board-name>.dtb
    │       ├── Readme.md
    │       └── u-boot-nodtb-rz-cmn.bin
    └── Readme.md
```
## User Manual

The build provides comprehensive documentation of the supported board and all the features in a user manual having the name `rz-cmn-srp-um.pdf`.

> [!IMPORTANT]
> The user manual name is prefixed with an internal code that we use for tracking and version within our systems. The actual filename would have a prefix looking like :
> `xxxxxx-rz-cmn-srp-um.pdf`
>
> The document gets updated with each official release.
