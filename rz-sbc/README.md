# rz-sbc build package

This directory holds the automated build scripts that perform the rz yocto repository builds.

## Hierarchy

```
.
├── git_patch.json
├── jq-linux-amd64
├── patches
│   ├── meta-summit-radio
│   │   ├── 0001-rzsbc-summit-radio-pre-3.4-support-eSDK-build.patch
│   │   └── 0002-rzsbc-summit-radio-pre-3.4-enable-usb-bt-support.patch
│   └── poky
│       └── 0001-meta-classes-esdk-explicitly-address-the-location-of.patch
├── README.md
├── rzsbc_yocto.sh
└── site.conf       /* (optional) */
3 directories, 7 files

``` 

## Organization:

| File                 | Description                                                                                                                                                     |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| git_patch.json       | contains json keys and repository configuration such as: url, branch, tag, commit, repo type and patch paths to apply.                                          |
| jq-linux-amd64       | json querry oss binary to perform reads of git_patch.json from shell script.                                                                                    |
| patches/             | folder containing patches. This should ideally be organized into sub directories named after the json key.                                                      |
| rzsbc_yocto.sh       | main build script that performs setup, configure and build operations.                                                                                          |
| site.conf [optional] | An optional overrride site.conf. If present, this will be used as the override file. If not, the template conf site.conf will be used from meta-renesas layer.  |
| README.md            | This document. This document provides an overview of the rz-sbc build package. It serves as a guide for users to understand how to set up and execute the Yocto build process, as well as how to manage and utilize the build artifacts and patches.|

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
> Simply running the script `rzsbc_yocto.sh` will tell you the command options.
> Running the script with `build` parameter (`rzsbc_yocto.sh build`) will give you the download url's of the missing packages.

> [!IMPORTANT]
> Please ensure that you are making this build in an ubuntu 20.04 OS environment through docker/VM/native-OS installations.

Once you download the packages, place the zip files here.
Then rerun the build script and it will take care of everything else.

## Build output

The final output within your yocto build directory will be under `tmp/deploy/images/rzpi/`. If the default location is chosen and no arguments are passed to the script beyond `build`; the images are under `yocto_rzsbc_board/build/tmp/deploy/images/rzpi/`.

```
.
├── host
│   ├── build
│   │   ├── core-image-qt-rzpi-20240914083354.rootfs.manifest
│   │   ├── core-image-qt-rzpi-20240914083354.testdata.json
│   │   ├── core-image-qt-rzpi.manifest -> core-image-qt-rzpi-20240914083354.rootfs.manifest
│   │   └── core-image-qt-rzpi.testdata.json -> core-image-qt-rzpi-20240914083354.testdata.json
│   ├── Readme.md
│   ├── src
│   │   ├── git_patch.json
│   │   ├── jq-linux-amd64
│   │   ├── README.md
│   │   ├── patches
│   │   │   ├── 0001-meta-classes-esdk-explicitly-address-the-location-of.patch
│   │   │   ├── 0001-rzsbc-summit-radio-pre-3.4-support-eSDK-build.patch
│   │   │   └── 0002-rzsbc-summit-radio-pre-3.4-enable-usb-bt-support.patch
│   │   └── rzsbc_yocto.sh
│   └── tools
│       ├── bootloader-flasher
│       │   ├── linux
│       │   │   ├── bootloader_flash.py
│       │   │   └── Readme.md
│       │   ├── Readme.md
│       │   └── windows
│       │       ├── config.ini
│       │       ├── flash_bootloader.bat
│       │       ├── Readme.md
│       │       └── tools
│       │           ├── cygterm.cfg
│       │           ├── flash_bootloader.ttl
│       │           ├── TERATERM.INI
│       │           ├── ttermpro.exe
│       │           ├── ttpcmn.dll
│       │           ├── ttpfile.dll
│       │           ├── ttpmacro.exe
│       │           ├── ttpset.dll
│       │           └── ttxssh.dll
│       ├── Readme.md
│       ├── sd-creator
│       │   ├── linux
│       │   │   ├── Readme.md
│       │   │   └── sd_flash.sh
│       │   ├── Readme.md
│       │   └── windows
│       │       ├── config.ini
│       │       ├── flash_filesystem.bat
│       │       ├── Readme.md
│       │       └── tools
│       │           ├── AdbWinApi.dll
│       │           ├── cygterm.cfg
│       │           ├── fastboot.bat
│       │           ├── fastboot.exe
│       │           ├── flash_system_image.ttl
│       │           ├── TERATERM.INI
│       │           ├── ttermpro.exe
│       │           ├── ttpcmn.dll
│       │           ├── ttpfile.dll
│       │           ├── ttpmacro.exe
│       │           ├── ttpset.dll
│       │           └── ttxssh.dll
│       └── uload-bootloader
│           ├── linux
│           │   ├── Readme.md
│           │   └── uload_bootloader_flash.py
│           ├── Readme.md
│           └── windows
│               ├── config.ini
│               ├── Readme.md
│               ├── tools
│               │   ├── cygterm.cfg
│               │   ├── TERATERM.INI
│               │   ├── ttermpro.exe
│               │   ├── ttpcmn.dll
│               │   ├── ttpfile.dll
│               │   ├── ttpmacro.exe
│               │   ├── ttpset.dll
│               │   ├── ttxssh.dll
│               │   └── uload-flash_bootloader.ttl
│               └── uload-flash_bootloader.bat
├── license
│   ├── Disclaimer051.pdf
│   └── Disclaimer052.pdf
├── r12uz0158eu0101-rz-g2l-sbc-single-board-computer.pdf
├── README.md
├── RZG2L-SBC_Evaluation_license.pdf
└── target
    ├── env
    │   ├── core-image-qt.env
    │   ├── Readme.md
    │   └── uEnv.txt
    ├── images
    │   ├── bl2_bp-rzpi.bin
    │   ├── bl2_bp-rzpi.srec
    │   ├── bl2-rzpi.bin
    │   ├── core-image-qt-rzpi.wic
    │   ├── dtbs
    │   │   ├── overlays
    │   │   │   ├── Readme.md
    │   │   │   ├── rzpi-can.dtbo
    │   │   │   ├── rzpi-dsi.dtbo
    │   │   │   ├── rzpi-ext-i2c.dtbo
    │   │   │   ├── rzpi-ext-spi.dtbo
    │   │   │   └── rzpi-ov5640.dtbo
    │   │   ├── Readme.md
    │   │   ├── rzpi--5.10.184-cip36+gitAUTOINC+5f065ec41b-r1-rzpi-20240913215704.dtb
    │   │   └── rzpi.dtb -> rzpi--5.10.184-cip36+gitAUTOINC+5f065ec41b-r1-rzpi-20240913215704.dtb
    │   ├── fip-rzpi.bin
    │   ├── fip-rzpi.srec
    │   ├── Flash_Writer_SCIF_rzpi.mot
    │   ├── Image -> Image--5.10.184-cip36+gitAUTOINC+5f065ec41b-r1-rzpi-20240913215704.bin
    │   ├── Image--5.10.184-cip36+gitAUTOINC+5f065ec41b-r1-rzpi-20240913215704.bin
    │   ├── Readme.md
    │   └── rootfs
    │       ├── core-image-qt-rzpi.tar.bz2
    │       └── Readme.md
    └── Readme.md

25 directories, 90 files
```
## User Manual

The build provides comprehensive documentation of the supported board and all the features in a user manual having the name `rz-g2l-sbc-single-board-computer.pdf`.

> [!IMPORTANT]
> The user manual name is prefixed with an internal code that we use for tracking and version within our systems. The actual filename would have a prefix looking like :
> `xxxxxx-rz-g2l-sbc-single-board-computer.pdf`
>
> The document gets updated with each official release.
