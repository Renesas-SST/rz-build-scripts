# RZ Common System Ubuntu build package

This directory (ubuntu/) provides an organized framework to create Ubuntu-based images (e.g., Ubuntu Core, Ubuntu LXDE) for Renesas RZ boards. The main script acts as a controller that **includes and invokes modular scripts** to perform image creation tasks.

## Hierarchy

```
ubuntu/
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
``` 

## Organization:

| File                 | Description                                                                                                                                                     |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| config/       | The folder that holds configuration files for different Ubuntu variants.                                                                                    |
| include/       | Contains scripts related to Ubuntu (e.g., for creating WIC files, packaging the root filesystem, preparing the environment, etc.) |
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
