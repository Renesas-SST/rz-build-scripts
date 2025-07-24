# rz-build-scripts
Build scripts for rz projects

This repository holds scripts to build various Linux-based systems for RZ platforms. It supports both Yocto-based and Ubuntu-based images.

## Hierarchy

```
$ tree -L 3
.
├── README.md                   <---- Top-level documentation (this file)
└── rz-cmn-srp/                 <---- Main build logic and scripts
    ├── files_to_add/		<---- Additional files to be copied into build environment.
    │   └── meta-rz-features/
    ├── README.md               <---- Detailed guide for Ubuntu and Yocto builds.
    ├── rz_builder.sh        <---- Unified entry point for both Yocto and Ubuntu builds
    ├── git_patch.json          <---- JSON definitions for managing repositories and patches
    ├── images.json             <---- Image definitions grouped by build type
    ├── jq-linux-amd64          <---- Local copy of `jq` for JSON processing
    ├── site.conf               /* (optional) */
    ├── patches/                <---- Patch sets organized by target layer
    │   ├── meta-summit-radio/
    │   └── meta-rz-features/
    └── ubuntu/                 <---- Ubuntu-specific configuration and scripts
        ├── config
        ├── config.ini          <---- User configuration file
        ├── docs                <---- Documentation specific to Ubuntu-LXDE and Ubuntu-core
        ├── include             <---- Header files
        ├── README.md           <---- Detailed guide for Ubuntu builds
        ├── script              <---- Ubuntu-related scripts
        └── setup_ubuntu_environment.sh         <---- Script sourced by main builder to prepare Ubuntu environment
11 directories, 9 files
```

## Build Systems Overview

The unified build script `rz_builder.sh` located in the `rz-cmn-srp` folder manages both Yocto and Ubuntu build workflows.

### Yocto

The Yocto build workflow is handled through `rz_builder.sh`, which configures and executes all Yocto-specific tasks.

#### JQuerry

The build script `rz_builder.sh` uses the open-source tool jq (https://jqlang.github.io/jq/) to process JSON data, enabling efficient management of off-tree patching and configuration.

#### Patching

The general idea is to avoid patches and keep things within the repositories.
In some cases release builds need specific tweaks to work with the infrastructure or environement.
In some cases we have to patch a third party repository.
In such rare cases, patches are held here and applied during build.

#### Patch Management Feature

The build script includes functionality to detect and apply new patches as they are added. This allows the script to adapt to evolving project needs without manual intervention for each build. This feature is designed to ensure that any necessary fixes or updates are automatically integrated, keeping the build process efficient and up to date.

### Ubuntu

Ubuntu-related build logic and configurations reside under the `rz-cmn-srp/ubuntu/` directory. The unified build script `rz_builder.sh` also manages Ubuntu image creation by sourcing the necessary environment setup scripts and executing Ubuntu-specific workflows.

This repository supports building two Ubuntu image types for RZ boards:
- ubuntu-core: A minimal, headless Ubuntu image tailored for embedded systems. It includes Qt framework support for developing Qt-based applications in a resource-efficient environment.
- Ubuntu LXDE: A lightweight Ubuntu image featuring the LXDE desktop environment, providing a graphical interface while maintaining low resource consumption. This image also includes Qt framework support for GUI development.

> [!IMPORTANT]
> Refer to the README in `rz-cmn-srp` folder to understand the usage and configuration specific to each build system.
