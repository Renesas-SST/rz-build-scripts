# rz-sbc build package

This directory holds the automated build scripts that perform the Ubuntu image builds.

## Hierarchy

```
.
├── config
│   ├── ubuntu_core
│   │   └── network_interfaces.conf
│   └── ubuntu_lxde
│       ├── interfaces
│       ├── lightdm.conf
│       ├── NetworkManager.conf
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
│   │   ├── prepare_ubuntu_base.sh
│   │   └── yocto_working.sh
│   ├── ubuntu_core
│   │   ├── mount.sh
│   │   ├── prepare_conf.sh
│   │   ├── prepare_env.sh
│   │   └── prepare_rootfs_qt.sh
│   └── ubuntu_lxde
│       ├── create_swap.sh
│       ├── mount.sh
│       ├── prepare_conf.sh
│       └── prepare_rootfs_qt.sh
├── README.md
├── rzsbc_ubuntu.sh
└── script
    ├── ubuntu_core
    │   ├── apt_install_base.sh
    │   └── set_root_password.sh
    └── ubuntu_lxde
        ├── apt_audio_video.sh
        ├── apt_blueman.sh
        ├── apt_install_base.sh
        ├── apt_lxde_desktop.sh
        ├── apt_wifi_ble.sh
        ├── create_rzpi_user.sh
        ├── set_root_password.sh
        ├── set_swap_enable.sh
        └── setup-set-permissions.sh

15 directories, 66 files

``` 

## Organization:

| File                 | Description                                                                                                                                                     |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| config/       | The folder that holds configuration files for different Ubuntu variants.                                                                                    |
| docs/             | Contains documentation detailing supported features and usage instructions for each Ubuntu image variant.                                                      |
| script/       | The folder that contains all scripts related to Ubuntu image creation.                                                                                          |
| rzsbc_ubuntu.sh | Custom Ubuntu build script that automates the setup, configuration, and creation of Ubuntu-based images (e.g., Ubuntu Core, Ubuntu LXDE) for the RZ/G2L-SBC.  |
| config.ini            | Configuration file that defines key parameters for the Ubuntu image build process, such as the Ubuntu variant, base image, output filenames, and system settings.|
| README.md            | This README (the current document).|

## Ubuntu Build

You can perform the Ubuntu build right here or by moving this directorys contents to your chosen location.
To perform Ubuntu build with all RZ SoC's IP's functioning, you must first build the Yocto environment. This step is necessary to collect essential binary artifacts that will be reused during the Ubuntu image build process.

### Required Components

Before running the Ubuntu build, download the following ZIP files from the Renesas website after accepting their click-through license agreements. These packages contain proprietary GPU and codec drivers necessary for full hardware support.

| File                             |   Description                                                                                                                |
|----------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| RTK0EF0045Z13001ZJ-v1.1.2_EN.zip | RZ Mali GPU driver and HAL package.  |
| RTK0EF0045Z15001ZJ-v1.1.0_EN.zip | RZ codec driver and HAL package.    |

> [!IMPORTANT]
> Place the downloaded ZIP files into the `yocto/` directory before building.
> Simply running the script `rzsbc_ubuntu.sh` will tell you the command options.
> Use the script with the `ubuntu-lxde`, `ubuntu-core`, or `all-ubuntu-images` parameter to build the corresponding images. For example, run `sudo rzsbc_ubuntu.sh all-ubuntu-images` to build both images.

> [!IMPORTANT]
> Please ensure that you are making this build in an Ubuntu 20.04 OS environment through docker/VM/native-OS installations.

Run the build script and it will take care of everything else.

For more details on each Ubuntu image, please refer to its README:
- Ubuntu core: `docs/ubuntu_core/README.md`
- Ubuntu LXDE: `docs/ubuntu_lxde/README.md`

## User configuration (config.ini)
### User Account Settings

Both Ubuntu Core and Ubuntu LXDE images support setting up a non-root user account via the `config.ini` file. This is necessary because desktop environments like LXDE cannot run as the root user.

To configure the default user credentials, edit the following entries in `config.ini`:

```shell
USERNAME=rzpi
PASSWORD=1
```

> [!IMPORTANT]
> These credentials will be used in the generated image, and are required for login..
> Update them before the build if you require a different user or stronger security.
