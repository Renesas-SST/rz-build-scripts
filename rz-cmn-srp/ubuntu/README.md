# rz-sbc build package

This directory (ubuntu/) provides an organized framework to create Ubuntu-based images (e.g., Ubuntu Core, Ubuntu LXDE) for Renesas RZ boards. The main script acts as a controller that **includes and invokes modular scripts** to perform image creation tasks.

## Hierarchy

```
.
├── config
│   ├── ubuntu_core
│   │   ├── audio-init-core.sh
│   │   ├── network_interfaces.conf
│   │   ├── NetworkManager.conf
│   │   └── resolved.conf
│   └── ubuntu_lxde
│       ├── audio-init-lxde.sh
│       ├── connman-gtk.desktop
│       ├── force-display-xorg.sh
│       ├── force-xorg-display.service
│       ├── interfaces
│       ├── lightdm.conf
│       ├── NetworkManager.conf
│       ├── panel
│       ├── rsyslog
│       ├── ttyS0.conf
│       └── v4l2-init.sh
├── config.ini
├── docs
│   ├── ubuntu_core
│   │   └── README.md
│   └── ubuntu_lxde
│       ├── Pictures
│       │   ├── audacity.png
│       │   ├── audio_settings.png
│       │   ├── bluetooth_0.png
│       │   ├── bluetooth_1.png
│       │   ├── bluetooth_2.png
│       │   ├── bluetooth_3.png
│       │   ├── bluetooth_4.png
│       │   ├── csi_0.png
│       │   ├── csi_1.png
│       │   ├── csi_2.png
│       │   ├── eth_1.png
│       │   ├── eth_2.png
│       │   ├── eth_3.png
│       │   ├── eth_4.png
│       │   ├── eth_5.png
│       │   ├── eth.png
│       │   ├── save_audio_0.png
│       │   ├── save_audio_1.png
│       │   ├── save_audio_2.png
│       │   ├── vlc_open_0.png
│       │   ├── vlc_open_1.png
│       │   ├── vlc_open_2.png
│       │   ├── vlc.png
│       │   ├── vlc_video_1.png
│       │   ├── vlc_video.png
│       │   ├── web_1.png
│       │   ├── web_2.png
│       │   ├── web_lxterm_htop.png
│       │   ├── web.png
│       │   └── wifi_0.png
│       └── README.md
├── include
│   ├── common
│   │   ├── allow_empty_password.sh
│   │   ├── create_wic.sh
│   │   ├── install_gstreamer.sh
│   │   ├── install_weston.sh
│   │   ├── mount.sh
│   │   ├── prepare_env_rootfs.sh
│   │   ├── prepare_env.sh
│   │   ├── prepare_ubuntu_base.sh
│   │   └── yocto_working.sh
│   ├── ubuntu_core
│   │   ├── prepare_conf.sh
│   │   ├── prepare_env.sh
│   │   ├── prepare_rootfs.sh
│   │   └── setup_dns.sh
│   └── ubuntu_lxde
│       ├── create_swap.sh
│       ├── prepare_conf.sh
│       └── prepare_rootfs_qt.sh
├── README.md
├── script
│   ├── common
│   │   ├── dpkg-install-lock-fix.sh
│   │   └── setup_dns_and_time.sh
│   ├── ubuntu_core
│   │   ├── apt_install_base.sh
│   │   ├── link_to_leagcy_iptables.sh
│   │   └── set_root_password.sh
│   └── ubuntu_lxde
│       ├── apt_audio_video.sh
│       ├── apt_blueman.sh
│       ├── apt_install_base.sh
│       ├── apt_lxde_desktop.sh
│       ├── apt_wifi_ble.sh
│       ├── create_user.sh
│       ├── enable_service.sh
│       ├── set_root_password.sh
│       ├── set_swap_enable.sh
│       └── setup-set-permissions.sh
└── setup_ubuntu_environment.sh
``` 

## Organization:

| File                 | Description                                                                                                                                                     |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| config/       | The folder that holds configuration files for different Ubuntu variants.                                                                                    |
| docs/             | Contains documentation detailing supported features and usage instructions for each Ubuntu image variant.                                                      |
| script/       | The folder that contains all scripts related to Ubuntu image creation.                                                                                          |
| setup_ubuntu_environment.sh | **Main entry-point script** (acts like a dispatcher/header). It sources and sequences logic from the modular scripts under `script/`. It does **not** build anything by itself.|
| config.ini            | Configuration file that defines key parameters for the Ubuntu image build process, such as the Ubuntu variant, base image, output filenames, and system settings.|
| README.md            | This README (the current document).|

## Ubuntu Image Build Overview

This directory contains the resources necessary to prepare for building Ubuntu images. You may use it from this location or move its contents to another directory of your choice.

To build Ubuntu images with full RZ SoC IP support, you must first manually download the required proprietary components. These files are gated behind click-through license agreements.

> [!IMPORTANT]
> The script `setup_ubuntu_environment.sh` is a helper script that prepares the Ubuntu environment and dependencies. It assists the main build process but does not perform the full build itself, which is handled by the `rz_builder.sh` script.
> Please ensure that you are making this build in an Ubuntu 24.04 OS environment through docker/VM/native-OS installations.

For more details on each Ubuntu image, please refer to its README:
- Ubuntu core: docs/ubuntu_core/README.md
- Ubuntu LXDE: docs/ubuntu_lxde/README.md

## User configuration (config.ini)
### User Account Settings

Both Ubuntu Core and Ubuntu LXDE images support setting up a non-root user account via the `config.ini` file. This is necessary because desktop environments like LXDE cannot run as the root user.

To configure the default user credentials, edit the following entries in `config.ini`:

```shell
USERNAME=rz
PASSWORD=1
```

> [!IMPORTANT]
> These credentials will be used in the generated image, and are required for login..
> Update them before the build if you require a different user or stronger security.
