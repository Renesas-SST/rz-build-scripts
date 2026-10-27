# Ubuntu GNOME System development on Renesas boards #
This is the quick startup guide for Renesas boards to develop on Ubuntu GNOME (with full GNOME Desktop environment support).

The following sections will describe how to build this custom Ubuntu GNOME image and set up the development environment for all supported Renesas boards.

## Status

This is a Custom Ubuntu GNOME release of the Renesas development product for **R-Car V4H SBC**, **IMDT-V2H-SBC**, **RZ/V2H-EVK**, **RZ/V2H-RDK**, **RZ/G2L-100**, **RZ/G2L-EVK**, **RZ/V2L-EVK**, and **RZ/G2L-SBC**.

This release provides a full GNOME desktop environment running on Wayland with hardware-accelerated graphics using board-specific GPU drivers. It is built on the same Ubuntu Core base, so all common features (package management, networking, SSH, Docker, etc.) are inherited.

**GNOME Desktop Features:**

* GNOME desktop environment running on Wayland
* GDM3 display manager for login and session handling
* Hardware-accelerated graphics using board-specific GPU drivers (PowerVR or Mali Panfrost)
* Runtime GPU detection — a single image works across all supported boards
* Standard GNOME desktop applications (Nautilus file manager, GNOME Terminal, Settings)
* PipeWire audio routing with WirePlumber session management
* Ubuntu Yaru theme (GTK and icons)
* Network Manager GUI for network configuration

**Common Features (inherited from Ubuntu Core):**

* Verified Linux Package (VLP) Yocto build support
* Linux BSP functionality (pinned to the 6.18 baseline per platform)
* Codec libraries supported
* On-board Audio Codec with Stereo Jack Analog Audio IO
* Generic USB Bluetooth framework support
* Bootloader with U-Boot Fastboot UDP enabled
* Network Boot and TFTP support
* Remote Access (SSH, SCP) and Debugging (GDBServer, VSCode, Eclipse)
* Postmortem Analysis via Core Dumps
* Package Management using APT and DPKG
* Docker Installation Support

**Typical Use Cases:**

* Development and evaluation during Renesas SoC bring-up
* GUI application demonstrations, including ROS 2, rviz2, Foxglove Studio, and Chromium
* Rapid prototyping using standard Ubuntu desktop tools
* Customer demonstrations and trade-show displays
* AI and DRP-AI inference visualization alongside DNN workloads
* Desktop-based debugging and configuration

## Porting the Ubuntu File System
### Introduction
Ubuntu-base is the minimum file system officially built by Ubuntu, which includes the Debian package manager. The size of the base package is usually only tens of megabytes, behind which there is the entire ubuntu software repository support. Ubuntu software generally has good stability. Based on Ubuntu-base, Linux software can be installed on demand, with deep customization capabilities, and it is commonly used for embedded rootfs construction.

Several common methods for building embedded file systems include busybox, yocto and buildroot. But Ubuntu offers a convenient and powerful package management system with strong community support, allowing for the installation of new software packages directly through apt-get install. This article describes how to build a complete Ubuntu system based on Ubuntu-base. Ubuntu supports many architectures such as arm, X86, powerpc, ppc, and more. This article is mainly focusing on building a complete ubuntu system based on arm as an example.

Before running the build script, please ensure that this source belongs to a regular user (not root or a privileged user), and the user executing this must have sudo/root privileges.

The `config.ini` file is used for configuring the script that builds an Ubuntu image for ARM systems. It includes essential parameters for partition sizes, the Ubuntu base file, and other configurations needed to create the rootfs and wic image. Here are the parameters that need to be configured before starting the script:
- **UBUNTU_TYPE**: Type of target Ubuntu. Available types are "**CORE**", "**LXDE**", "**GNOME**", and "**ALL**". The "ALL" option will build all Ubuntu types.
- **CLEAN_ALL**: Set to 0 to keep the current build (not recommended).
- **BOOT_SIZE_MB**: Size of the boot partition in MB. It should be larger than 100 MB.
- **WIC_ROOTFS_PARTITION_OVERHEAD_FACTOR**: Overhead factor for the rootfs partition in WIC. Default is 1.3 (30%) is a common default for WIC. Use 1.0 to disable overhead.
- **ROOTFS_INTERNAL_FREE_SPACE_MB**: Default extra *free* space to add *inside* the root filesystem (in MB). This space is available to the user/system after booting.
- **renesas_ubuntu_input_name**: Input rootfs (contains Qt libraries, bootloader, kernel, etc. - generated from Yocto) file name.
- **UBUNTU_BASE_URL**: The primary url to use for landing at the download page.
- **UBUNTU_BASE_URL_FILE_PATTERN**: The regex pattern used to filter out the requisite image file from the download page.
- **UBUNTU_BASE_FILE_PATTERN**: The file pattern used to search for local cdimage archive previously downloaded. It's passed on to a `find` command.
- **UBUNTU_LATEST_IMAGE**: A composite variable that automatically determines the image to download from those available at release page.
- **DOWNLOAD_DIR**: Specify the path to place the downloaded cdimage archive. DOWNLOAD_DIR can be set here but will default to './' during execution if left empty here.
- **LOCAL_FILE**: Short hand variable that points to where the previous cdimage archive might be present.

- **OUTPUT_ROOTFS**: The output file name for the rootfs.
- **OUTPUT_WIC**: The output file name for the wic image.
- **TIME_ZONE_AREA**: The time zone area (e.g., "Asia").
- **TIME_ZONE_CITY**: The time zone city (e.g., "Ho_Chi_Minh").
- **SSH_NO_PASS_LOGIN**: Set to 1 to enable users to log in without a password.
- **IS_WESTON_ENABLE**: Set to 0 to disable the Weston compositor.
- **USERNAME**: The default username for logging into the system (e.g., "rz"). This account is used for user login during system access. GNOME cannot run as root, so a non-root user is required.
- **PASSWORD**: The password associated with the default USERNAME (e.g., "1"). This password is required to authenticate the user during login.

> :memo: **Note:** Host PC with Ubuntu 24.04 is recommended for the build. Prepare environment for building package and local build environment.

Here are the packages preinstalled after running the script:

| **Category**                     | **Package(s)**                                                                    |
|----------------------------------|-----------------------------------------------------------------------------------|
| **Basic Packages**               | dialog, rsyslog, systemd, avahi-daemon, avahi-utils, udhcpc, ssh, vim, net-tools, ethtool, ifupdown, iputils-ping, htop, tree, lrzsz, gpiod, wpasupplicant, kmod, iw, usbutils, memtester, alsa-utils, ufw, sudo, pkg-config |
| **Python3**                      | python3-pip                                                                       |
| **Package manager**              | dpkg                                                                              |
| **Tools**                        | can-utils, i2c-tools, spi-tools                                                  |
| **Wifi & Bluetooth Controllers** | bluez, connman, network-manager, rfkill                                           |
| **Desktop Environment**          | gnome-shell, gnome-session, ubuntu-session, gdm3, mutter, nautilus, gnome-terminal, gnome-control-center |
| **Audio**                        | pipewire-pulse, wireplumber                                                       |
| **Networking GUI**               | network-manager-gnome                                                             |
| **Theme**                        | yaru-theme-gtk, yaru-theme-icon                                                  |


### Hierarchy

```
ubuntu/
├── config
│   ├── common
│   ├── ubuntu_core
│   ├── ubuntu_lxde
│   └── ubuntu_gnome
├── config.ini
├── files_to_add
│   ├── pvr
│   └── pvr-gnome
├── docs
│   ├── ubuntu_core
│   ├── ubuntu_lxde
│   └── ubuntu_gnome
├── include
│   ├── common
│   ├── ubuntu_core
│   ├── ubuntu_lxde
│   └── ubuntu_gnome
├── README.md
├── script
│   ├── common
│   ├── ubuntu_core
│   ├── ubuntu_lxde
│   └── ubuntu_gnome
└── setup_ubuntu_environment.sh
```

**Output folder outline and build process:**

The image build is controlled by the main build script `rz_builder.sh` located at the root of the repository. Running this script initiates the complete build process, producing the output images and root filesystem archives as shown below.

To build the Ubuntu GNOME image, run the main build script with the following command:

```shell
IMAGE=ubuntu-gnome ./rz_builder.sh build
```

```
ubuntu/
├── config
│   ├── common
│   ├── ubuntu_core
│   ├── ubuntu_lxde
│   └── ubuntu_gnome
├── config.ini                                    <---- User configuration
├── files_to_add
│   ├── pvr                                       <---- PowerVR base GPU runtime files
│   └── pvr-gnome                                 <---- GNOME-specific GPU wrappers
├── docs
│   ├── ubuntu_core
│   ├── ubuntu_lxde
│   └── ubuntu_gnome
├── include
│   ├── common
│   ├── ubuntu_core
│   ├── ubuntu_lxde
│   └── ubuntu_gnome
├── README.md                                     <---- The main README
├── renesas-ubuntu.tar.bz2                        <---- Rootfs that generated by yocto
├── setup_ubuntu_environment.sh                   <---- Setup environment for main build script
├── script
│   ├── common
│   ├── ubuntu_core
│   ├── ubuntu_lxde
│   └── ubuntu_gnome
└── ubuntu-base-24.04.<version>-base-arm64.tar.gz

yocto_rzcmn_board/build/tmp/deploy/images/<machine_name>/target/images
├── rootfs
|   └── ubuntu-gnome-image.tar.bz2               <---- Output compressed rootfs
└──  ubuntu-gnome-image.wic.gz                   <---- Output compressed WIC
```

**Note on ubuntu base version**: By default, the scripts fetch the latest available 24.04 point release at build time.

### Build Architecture

The build is orchestrated by `rz_builder.sh` and consists of two stages.

**Stage 1: Yocto Build**

The Yocto stage builds platform-specific artifacts, including:
- Linux kernel
- Device tree blobs (DTBs)
- Kernel modules
- Firmware and board-specific components
- Base Ubuntu integration artifacts, including `renesas-ubuntu.tar.bz2`

**Stage 2: Ubuntu Image Assembly**

The Ubuntu stage:
- Extracts the Yocto-generated artifacts
- Creates an Ubuntu 24.04 ARM64 root filesystem
- Runs package installation inside a QEMU-based ARM64 chroot
- Installs GNOME and desktop components
- Stages the board-specific GPU driver stack (PowerVR runtime files from `files_to_add/`)
- Produces a flashable WIC image

### Other Image Variants

```shell
IMAGE=ubuntu-core  ./rz_builder.sh build   # Headless Ubuntu image variant
IMAGE=ubuntu-lxde  ./rz_builder.sh build   # Lightweight LXDE desktop
IMAGE=ubuntu-gnome ./rz_builder.sh build   # Full GNOME desktop
```

| **Image**        | **Use Case**                                                                     |
|------------------|----------------------------------------------------------------------------------|
| ubuntu-gnome     | Full desktop development, demonstrations, and rich GUI applications              |
| ubuntu-lxde      | Lower-resource desktop usage on memory-constrained platforms                      |
| ubuntu-core      | Headless deployment, inference workloads, services, and server-style use cases    |

### U-boot environment
For more information about the U-Boot environment configuration, please refer to the original documentation provided in the [Renesas-SST/meta-renesas](https://github.com/Renesas-SST/meta-renesas/blob/styhead/rz-cmn/recipes-docs/rz-cmn-readme/files/README.md) layer.

## Graphics Architecture

GNOME uses the Mutter compositor and runs as a Wayland session. Hardware-accelerated rendering depends on the GPU, kernel driver, userspace driver, and display stack available on each platform.

| **Platform**                      | **GPU**            | **Driver**                                          |
|-----------------------------------|--------------------|-----------------------------------------------------|
| R-Car V4H (rcar-v4h-sbc)         | PowerVR GSX        | PowerVR graphics driver with Vulkan-backed rendering |
| IMDT-V2H (imdt-v2h-sbc)          | PowerVR GSX        | PowerVR with Zink/Vulkan translation layer           |
| RZ/V2H (rzv2h-evk, rzv2h-rdk)    | Mali G31           | Open-source Mesa Panfrost driver, native OpenGL ES   |
| RZ/G2L (rzg2l-100, rzg2l-evk, rzg2l-sbc) | Mali G31  | Open-source Mesa Panfrost driver, native OpenGL ES   |
| RZ/V2L (rzv2l-evk)               | Mali G31           | Open-source Mesa Panfrost driver, native OpenGL ES   |

### Runtime GPU Detection

The Ubuntu GNOME image uses a single rootfs that works across all supported boards. At boot time, the `has_pvr_gpu()` function checks `/sys/class/drm/card*/device/driver` for the `pvrsrvkm` driver to determine whether the board has a PowerVR GPU. GPU-specific environment variables and wrappers are configured automatically based on the detected GPU.

The `files_to_add/` directory contains the runtime files staged into the rootfs:
- **`pvr/`** — PowerVR base runtime: Vulkan ICD, OpenCL, EGL/GLES libraries, udev rules, GBM backend
- **`pvr-gnome/`** — GNOME-specific wrappers: gnome-shell-wrapper, Xwayland-wrapper, pvr-egl-wrapper, application wrappers (cheese, foxglove, rviz2, chromium), environment generator (`90-pvr-gpu-env`), shim libraries (`libpvr-gnome-shim.so`, `librviz-nomsaa.so`)

## Graphics Benchmark Results

### glmark2-es2-wayland Results

| **Board**       | **GPU**                           | **Score** | **Notes**                                            |
|-----------------|-----------------------------------|-----------|------------------------------------------------------|
| rcar-v4h-sbc    | PowerVR GSX                       | ~800      | Highest measured graphics performance                |
| imdt-v2h-sbc    | PowerVR GSX with Zink/Vulkan path | ~275      | Usable GNOME desktop performance                     |
| rzv2h-evk       | Mali G31 with Panfrost            | ~275      | Usable GNOME desktop performance                     |
| rzv2h-rdk       | Mali G31 with Panfrost            | ~275      | Similar graphics performance to RZ/V2H EVK           |
| rzg2l-100       | Mali G31 with Panfrost            | ~67       | Functional but constrained desktop performance       |
| rzg2l-evk       | Mali G31 with Panfrost            | ~67       | Functional but constrained desktop performance       |
| rzv2l-evk       | Mali G31 with Panfrost            | ~67       | Functional but constrained desktop performance       |
| rzg2l-sbc       | Mali G31 with Panfrost            | ~55       | Lowest measured result; swap is recommended           |

Scores are indicative results under controlled test conditions. They should not be treated as absolute GPU-performance specifications.

### Benchmark Tools

Install the OpenGL ES benchmark packages:

```shell
sudo apt-get update
sudo apt-get install -y glmark2-es2-drm glmark2-es2-wayland
```

### Recommended Test Conditions

For comparable results, use the following conditions:

- Fresh boot
- No user applications running before the test
- GNOME Wayland session
- HDMI display connected at 1920 x 1080
- Same display refresh rate for all boards
- Same image release, kernel, and GPU-driver version
- Same CPU governor where possible
- SD card of comparable class and performance
- Benchmark started after at least 60 seconds of desktop idle time
- Consistent ambient temperature and thermal configuration

For stronger confidence, run each benchmark at least three times and report the average result.

Useful system information to capture with each result:

```shell
free -h
uname -a
cat /sys/devices/system/cpu/cpufreq/policy*/scaling_governor
eglinfo -B    # if installed
```

### Result Interpretation

The measured differences should not be attributed to RAM alone. Desktop performance is affected by:

- GPU architecture and available GPU frequency
- Graphics driver maturity and rendering path
- DRAM bandwidth and memory-controller configuration
- CPU performance, CPU governor, and background load
- Display resolution and refresh rate
- Thermal conditions and power limits
- Storage performance, particularly when swap is used

**R-Car V4H SBC**: Achieves the highest measured score, indicating the strongest graphics performance among the evaluated platforms.

**IMDT-V2H-SBC and RZ/V2H Platforms**: Score approximately 275. This level is generally adequate for a usable GNOME desktop, standard desktop applications, and GUI demonstrations.

**RZ/G2L and RZ/V2L Platforms**: Score approximately 55–67. GNOME remains functional, but the experience is more constrained, particularly during multitasking, web browsing, large application startup, or graphics-heavy workloads.

## Board Suitability

### Recommended for Ubuntu GNOME

| **Board**       | **GPU**                           | **Suitability** | **Notes**                                                         |
|-----------------|-----------------------------------|-----------------|-------------------------------------------------------------------|
| rcar-v4h-sbc    | PowerVR GSX                       | Recommended     | Best measured graphics performance and strongest desktop experience |
| imdt-v2h-sbc    | PowerVR GSX with Zink/Vulkan path | Recommended     | Suitable for full GNOME desktop and GUI demonstrations             |
| rzv2h-evk       | Mali G31 with Panfrost            | Recommended     | Suitable for GNOME desktop evaluation and standard GUI workloads   |
| rzv2h-rdk       | Mali G31 with Panfrost            | Recommended     | Similar suitability to RZ/V2H EVK                                  |

### Usable with Limitations

| **Board**       | **GPU**                | **Suitability**          | **Notes**                                                        |
|-----------------|------------------------|--------------------------|------------------------------------------------------------------|
| rzg2l-100       | Mali G31 with Panfrost | Usable with limitations  | GNOME is functional but desktop responsiveness is limited        |
| rzg2l-evk       | Mali G31 with Panfrost | Usable with limitations  | Better suited to lightweight desktop usage                       |
| rzv2l-evk       | Mali G31 with Panfrost | Usable with limitations  | Better suited to lightweight desktop usage                       |
| rzg2l-sbc       | Mali G31 with Panfrost | Usable with limitations  | Swap is recommended; LXDE is preferred for sustained desktop use |

## Swap Configuration for RZ/G2L SBC

The rzg2l-sbc has a low-memory configuration. GNOME and graphics benchmarks may exceed available physical memory, especially when multiple desktop applications are open.

Enable swap before running graphics benchmarks or using GNOME for extended periods:

```shell
sudo fallocate -l 512M /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

Verify that swap is enabled:

```shell
free -h
```

To enable the swap file automatically after reboot, add the following entry to `/etc/fstab`:

```
/swapfile none swap sw 0 0
```

> :memo: **Note:** Swap on an SD card is slower than RAM and may increase SD-card wear. It is appropriate as an evaluation workaround, but a lighter desktop environment (LXDE) or headless image (Ubuntu Core) is preferred for sustained deployment on low-memory systems.

## Image Selection Matrix

| **Board**       | **ubuntu-gnome**                          | **ubuntu-lxde**                  | **ubuntu-core**                                        |
|-----------------|-------------------------------------------|----------------------------------|--------------------------------------------------------|
| rcar-v4h-sbc    | Recommended                               | Suitable lighter alternative     | Suitable for headless inference and service workloads  |
| imdt-v2h-sbc    | Recommended                               | Suitable lighter alternative     | Suitable for headless inference and service workloads  |
| rzv2h-evk       | Recommended                               | Suitable lighter alternative     | Suitable for headless workloads                        |
| rzv2h-rdk       | Recommended                               | Suitable lighter alternative     | Suitable for headless workloads                        |
| rzg2l-100       | Usable with limitations                   | Recommended for desktop use      | Recommended for headless or production-focused use     |
| rzg2l-evk       | Usable with limitations                   | Recommended for desktop use      | Recommended for headless or production-focused use     |
| rzv2l-evk       | Usable with limitations                   | Recommended for desktop use      | Recommended for headless or production-focused use     |
| rzg2l-sbc       | Usable with limitations; swap recommended | Recommended for desktop use      | Recommended for headless or production-focused use     |

## Decision Guide

**Choose Ubuntu GNOME when:**
- A full Ubuntu desktop environment is required
- The platform has sufficient memory and graphics capability
- The use case includes GUI development, demonstrations, browser-based tools, ROS visualization, or desktop workflows
- Desktop responsiveness is more important than minimum memory footprint

**Choose Ubuntu LXDE when:**
- A graphical desktop is required on a lower-resource platform
- Lower memory usage and faster responsiveness are preferred over the full GNOME feature set
- The target board has limited RAM or a constrained graphics/system-performance profile

**Choose Ubuntu Core (headless) when:**
- No local display or desktop environment is needed
- The system is intended for AI inference, services, automation, or server-style workloads
- Minimal memory use, faster boot, and reduced software footprint are priorities

For quick evaluation or demonstrations, Ubuntu GNOME can be used across all listed boards. However, desktop responsiveness varies substantially by platform. Lower-resource boards should be evaluated with realistic workloads, and swap may be required on the lowest-memory configurations.

## Flashing the Image

Write the generated WIC image to an SD card using `dd` or a GUI utility such as Balena Etcher.

```shell
sudo dd if=ubuntu-gnome-image.wic of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

Replace `/dev/sdX` with the target SD card device.

Use the following command to identify available storage devices:

```shell
lsblk
```

> :warning: **Warning:** `dd` overwrites the selected device without confirmation. Verify the target device carefully before running the command.

## Accessing Supported Features

Ubuntu GNOME inherits all common features from Ubuntu Core. For detailed instructions on the following topics, refer to the [Ubuntu Core README](../ubuntu_core/README.md):

- **Package Management** — APT and DPKG usage, repository configuration
- **Network Boot and TFTP** — TFTP server setup, NFS server setup, U-Boot DHCP configuration, TFTP boot
- **SSH and SCP** — Remote access, key-based authentication, OpenSSH and Dropbear configuration
- **Network Configuration** — Static IP, Netplan configuration, hostname setup
- **Board-specific Features** — GPIO, I2C, SPI, CAN, Wi-Fi, Bluetooth, Audio, MIPI DSI/CSI (RZ/G2L-SBC)
- **BSP Interface** — RZ/G2L, RZ/V2L, and RZ/V2H evaluation kit documentation references

### GNOME Session

The GNOME desktop environment is enabled by default:

- Upon logging in, GDM3 presents the login screen and launches a GNOME Wayland session.
- No manual desktop selection is required.
- The non-root user configured in `config.ini` (default: `rz` / `1`) is used for login.

### Desktop Software Components

| **Component**               | **Package**                      | **Function**                          |
|-----------------------------|----------------------------------|---------------------------------------|
| Display manager             | gdm3                             | Login screen and session launch       |
| Compositor / window manager | gnome-shell / Mutter             | Wayland compositor and window management |
| Session management          | gnome-session, ubuntu-session    | Desktop session lifecycle             |
| File manager                | nautilus                         | File browsing and management          |
| Terminal                    | gnome-terminal                   | Shell access                          |
| Settings                    | gnome-control-center             | System configuration                  |
| Audio                       | pipewire-pulse, wireplumber      | Audio routing and policy management   |
| Networking                  | network-manager-gnome            | GUI network configuration             |
| Theme                       | yaru-theme-gtk, yaru-theme-icon  | Ubuntu visual theme                   |
