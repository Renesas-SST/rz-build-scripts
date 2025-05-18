# rz-build-scripts
Build scripts for rz projects

This repository holds scripts to build various Linux-based systems for RZ platforms. It supports both Yocto-based and Ubuntu-based images.

## Hierarchy

```
.
├── README.md
├── ubuntu
│   ├── config
│   │   ├── ubuntu_core
│   │   │   └── network_interfaces.conf
│   │   └── ubuntu_lxde
│   │       ├── interfaces
│   │       ├── lightdm.conf
│   │       ├── NetworkManager.conf
│   │       ├── rsyslog
│   │       ├── ttyS0.conf
│   │       └── v4l2-init.sh
│   ├── config.ini
│   ├── docs
│   │   ├── ubuntu_core
│   │   │   └── README.md
│   │   └── ubuntu_lxde
│   │       ├── Pictures
│   │       │   ├── audacity.png
│   │       │   ├── bluetooth_0.png
│   │       │   ├── bluetooth_1.png
│   │       │   ├── bluetooth_2.png
│   │       │   ├── bluetooth_3.png
│   │       │   ├── bluetooth_4.png
│   │       │   ├── csi_0.png
│   │       │   ├── csi_1.png
│   │       │   ├── csi_2.png
│   │       │   ├── eth_1.png
│   │       │   ├── eth_2.png
│   │       │   ├── eth_3.png
│   │       │   ├── eth_4.png
│   │       │   ├── eth_5.png
│   │       │   ├── eth.png
│   │       │   ├── save_audio_0.png
│   │       │   ├── save_audio_1.png
│   │       │   ├── save_audio_2.png
│   │       │   ├── vlc_open_0.png
│   │       │   ├── vlc_open_1.png
│   │       │   ├── vlc_open_2.png
│   │       │   ├── vlc.png
│   │       │   ├── vlc_video_1.png
│   │       │   ├── vlc_video.png
│   │       │   ├── web_1.png
│   │       │   ├── web_2.png
│   │       │   ├── web_lxterm_htop.png
│   │       │   ├── web.png
│   │       │   └── wifi_0.png
│   │       └── README.md
│   ├── include
│   │   ├── common
│   │   │   ├── allow_empty_password.sh
│   │   │   ├── create_wic.sh
│   │   │   ├── install_gstreamer.sh
│   │   │   ├── install_weston.sh
│   │   │   ├── prepare_ubuntu_base.sh
│   │   │   └── yocto_working.sh
│   │   ├── ubuntu_core
│   │   │   ├── mount.sh
│   │   │   ├── prepare_conf.sh
│   │   │   ├── prepare_env.sh
│   │   │   └── prepare_rootfs_qt.sh
│   │   └── ubuntu_lxde
│   │       ├── create_swap.sh
│   │       ├── mount.sh
│   │       ├── prepare_conf.sh
│   │       └── prepare_rootfs_qt.sh
│   ├── README.md
│   ├── setup_ubuntu_environment.sh
│   └── script
│       ├── ubuntu_core
│       │   ├── apt_install_base.sh
│       │   └── set_root_password.sh
│       └── ubuntu_lxde
│           ├── apt_audio_video.sh
│           ├── apt_blueman.sh
│           ├── apt_install_base.sh
│           ├── apt_lxde_desktop.sh
│           ├── apt_wifi_ble.sh
│           ├── create_rzpi_user.sh
│           ├── set_root_password.sh
│           ├── set_swap_enable.sh
│           └── setup-set-permissions.sh
└── yocto
    ├── git_patch.json
    ├── jq-linux-amd64
    ├── patches
    │   ├── meta-summit-radio
    │   │   ├── 0001-rzsbc-summit-radio-pre-3.4-support-eSDK-build.patch
    │   │   └── 0002-rzsbc-summit-radio-pre-3.4-enable-usb-bt-support.patch
    │   └── poky
    │       └── 0001-meta-classes-esdk-explicitly-address-the-location-of.patch
    ├── README.md
    └── rzsbc_yocto.sh

20 directories, 74 files
```

## Yocto

All Yocto-related scripts and patches are located in the yocto/ folder.

### JQuerry

This script uses jqerry open source project to manage off tree patching (https://jqlang.github.io/jq/).

### Patching

The general idea is to avoid patches and keep things within the repositories.
In some cases release builds need specific tweaks to work with the infrastructure or environement.
In some cases we have to patch a third party repository.
In such rare cases, patches are held here and applied during build.

### Patch Management Feature

The build script includes functionality to detect and apply new patches as they are added. This allows the script to adapt to evolving project needs without manual intervention for each build. This feature is designed to ensure that any necessary fixes or updates are automatically integrated, keeping the build process efficient and up to date.

## Ubuntu

All Ubuntu-related build logic is located in the ubuntu/ directory.

This repository also provides scripts and configurations to build Ubuntu-based images for RZ/G2L-SBC. It supports two image types:
- ubuntu-core: A minimal, headless Ubuntu image tailored for embedded systems. It includes Qt framework support for developing Qt-based applications in a resource-efficient environment.
- Ubuntu LXDE: A lightweight Ubuntu image featuring the LXDE desktop environment, providing a graphical interface while maintaining low resource consumption. This image also includes Qt framework support for GUI development.

> [!IMPORTANT]
> Refer to the README in each folder (ubuntu/ or yocto/) to understand the usage and configuration specific to each build system.
