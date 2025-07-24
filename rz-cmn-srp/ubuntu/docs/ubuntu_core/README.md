# Ubuntu Core System development on RZ boards #
This is the quick startup guide for RZ boards to develop on Ubuntu headless (no Desktop environment support).

The following sections will describe how to build this custom Ubuntu Core image and set up the development environment for all supported RZ boards.

## Status

This is a Custom Ubuntu Core release of the RZ development product for **RZ/G2L-SBC**, **RZ/G2L-EVK**, **RZ/V2L-EVK** and **RZ/V2H-EVK**.

This release is based on the latest VLP of the Renesas RZ/G2L, RZ/V2L, and RZ/V2H-EVK development products. It provides a comprehensive Linux BSP (Board Support Package) with various features and tools for developing embedded applications on the supported Renesas boards.

**Key Features (Common to most boards unless specified):**

* Verified Linux Package (VLP) Yocto build support
* Linux BSP functionality (based on latest BSP release per platform)
* Codec libraries supported.
* On-board Audio Codec with Stereo Jack Analog Audio IO.
* Generic USB Bluetooth framework support.
* Bootloader with U-Boot Fastboot UDP enabled.
* Network Boot and TFTP support.
* Remote Access (SSH, SCP) and Debugging (GDBServer, VSCode, Eclipse).
* Postmortem Analysis via Core Dumps.
* Package Management using APT and DPKG.
* Docker Installation Support.

## Porting the Ubuntu File System
### Introduction
Ubuntu-base is the minimum file system officially built by Ubuntu, which includes the Debian package manager. The size of the base package is usually only tens of megabytes, behind which there is the entire ubuntu software repository support. Ubuntu software generally has good stability. Based on Ubuntu-base, Linux software can be installed on demand, with deep customization capabilities, and it is commonly used for embedded rootfs construction.

Several common methods for building embedded file systems include busybox, yocto and buildroot. But Ubuntu offers a convenient and powerful package management system with strong community support, allowing for the installation of new software packages directly through apt-get install. This article describes how to build a complete Ubuntu system based on Ubuntu-base. Ubuntu supports many architectures such as arm, X86, powerpc, ppc, and more. This article is mainly focusing on building a complete ubuntu system based on arm as an example.

Before running the build script, please ensure that this source belongs to a regular user (not root or a privileged user), and the user executing this must have sudo/root privileges.

The `config.ini` file is used for configuring the script that builds an Ubuntu image for ARM systems. It includes essential parameters for partition sizes, the Ubuntu base file, and other configurations needed to create the rootfs and wic image. Here are the parameters that need to be configured before starting the script:
- **UBUNTU_TYPE**: Type of target Ubuntu. Available types are "**CORE**", "**LXDE**", and "**ALL**". The "ALL" option will build all Ubuntu types.
- **CLEAN_ALL**: Set to 0 to keep the current build (not recommended).
- **BOOT_SIZE_MB**: Size of the boot partition in MB. It should be larger than 100 MB.
- **WIC_ROOTFS_PARTITION_OVERHEAD_FACTOR**: Overhead factor for the rootfs partition in WIC. Default is 1.3 (30%) is a common default for WIC. Use 1.0 to disable overhead.
- **ROOTFS_INTERNAL_FREE_SPACE_MB**: Default extra *free* space to add *inside* the root filesystem (in MB). This space is available to the user/system after booting.
- **renesas_ubuntu_input_name**: Input rootfs (contains Qt libraries, bootloader, kernel, etc. - generated from Yocto) file name.
- **UBUNTU_BASE_FILE_NAME**: The file name of the Ubuntu base that will be downloaded.
- **UBUNTU_BASE_LINK**: The link to download the Ubuntu base file.
- **OUTPUT_ROOTFS**: The output file name for the rootfs.
- **OUTPUT_WIC**: The output file name for the wic image.
- **TIME_ZONE_AREA**: The time zone area (e.g., "Asia").
- **TIME_ZONE_CITY**: The time zone city (e.g., "Ho_Chi_Minh").
- **SSH_NO_PASS_LOGIN**: Set to 1 to enable users to log in without a password.
- **IS_WESTON_ENABLE**: Set to 0 to disable the Weston compositor.
- **USERNAME**: The default username for logging into the system (e.g., "root"). This account is used for user login during system access.
- **PASSWORD**: The password associated with the default USERNAME (e.g., "1"). This password is required to authenticate the user during login.

> :memo: **Note:** Host PC with Ubuntu 24.04 is recommended for the build. Prepare environment for building package and local build environment.

Here are the packages preinstalled after running the script:

| **Category**                     | **Package(s)**                                                                |
|----------------------------------|-------------------------------------------------------------------------------|
| **Basic Packages**               | dialog, rsyslog, systemd, avahi-daemon, avahi-utils, udhcpc, ssh, vim, net-tools, ethtool, ifupdown, iputils-ping, htop, tree, lrzsz, gpiod, wpasupplicant, kmod, iw, usbutils, memtester, alsa-utils, ufw, sudo, pkg-config|
| **Python3**                      | python3-pip                                                                       |
| **Package manager**              | dpkg                                                                              |
| **Tools**                        | can-utils, i2c-tools, spi-tools                                                   |
| **Wifi & Bluetooth Controllers** | bluez, connman, network-manager, rfkill                                           |


## Hierarchy
```
ubuntu/
├── config
│   ├── ubuntu_core
│   │   ├── network_interfaces.conf
│   │   ├── NetworkManager.conf
│   │   └── resolved.conf
│   └── ubuntu_lxde
│       ├── connman-gtk.desktop
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
│       ├── set_root_password.sh
│       ├── set_swap_enable.sh
│       └── setup-set-permissions.sh
└── setup_ubuntu_environment.sh
```

**Output folder outline:**

The image build is controlled by the main build script `rz_builder.sh` located at the root of the repository. Running this script initiates the complete build process, producing the output images and root filesystem archives as shown below.

To build the Ubuntu Core image, run the main build script with the following command:

```shell
IMAGE=ubuntu-core ./rz_builder.sh build
```

```
├── config
│   ├── ubuntu_core
│   └── ubuntu_lxde
├── config.ini                                   <---- User configuration
├── docs
│   ├── ubuntu_core
│   └── ubuntu_lxde
├── include
│   ├── common
│   ├── ubuntu_core
│   └── ubuntu_lxde
├── README.md                                    <---- The main README
├── renesas-ubuntu.tar.bz2                       <---- Roofs that generated by yocto
├── setup_ubuntu_environment.sh                  <---- Setup environment for main build script
├── script
│   ├── common
│   ├── ubuntu_core
│   └── ubuntu_lxde
└── ubuntu-base-24.04-base-arm64.tar.gz

yocto_rzcmn_board/build/tmp/deploy/images/<machine_name>/target/images
├── rootfs
|   └── ubuntu-core-image.tar.bz2        <---- Output compressed rootfs
└──  ubuntu-core-image.wic.gz            <---- Output compressed WIC
```

### U-boot environment
For more information about the U-Boot environment configuration, please refer to the original documentation provided in the [Renesas-SST/meta-renesas](https://github.com/Renesas-SST/meta-renesas/blob/styhead/rz-cmn/recipes-docs/rz-cmn-readme/files/README.md) layer.

## 4. Accessing Supported Features 

### 4.1. Common Features for All Supported RZ/V2L, RZ/G2L, and RZ/V2H Boards

This section describes features generally supported across Renesas RZ/G2L and RZ/V2L series and RZ/V2H boards. Specific peripheral availability may depend on the board design will introduce later.

#### 4.1.1. Package Management

The distribution comes with Debian package manager `apt-get` and `dpkg` for binary package handling. 

##### 4.1.1.1. Setting up Debian as a backend source
The default configuration for the `sources.list` file, which defines the package repositories, is as follows:

```
deb [arch=arm64] http://ports.ubuntu.com/ oracular main multiverse universe
deb [arch=arm64] http://ports.ubuntu.com/ oracular-security main multiverse universe
deb [arch=arm64] http://ports.ubuntu.com/ oracular-backports main multiverse universe
deb [arch=arm64] http://ports.ubuntu.com/ oracular-updates main multiverse universe
```

##### 4.1.1.2. Configuring the Debian package repository

`sources.list` is a critical configuration file for packages installation and updates used by package managers on Debian-based Linux distributions. The `sources.list` file contains a list of URLs or repository addresses where the package manager can find software packages. These repositories may be maintained by the Linux distribution itself or by third-party individuals or organizations.

The file is located at `/etc/apt/sources.list.d/sources.list`. You can modify it to add or change the repositories according to your needs.

After configuring the APT repositories, refresh the package database by running:

```
root@localhost:~# apt-get update
```

**Please make sure you have internet access before running `apt-get update`.**

This command refreshes the package database and ensures that your system is aware of the latest available packages from the configured repositories.

In the contents of `sources.list` file, you can see `[arch=arm64]` on each line. This is because the RZ's architecture is aarch64, as indicated by the output of the `lscpu` command:

```
root@localhost:~# lscpu
Architecture:                    aarch64
CPU op-mode(s):                  32-bit, 64-bit
Byte Order:                      Little Endian
CPU(s):                          2
...
Vendor ID:                       ARM
```

So we need to specify `[arch=arm64]` in `sources.list` file to filter the binary packages in the repository.

This specification is to limit the existing APT sources to arm64 only, so APT won't try to fetch packages for other architectures from the existing repository.

However, if we use a repository which is already designed for ARM architectures, we don't need to specify `[arch=arm64]`. For example:

```
deb http://deb.debian.org/debian trixie main contrib non-free
```

Remember that sources doesn’t have to be a single origin. It's very common to add multiple repositories and sources for packages and manage them using keys.

The source management is beyond the scope of this document.

##### 4.1.1.3. Using `apt-get` to install packages

To install a package using `apt-get`, use the following command:

```
root@localhost:~# apt-get install <package-name>
```

##### 4.1.1.4. Using `DPKG` to install packages

The utility `dpkg` is the low-level package manager for Debian-based systems. It is the local systemwide package manager. It handles installation, removal, provisioning about package.deb file, indexing and other aspects of packages installed on the system. However, it does not perform any cloud operations. Dpkg also doesn’t handle dependency resolution. This is another task handled by a high-level manager like `apt-get`. In fact, `dpkg` is the backend for `apt-get`. While `apt-get` handles fetching and indexing, the local installations and management of the packages are performed by the `dpkg` manager.

Basic `dpkg` commands:

- `dpkg -i <package.deb>`: Installs a `package.deb` package.
- `dpkg -r <package>`: Removes a package.
- `dpkg -l <pattern>`: Lists installed packages matching `<pattern>`.
- `dpkg -s <package>`: Provides information about an installed package.

You can install `package.deb` using `dpkg` with the following command:

```
root@localhost:~# dpkg -i <package.deb>
```

After installing a package using dpkg, if you need to resolve dependency issues, use the following command:

```
root@localhost:~# apt-get install -f
```

#### 4.1.2. Network Boot and TFTP

This section outlines the process for network booting using TFTP (Trivial File Transfer Protocol). It includes configuration steps and commands necessary for a successful setup.

Network booting allows devices to boot from an image stored on a network server, rather than relying on local storage.

##### 4.1.2.1. TFTP server setup

This subsection covers the setup of a TFTP server, which is necessary for the device to retrieve the boot images over the network.

- Step 1: Install a TFTP server using the following command:

  ```shell
  $ sudo apt update
  $ sudo apt install tftpd-hpa
  ```

- Step 2: Create a TFTP directory and set the appropriate permissions.

  ```shell
  $ sudo mkdir /tftpboot
  $ sudo chmod 755 /tftpboot
  ```

- Step 3: Edit the TFTP configuration file (typically found at /etc/default/tftpd-hpa) and set it up as follows:

  ```shell
  # /etc/default/tftpd-hpa
  TFTP_USERNAME="<tftp_name>"
  TFTP_DIRECTORY="</path/to/your/tftp_folder"
  TFTP_ADDRESS="0.0.0.0:69"
  TFTP_OPTIONS="--secure"
  ```

  For example:
  ```shell
  # /etc/default/tftpd-hpa
  TFTP_USERNAME="tftp"
  TFTP_DIRECTORY="/tftpboot"
  TFTP_ADDRESS="0.0.0.0:69"
  TFTP_OPTIONS="--secure"
  ```

- Step 4: Restart the TFTP service to apply the changes.

  ```shell
  $ sudo systemctl restart tftpd-hpa
  ```

  Make sure the tftpd-hpa service is running:

  ```shell
  $ sudo systemctl status tftpd-hpa
  ```

##### 4.1.2.2. NFS server setup

NFS (Network File System) is a protocol that allows clients to access files over a network as if they were local. It enables multiple clients to share files from a central server, simplifying file management across machines.

In this setup, NFS will share the root filesystem (rootfs) with clients booting over the network. This allows client devices to dynamically retrieve their operating system files and configurations, making it ideal for embedded systems that require consistent file access without local storage.

- Step 1: Install NFS server and NFS client package if it's not already installed on your host PC:
  ```shell
  $ sudo apt update
  $ sudo apt install nfs-kernel-server nfs-common
  ```

- Step 2: Edit the `/etc/exports` file to specify the directories to be shared and their access permissions.
  ```shell
  $ vi /etc/exports
  ```

  For example, to share the `/tftpboot` directory, add the following line:

  ```shell
  /tftpboot *(rw,no_root_squash,async)
  ```

  Here, * allows access from any client. Consider replacing it with specific client IP addresses for better security.

- Step 3: After editing `/etc/exports`, run the following command to export the directories:

  ```shell
  $ sudo exportfs -a
  ```

- Step 4: Start the NFS server and enable it to run at boot:
  ```shell
  $ sudo systemctl start nfs-kernel-server
  $ sudo systemctl enable nfs-kernel-server
  ```

##### 4.1.2.3. U-Boot DHCP IP Configuration

In this subsection, the U-Boot environment will be configured for network settings, including the specification of the Ethernet device and the configuration of the server and device IP addresses.

- Step 1: Enter the U-Boot interactive command prompt for configuration by pressing any key when prompted with `Hit any key to stop autoboot`:


  ```shell
  U-Boot 2021.10 (May 24 2024 - 07:26:08 +0000)

  CPU:   Renesas Electronics CPU rev 1.0
  Model: <Board-Model>
  DRAM:  896 MiB
  MMC:   sd@11c00000: 0
  Loading Environment from SPIFlash... SF: Detected is25wp256 with page size 256 Bytes, erase size 4 KiB, total 32 MiB

  In:    serial@1004b800
  Out:   serial@1004b800
  Err:   serial@1004b800
  Net:   eth0: ethernet@11c20000, eth1: ethernet@11c30000
  Hit any key to stop autoboot:  0
  =>
  =>
  ```

- Step 2: Enter Specify the Ethernet device (eth1) to use for the network connection. For example,

  ```shell
  => setenv ethact ethernet@11c30000
  ```

- Step 3: Configure server and device IPs:

  ```shell
  => setenv serverip <server_ip>
  => setenv ipaddr <device_ip>
  ```

  For example:
  ```shell
  => setenv serverip 192.168.5.86
  => setenv ipaddr 192.168.5.30
  ```

##### 4.1.2.4. TFTP Boot

In this subsection, the boot arguments and commands for U-Boot will be configured to load the kernel image and device tree from the TFTP server.

Step 1: After setting up the TFTP server, you need to ensure that the necessary boot images, including the kernel image, device tree blob (DTB), device tree overlay (DTBO), and root file system, are placed in the TFTP directory.

The example below is based on the RZ/G2L-SBC board. Other boards will follow the same procedure, but the image filenames may differ depending on the board configuration.

```shell
renesas@builder-pc:/tftpboot/rzsbc/$ tree -L 2
.
├── Image
├── overlays
│   ├── rzg2l-sbc-can.dtbo
│   ├── rzg2l-sbc-dsi.dtbo
│   ├── rzg2l-sbc-ext-i2c.dtbo
│   ├── rzg2l-sbc-ext-spi.dtbo
│   └── rzg2l-sbc-ov5640.dtbo
├── rootfs
│   ├── bin -> usr/bin
│   ├── boot
│   ├── dev
│   ├── etc
│   ├── home
│   ├── lib -> usr/lib
│   ├── media
│   ├── mnt
│   ├── opt
│   ├── proc
│   ├── root
│   ├── run
│   ├── sbin -> usr/sbin
│   ├── snap
│   ├── srv
│   ├── sys
│   ├── tmp
│   ├── usr
│   └── var
└── rzg2l-sbc.dtb
```
- Step 2: Define the boot arguments to specify the network and root file system settings:

  ```shell
  => setenv bootargs 'consoleblank=0 strict-devmem=0 ip=<device_ip>:<server_ip>::::<eth_device> root=/dev/nfs rw nfsroot=<server_ip>:</path/to/your/rootfs>,v3,tcp' 
  ```

  For example: 
  ```shell
  => setenv bootargs 'consoleblank=0 strict-devmem=0 ip=192.168.5.30:192.168.5.86::::eth1 root=/dev/nfs rw nfsroot=192.168.5.86:/tftpboot/rzsbc/rootfs,v3,tcp'
  ```

- Step 3: Configure the boot command to load the kernel image and device tree files.

  ```shell
  => setenv bootcmd 'tftp <load_address_kernel> <path/to/kernel_image>; tftp <load_address_dtb> <path/to/device_tree_blob>; tftp <load_address_dtbo> <path/to/dtbo file>; booti <load_address_kernel> - <load_address_dtb> - <load_address_dtbo>'
  ```

  For example load `Image`, `rzg2l-sbc.dtb` and `rzg2l-sbc-ext-spi.dtbo` files.
  ```shell
  => setenv bootcmd 'tftp 0x48080000 rzsbc/Image; tftp 0x48000000 rzsbc/rzg2l-sbc.dtb; tftp 0x48010000 rzsbc/overlays/rzg2l-sbc-ext-spi.dtbo; booti 0x48080000 - 0x48000000 - 0x48010000'
  ```

- Step 4: Save the changes to the environment variables so they persist across reboots:

  ```shell
  => saveenv
  ```

- Step 5: Initiate the boot progress by running bootcmd:

  ```shell
  run bootcmd
  ```

  If everything is set up correctly, the images will be booted from the network.

  ```
  => run bootcmd
  Using ethernet@11c30000 device
  TFTP from server 192.168.5.86; our IP address is 192.168.5.30
  Filename rzsbc/Image'.
  Load address: 0x48080000
  Loading: #################################################################
          #################################################################
          #################################################################
          19.6 MiB/s
  done
  Bytes transferred = 18035200 (1133200 hex)
  Using ethernet@11c30000 device
  TFTP from server 192.168.5.86; our IP address is 192.168.5.30
  Filename 'rzsbc/rzg2l-sbc.dtb'.
  Load address: 0x48000000
  Loading: ####
          8.6 MiB/s
  done
  Bytes transferred = 44855 (af37 hex)
  Using ethernet@11c30000 device
  TFTP from server 192.168.5.86; our IP address is 192.168.5.30
  Filename 'rzsbc/overlays/rzg2l-sbc-ext-spi.dtbo'.
  Load address: 0x48010000
  Loading: #
          455.1 KiB/s
  done
  Bytes transferred = 932 (3a4 hex)
  Moving Image from 0x48080000 to 0x48200000, end=493a0000
  ## Flattened Device Tree blob at 48000000
    Booting using the fdt blob at 0x48000000
    Loading Device Tree to 000000007bf1a000, end 000000007bf27f36 ... OK

  Starting kernel ...
  ```


#### 4.1.3. Using SSH and SCP for Remote Access and File Transfers

This section explains how to use SSH (Secure Shell) for secure remote access to the target board and how to utilize SCP (Secure Copy Protocol) for file transfers. By default, OpenSSH is employed as it is a feature-rich and widely used SSH implementation that offers advanced capabilities for secure communication. While OpenSSH serves as the default option, Dropbear SSH can be considered for lightweight, resource-constrained environments making it particularly suitable for embedded systems.

##### 4.1.3.1. Differences Between Dropbear and OpenSSH

- **Resource Usage**: Dropbear is optimized for lower resource usage, making it ideal for embedded systems.
- **Feature Set**: OpenSSH has a more extensive feature set, including advanced options for authentication and configuration.
- **Key Authentication**: OpenSSH requires the use of SSH keys for authentication, while Dropbear can operate with both keys and passwords.

##### 4.1.3.2. Using OpenSSH

OpenSSH is a widely-used, full-featured SSH implementation that provides encrypted communication between hosts. It supports advanced authentication methods and secure remote administration, making it ideal for robust network security.

The RZ boards supports both password and key-based authentication methods. To enhance security by enforcing SSH key-based login, follow these steps to switch to key-based authentication:

- Step 1: Generate an SSH key pair on your local machine, run the following command to generate a secure SSH key pair:

  ```shell
  $ ssh-keygen -t rsa -b 4096
  ```

  - Step 2: Copying an SSH public key to the board using SSH, transfer your public key to the board with this command:

  ```shell
  $ cat ~/.ssh/id_rsa.pub | ssh username@remote_host "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
  ```
  For example:

  ```shell
  $ cat ~/.ssh/id_rsa.pub | ssh root@192.168.5.30 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
  ```

- Step 3: Authenticate using SSH keys:

  ```shell
  $ ssh root@192.168.5.30
  ```

  If this is the first time connecting to this host (as mentioned in the previous method), a message similar to the following may appear:

  ```shell
  $ The authenticity of host 192.169.5.30 (192.168.5.30)' can't be established.
  ED25519 key fingerprint is SHA256:esQPI0Ip9HZH9A6dvTsA9+k7eLjT4sqzpiF7znl0tyw.
  This key is not known by any other names
  Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
  ```

  This indicates that the local computer does not recognize the remote host. Type `yes` and press `ENTER` key to proceed.

- Step 4: Disable password authentication. If login to your account using SSH is successful without a password, SSH key-based authentication has been correctly configured. However, password-based authentication remains active, which leaves the server vulnerable to brute-force attacks.

  Once the SSH connection is established, open the SSH daemon's configuration file:

  ```shell
  $ vi /etc/ssh/sshd_config
  ```

  Inside the file, search for a directive called `PasswordAuthentication`. This may be commented out. Uncomment the line by removing any # at the beginning of the line, and set the value to `no`. This will disable your ability to log in through SSH using account passwords: /etc/ssh/sshd

  ```shell
  PasswordAuthentication no
  ```

- Step 5: Restart the SSH service to apply the changes:
  ```shell
  $ systemctl restart ssh
  ```

##### 4.1.3.3. SSH Access

After configuring the authentication key, access to target board via SSH can be achieved using various tools available on both Windows and Linux platforms.

1. **SSH from Windows host**
   - **Using Git Bash**:
        - Install Git for Windows if you haven't already.
        - Use the following command:
            ```shell
            $ ssh username@<device_ip>
            ```
            For example:
            ```shell
            $ ssh root@192.168.5.30
            ```
        - Type `yes` to confirm the host's authenticity when prompted.
          ```shell
          $ ssh root@192.168.5.30
          The authenticity of host '192.168.5.30 (192.168.5.30)' can't be established.
          RSA key fingerprint is SHA256:v39PhjNp4F7HcQpwJmfNOYcC+ZZ3Yw8i1ICsL2mXUgg.
          This key is not known by any other names.
          Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
          Warning: Permanently added '192.168.5.30' (RSA) to the list of known hosts.
          ```

   - **Using MobaXTerm**:
        - Download and install MobaXterm.
        - Select "Session" > "SSH" and enter the device's IP address.
        - Confirm the host's authenticity if prompted.

2. **SSH from Linux host**
    - Open a terminal and run
        ```shell
        $ ssh username@<device_ip>
        ```
        For example:
        ```shell
        $ ssh root@192.168.5.30
        ```
    - Type `yes` to confirm the host's authenticity when prompted.

##### 4.1.3.4. SCP (Secure Copy)

To securely transfer files between local and remote systems, SCP can be used on both Windows and Linux.

1. **SCP from Windows host**
   - **Using Git Bash**:
     - Install Git for Windows if you haven't already.
     - Use the following command:
       ```shell
       $ scp <local_file> username@<device_ip>:<remote_path>
       ```
       For example:
       ```shell
       $ scp hello-world root@192.168.5.30:home/root
       ```
     - Type `yes` to confirm the host's authenticity when prompted.

   - **Using WinSCP**:
     - Open WinSCP and select "New Session"
     - Choose SCP as protocol then enter the remote device's IP address and the user name.
     - Click "Login" and choose yes to confirm the host's authenticity when prompted.
     - Drag and drop files between your local machine (Left) and the target board (Right) to transfer.

2. **SCP from Linux host**
   - Use the following command:
      ```shell
      $ scp <local_file> username@<device_ip>:<remote_path>
      ```
     For example:
      ```shell
      $ scp hello-world root@192.168.5.30:home/root
      ```
   - Type `yes` to confirm the host's authenticity when prompted.

##### 4.1.3.5. Switching from OpenSSH to Dropbear

By default, the RZ boards image uses OpenSSH as the SSH server. If you want to switch to Dropbear, follow these steps:

- Step 1: Edit the local.conf file in Yocto build configuration
- Step 2: Step 2: Modify the SSH-related variables to disable OpenSSH and enable Dropbear by changing:

  ```shell
  EXTRA_IMAGE_FEATURES:remove = " ssh-server-dropbear"
  EXTRA_IMAGE_FEATURES:append = " ssh-server-openssh"
  ```

  to

  ```shell
  EXTRA_IMAGE_FEATURES:append = " ssh-server-dropbear"
  EXTRA_IMAGE_FEATURES:remove = " ssh-server-openssh"
  ```

  This tells the build system to remove OpenSSH support and include Dropbear instead.

- Step 3: Rebuild and deploy the image to apply the changes.

This will automatically remove OpenSSH and enable Dropbear during the image build.

#### 4.1.4. Configure the Network

The Ubuntu installer has configured our system to get its network settings via DHCP, we can change that now to have a static IP address. If you want to keep the DHCP-based network configuration, then skip this chapter. In Ubuntu, the network is configured with Netplan and the configuration file is **/etc/netplan/01-netcfg.yaml**. The traditional network configuration file **/etc/network/interfaces** is not used anymore. Edit */etc/netplan/00-installer-config.yaml* and adjust it to your needs (in this example setup I will use the IP address *192.168.0.100* and the DNS servers *8.8.4.4, 8.8.8.8* .

Open the network configuration file with vim:

```bash
sudo vi /etc/netplan/00-installer-config.yaml
```

The server is using DHCP right after the installation; the interfaces file will look like this:

```yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    ens33:
      dhcp4: true
  version: 2
```

To use a static IP address 192.168.0.100, I will change the file so that it looks like this afterward:

```yaml
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
 version: 2
 renderer: networkd
 ethernets:
   ens33:
     dhcp4: no
     dhcp6: no
     addresses: [192.168.0.100/24]
     routes:
      - to: default
        via: 192.168.0.1
     nameservers:
       addresses: [8.8.8.8,8.8.4.4]
```

**IMPORTANT**: The indentation of the lines matters, add the lines as shown above.

Then restart your network to apply the changes:

```bash
sudo netplan generate
sudo netplan apply
```

Then edit */etc/hosts*.

```bash
sudo vi /etc/hosts
```
Make it look like this:
```
127.0.0.1 localhost
192.168.0.100 rz.example.com rz

# The following lines are desirable for IPv6 capable hosts
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

Now, we will change the hostname of our machine as follows:

```bash
sudo echo rz > /etc/hostname 
sudo hostname rz
```

The first command sets the hostname "rz" in the /etc/hostname file. This file is read by the system at boot time. The second command sets the hostname in the current session so we don't have to restart the server to apply the hostname.

As an alternative to the two commands above you can use the hostnamectl command which is part of the systemd package.

```bash
sudo hostnamectl set-hostname rz
```

Afterward, run:

```bash
hostname
hostname -f
```

The first command returns the short hostname while the second command shows the fully qualified domain name:
```bash
root@rz:/home/root# hostname
rz
root@rz:/home/root# hostname -f
rz.example.com
root@rz:/home/root#
```

### 4.2. Accessing and Configuring Features on RZ/G2L-SBC

This section provides practical instructions for configuring and using key hardware features on the RZ/G2L Single Board Computer (SBC). It includes guidance on enabling interfaces such as SPI, I2C, and HDMI, as well as using Wi-Fi, Bluetooth, the 40-pin IO expansion header, and the U-Boot environment.

#### 4.2.1. 40 IO expansion interface settings

The RZ/G2L-SBC features a versatile 40-pin IO Expansion Interface that supports various communication protocols and functions. This interface can be configured for:

- I2C: Channels 0 and 3
- SPI: Channel 0
- SCIF: Channel 0
- CAN: Channels 0 and 1
- GPIO: Pin-function (default setting)

By default, I2C Channel 0 and SCIF Channel 0 are enabled. However, you can easily reconfigure the interface to use other channels and functions using FDT overlays.

##### 4.2.1.1. Understanding FDT Overlays and uEnv.txt

The RZ/G2L-SBC uses FDT (Flattened Device Tree) overlays to manage the configuration of its IO expansion interface. These overlays are enabled by setting specific environment variables in the `uEnv.txt` file.

The `uEnv.txt` file is located in partition 1 of the SD card.

The following table details the available configuration options that can be set in uEnv.txt:

```
## For RZ SBC U-Boot Env
/------------------------------|--------------|------------------------------
|       Config                 | Value if set |     To be loading
|------------------------------|--------------|------------------------------
| enable_overlay_i2c           | '1' or 'yes' |  rzg2l-sbc-ext-i2c.dtbo
|------------------------------|--------------|------------------------------
| enable_overlay_spi           | '1' or 'yes' |  rzg2l-sbc-ext-spi.dtbo
|------------------------------|--------------|------------------------------
| enable_overlay_can           | '1' or 'yes' |  rzg2l-sbc-can.dtbo
|------------------------------|--------------|------------------------------
| enable_overlay_dsi           | '1' or 'yes' |  rzg2l-sbc-dsi.dtbo
|------------------------------|--------------|------------------------------
| enable_overlay_csi_ov5640    | '1' or 'yes' |  rzg2l-sbc-ov5640.dtbo
|----------------------------------------------------------------------------
| fdtfile   : is a base dtb file, should be set rzg2l-sbc.dtb
|----------------------------------------------------------------------------
| uboot env : you could set U-Boot's environment variables here, such as 'console=' 'bootargs='
\---------------------------------------------------------------------------

default settings:
    fdtfile=rzg2l-sbc.dtb
    #enable_overlay_i2c=1
    #enable_overlay_spi=1
    #enable_overlay_can=1
    #enable_overlay_dsi=1
    #enable_overlay_csi_ov5640=1

(Note: Lines starting with # are commented out and not active.)
```

##### 4.2.1.2. How to Edit uEnv.txt

The `uEnv.txt` file can be edited using two primary methods:

- On Windows

Mount the SD card on a Windows computer. The `uEnv.txt` file should be accessible for direct editing as it resides in the first partition, typically formatted as FAT32.

- On Linux

When working within a Linux environment (e.g., via SSH or serial console on the RZG2L-SBC), the SD card's first partition can be mounted and the file edited:


You can refer to the `Readme.md` file in partition 1 for the FDT overlays information.
You can mount the sdcard on Windows to edit the uEnv.txt or do it on linux as below

Step 1: Mount the partition
```shell
root@localhost:~# mount /dev/mmcblk2p1 /tmp
root@localhost:/tmp# ls uEnv.txt
uEnv.txt
root@localhost:/tmp# vi uEnv.txt
```

After modifying `uEnv.txt`, save the file and umount the partition:

```shell
root@localhost:/tmp# cd ~
root@localhost:~# umount /tmp
root@localhost:~# sync
```

After changing the value of overlays options, we need to run `sync` to ensure that the changes are affected. Then, execute `reboot` to apply the changes.

For further details on FDT overlays and advanced configurations, refer to the `Readme.md` file located in partition 1 of the SD card.

The below section shows how to configure for each GPIO function:

##### 4.2.1.3. Configuring GPIO Pins

To set the state of a GPIO pin, use the `gpioset` command with the following syntax:

```shell
gpioset -c <chip> <pin> = <value>
```

- chip: Specifies the GPIO chip (e.g., gpiochip0).
- pin: Refers to the specific GPIO pin number on that chip.
- value: Sets the pin state (0 for low, 1 for high).

Examples:

To set GPIO pin 0 on gpiochip0 to a low state:

```
root@localhost:~# gpioset -c gpiochip0 0=0
```

To set GPIO pin 0 on gpiochip0 to a high state:

```shell
root@localhost:~# gpioset -c gpiochip0 0=1
```

##### 4.2.1.4. I2C function (channel 3 - RIIC3)

You should edit `uEnv.txt` as follows to enable I2C channel 3 on 40 IO expansion interface:

```
enable_overlay_i2c=1
```

To check the I2C channel 3 is enabled or not, run the following command and check the result:

```
root@localhost:~# i2cdetect -l
i2c-3   i2c             Renesas RIIC adapter                    I2C adapter
i2c-1   i2c             Renesas RIIC adapter                    I2C adapter
i2c-4   i2c             i2c-1-mux (chan_id 0)                   I2C adapter
i2c-0   i2c             Renesas RIIC adapter                    I2C adapter
root@localhost:~#
```

You can also check devices existance on I2C bus by running the following command:

```
root@localhost:~# i2cdetect -y -r 3
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:          -- -- -- -- -- -- -- -- -- -- -- -- --
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
50: 50 -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
70: -- -- -- -- -- -- -- --
```

##### 4.2.1.5. SPI function (channel 0 - RSPI0)

You should edit `uEnv.txt` as follows to enable SPI channel 0 on 40 IO expansion interface:

```
enable_overlay_spi=1
```

Run the following command to config the SPI:

```
root@localhost:~# spi-config -d /dev/spidev0.0 -q
/dev/spidev0.0: mode=0, lsb=0, bits=8, speed=2000000, spiready=0
```

Connect Pin 19 (RSPI0 MOSI) to Pin 21 (RSPI0 MISO), then run the below command and check the result:

```
root@localhost:~# echo -n -e "1234567890" | spi-pipe -d /dev/spidev0.0 -s 10000000 | hexdump
0000000 3231 3433 3635 3837 3039
000000a
```

##### 4.2.1.6. CAN function (channel 0,1 - CAN0, CAN1)

You should edit `uEnv.txt` as follows to enable CAN channel 0,1 on 40 IO expansion interface:

```
enable_overlay_can=1
```

To check the CAN channels are enabled or not, run the following command and check the result:

```
root@localhost:~# ip a | grep can
3: can0: <NOARP,ECHO> mtu 16 qdisc noop state DOWN group default qlen 10
    link/can
4: can1: <NOARP,ECHO> mtu 16 qdisc noop state DOWN group default qlen 10
    link/can
root@localhost:~#
```

Then set up for CAN devices. Now you can up/down or send data from CAN channels.

The below shows the communication between two CAN channels.
```
root@localhost:~# ip link set can0 down
root@localhost:~# ip link set can0 type can bitrate 500000
root@localhost:~# ip link set can0 up
[   48.120419] IPv6: ADDRCONF(NETDEV_CHANGE): can0: link becomes ready
root@localhost:~# ip link set can1 down
root@localhost:~# ip link set can1 type can bitrate 500000
root@localhost:~# ip link set can1 up
[   69.906039] IPv6: ADDRCONF(NETDEV_CHANGE): can1: link becomes ready
root@localhost:~# candump can0 & cansend can1 123#01020304050607
[1] 271
  can0  123   [7]  01 02 03 04 05 06 07
root@localhost:~# candump can1 & cansend can0 123#01020304050607
[2] 273
  can0  123   [7]  01 02 03 04 05 06 07
  can1  123   [7]  01 02 03 04 05 06 07
root@localhost:~#
```

#### 4.2.2. On-board Wi-Fi Modules configurations

RZG2L-SBC has an on-board Wireless modules on it. Currently, we only support for Wi-Fi feature in this release.

To settings for Wi-Fi on RZG2L-SBC, run the following commands:

```
root@localhost:~# connmanctl
connmanctl> enable wifi
Enabled wifi
connmanctl> agent on
Agent registered
connmanctl> scan wifi
Scan completed for wifi
connmanctl> services
    xDredme10zW          wifi_0025ca329da3_78447265646d6531307a57_managed_psk
                         wifi_0025ca329da3_hidden_managed_psk
    REL-GLOBAL           wifi_0025ca329da3_52454c2d474c4f42414c_managed_ieee8021x
    R-GUEST              wifi_0025ca329da3_522d4755455354_managed_none
    RVC-WLS              wifi_0025ca329da3_5256432d574c53_managed_ieee8021x
connmanctl> connect wifi_0025ca329da3_78447265646d6531307a57_managed_psk
Agent RequestInput wifi_0025ca329da3_78447265646d6531307a57_managed_psk
  Passphrase = [ Type=psk, Requirement=mandatory ]
Passphrase? nFjey48aT9pk
connmanctl> exit
```

To confirm the Wi-Fi is connected, ping to the outside world:

```
root@localhost:~# ping www.google.com
PING www.google.com(hkg07s39-in-x04.1e100.net (2404:6800:4005:813::2004)) 56 data bytes
64 bytes from hkg07s39-in-x04.1e100.net (2404:6800:4005:813::2004): icmp_seq=1 ttl=57 time=43.2 ms
64 bytes from hkg07s39-in-x04.1e100.net (2404:6800:4005:813::2004): icmp_seq=2 ttl=57 time=81.1 ms
64 bytes from hkg07s39-in-x04.1e100.net (2404:6800:4005:813::2004): icmp_seq=3 ttl=57 time=124 ms
```

**Please note that before using Wi-Fi feature on RZG2L-SBC, the ethernet connections need to be down.**

```
root@localhost:~# ifconfig end0 down
root@localhost:~# ifconfig end1 down
```

#### 4.2.3. On-board Audio Codec with Stereo Jack Analog Audio IO configurations

The RZ/G2L-SBC features an onboard audio codec, Renesas DA7219, enabling audio playback and recording through a 3.5mm stereo jack (connector J8, 6-pin).
- Audio Data Interface: Connected to DAI (SSI1) using the I2S format.
- Control Interface: Managed via I2C0.
- Headset Jack: Marked J8 on the board.

Audio playback and recording are supported through ALSA tools with PCM WAV files. For other formats such as MP3, the pre-installed GStreamer framework provides compatibility.

Prepare the required audio files and place them in the target directory before executing the following commands. Example commands are shown below:

```
root@localhost:~# aplay /home/root/audios/04_16KH_2ch_bgm_maoudamashii_healing01.wav
root@localhost:~# gst-play-1.0 /home/root/audios/COMMON6_MPEG2_L3_24KHZ_160_2.mp3
```

`aplay` command supports `wav` format audio files

`gst-play-1.0` command supports `wav`, `mp3` and `aac` formats

To perform a recording, run the following command to record audio to an `audio_capture.wav` file:

```
root@localhost:~# arecord -f S16_LE -r 48000 audio_capture.wav
```

Press Ctrl+C if you want to stop recording.

In the above command:

-f S16_LE : audio format

-r 48000  : sample rate of the audio file (48KHz)

To verify the recorded file, you can play it by the following command:

```
root@localhost:~# aplay audio_capture.wav
```

To adjust the level of the audio record/playback, use the following command to open the ALSA mixer GUI:

```
root@localhost:~# alsamixer
```

#### 4.2.4. MIPI DSI with display panels

RZG2L-SBC supports the MIPI DSI interface and the Waveshare 5 inch Touchscreen Monitor MIPI-DSI LCD is enabled and tested.

You should edit `uEnv.txt` as follows to enable MIPI DSI interface with the panel supported:

```
enable_overlay_dsi=1
```

**Please note that selecting the MIPI DSI display will cause the HDMI display be disabled.**

#### 4.2.5. Playing Video Files on RZ/G2L-SBC

Use `gst-launch-1.0` to play video files. The playbin element in GStreamer makes it easy to play multimedia content. Prepare an mp4 file and run the following command:

```
root@localhost:~# gst-launch-1.0 playbin uri=file:///<path/to/your/video/path>
```

We have prepared some test videos in the /home/root/videos folder. You can use these for testing. For example:

```
root@localhost:~# gst-launch-1.0 playbin uri=file:///home/root/videos/renesas-bigideasforeveryspace.mp4
```

#### 4.2.6. MIPI CSI2 with Arducam 5MP MIPI Camera

RZG2L-SBC supports the MIPI CSI-2 camera interface and the Arducam 5MP MIPI Camera (OV5640 image sensor) is enabled and tested.

You should edit `uEnv.txt` as follows to enable MIPI CSI-2 interface with the camera supported:

```
enable_overlay_csi_ov5640=1
```
To use the camera, we need to enable the CSI-2 module. Run the following commands:

```
root@localhost:~# cd /home/root/
root@localhost:~# ./v4l2-init.sh <resolution>
```

The <resolution> argument specifies the resolution for the camera. Valid resolutions are:

- 720x480
- 720x576
- 1024x768
- 1280x720
- 1920x1080
- 2592x1944

If no resolution is specified or an invalid resolution is provided, the default resolution 1280x720 will be used. For example:

When use a valid resolution:

```
root@localhost:~# ./v4l2-init.sh 1920x1080
Link CRU/CSI2 to ov5640 1-003c with format UYVY8_1X16 and resolution 1920x1080
```

When no resolution is specified:

```
root@localhost:~# ./v4l2-init.sh
No resolution specified. Using default resolution: 1280x720
Link CRU/CSI2 to ov5640 1-003c with format UYVY8_1X16 and resolution 1280x720
```

When an invalid resolution is provided:

```
root@localhost:~# ./v4l2-init.sh 3000x2000
Invalid resolution: 3000x2000
Input resolution is not available. Using default resolution: 1280x720
Link CRU/CSI2 to ov5640 1-003c with format UYVY8_1X16 and resolution 1280x720
```

The `v4l2-init.sh` script helps enable the CSI-2 module and select the camera's supported display resolution.

After running the script, initiate a video capture session using the matching width and height

```
root@localhost:~# gst-launch-1.0 v4l2src device=/dev/video0 ! video/x-raw,width=1280,height=720 ! videoconvert ! waylandsink
```

Ensure that the width and height values in the GStreamer pipeline match the resolution specified in `v4l2-init.sh`. This command starts a continuous stream of the camera feed to the active video display.

#### 4.2.7. Generic USB Bluetooth framework

The RZG2L-SBC supports the generic USB Bluetooth framework, which is back-ported from the Linux kernel mainline. TP-Link UB500 Bluetooth 5.0 Nano USB Adapter (Realtek chipset) has been tested and proven to work on the board.

The following steps will guide how to enable the TP-Link UB500 adapter:

- Step 1: Download the appropriate firmware for the TP-Link UB500 adapter and store it on the RZG2L-SBC. This will ensure it is loaded each time the board boots (one-time setup).

```shell
root@localhost:~# mkdir -p /lib/firmware/rtl_bt
root@localhost:~# curl -s https://raw.githubusercontent.com/Realtek-OpenSource/android_hardware_realtek/rtk1395/bt/rtkbt/Firmware/BT/rtl8761b_fw -o /lib/firmware/rtl_bt/rtl8761bu_fw.bin
```
**Note:**
**(1) Please make sure you have internet access before running the commands.**

**(2) If the firmware is being downloaded for the first time, a reboot of the board is required to ensure the TP-Link UB500 adapter functions properly.**

**(3) By default, Bluetooth is blocked by RFKILL. To unblock it, use the command 'rfkill unblock bluetooth'**

- Step 2: Unblock bluetooth and verify whether the bluetooth status is UP RUNNING.

Run the following command to ensure that rfkill unblock bluetooth:

```shell

root@localhost:~# hciconfig -a
hci0:   Type: Primary  Bus: USB
        BD Address: E8:48:B8:C8:20:00  ACL MTU: 1021:6  SCO MTU: 255:12
        DOWN
        RX bytes:1045 acl:0 sco:0 events:92 errors:0
        TX bytes:12279 acl:0 sco:0 commands:92 errors:0
        Features: 0xff 0xff 0xff 0xfe 0xdb 0xfd 0x7b 0x87
        Packet type: DM1 DM3 DM5 DH1 DH3 DH5 HV1 HV2 HV3
        Link policy: RSWITCH HOLD SNIFF PARK
        Link mode: PERIPHERAL ACCEPT
root@localhost:~# rfkill list
0: hci0: Bluetooth
        Soft blocked: yes
        Hard blocked: no
root@localhost:~# rfkill unblock bluetooth
root@localhost:~# rfkill list
0: hci0: Bluetooth
        Soft blocked: no
        Hard blocked: no
root@localhost:~# hciconfig hci0 up
root@localhost:~# hciconfig -a
hci0:   Type: Primary  Bus: USB
        BD Address: E8:48:B8:C8:20:00  ACL MTU: 1021:6  SCO MTU: 255:12
        UP RUNNING
        RX bytes:1773 acl:0 sco:0 events:142 errors:0
        TX bytes:13029 acl:0 sco:0 commands:142 errors:0
        Features: 0xff 0xff 0xff 0xfe 0xdb 0xfd 0x7b 0x87
        Packet type: DM1 DM3 DM5 DH1 DH3 DH5 HV1 HV2 HV3
        Link policy: RSWITCH HOLD SNIFF PARK
        Link mode: PERIPHERAL ACCEPT
        Name: 'rzg2l-sbc'
        Class: 0x000000
        Service Classes: Unspecified
        Device Class: Miscellaneous,
        HCI Version: 5.1 (0xa)  Revision: 0x97b
        LMP Version: 5.1 (0xa)  Subversion: 0xec43
        Manufacturer: Realtek Semiconductor Corporation (93)

The bluetooth status is UP RUNNING.

- Step 3: Verify whether the TP-Link UB500 adapter is properly attached.

Run the following command to ensure that the system has recognized the TP-Link UB500 adapter:

```shell
root@localhost:~# hciconfig hci0 -a
hci0:   Type: Primary  Bus: USB
        BD Address: E8:48:B8:C8:20:00  ACL MTU: 1021:5  SCO MTU: 255:11
        UP RUNNING PSCAN
        RX bytes:2264 acl:0 sco:0 events:211 errors:0
        TX bytes:32795 acl:0 sco:0 commands:211 errors:0
        Features: 0xff 0xff 0xff 0xfe 0xdb 0xfd 0x7b 0x87
        Packet type: DM1 DM3 DM5 DH1 DH3 DH5 HV1 HV2 HV3
        Link policy: RSWITCH HOLD SNIFF PARK
        Link mode: SLAVE ACCEPT
        Name: 'rzg2l-sbc'
        Class: 0x000000
        Service Classes: Unspecified
        Device Class: Miscellaneous,
        HCI Version: 5.1 (0xa)  Revision: 0x9dc6
        LMP Version: 5.1 (0xa)  Subversion: 0xd922
        Manufacturer: Realtek Semiconductor Corporation (93)
```

The TP-Link UB500 adapter is now ready to connect.

- Step 4: Connect Bluetooth Device

Use `bluetoothctl` to connect Bluetooth Device:

```Shell
root@localhost:~# bluetoothctl
[bluetooth]# power on
[bluetooth]# pairable on
[bluetooth]# agent on
[bluetooth]# default-agent
```

Set the RZG2L-SBC to be discoverable by other Bluetooth devices:

```Shell
[bluetooth]# discoverable on
```

Enable and disable scan function:

```Shell
[bluetooth]# scan on
[bluetooth]# scan off
```

Pair and connect the device:

```Shell
[bluetooth]# pair FC:02:96:A5:80:97
[bluetooth]# trust FC:02:96:A5:80:97
[bluetooth]# connect FC:02:96:A5:80:97
```

`FC:02:96:A5:80:97` is the address of the Bluetooth device. Please change it to match your device’s address.

Exit `bluetoothctl`.

```Shell
[Mi Sports BT]# quit
```

##### 4.2.7.1 Send files over Bluetooth

To share files between the RZG2L-SBC and the target Bluetooth device, run the obexctl daemon and connect:

```Shell
root@localhost:~# export $(dbus-launch)
root@localhost:~# /usr/libexec/bluetooth/obexd -r /home/root -a -d & obexctl
[1] 595
[NEW] Client /org/bluez/obex
[obex]#
[obex]# connect FC:02:96:A5:80:97
Attempting to connect to FC:02:96:A5:80:97
[NEW] Session /org/bluez/obex/client/session0 [default]
[NEW] ObjectPush /org/bluez/obex/client/session0
Connection successful
```

`FC:02:96:A5:80:97` is the address of the Bluetooth device. Please change it to match your device’s address.

Then, to send files, use `send` command while connected to the OBEX Object Push profile.

```Shell
[FC:02:96:A5:80:97]# send /boot/uEnv.txt
Attempting to send /boot/uEnv.txt to /org/bluez/obex/client/session0
[NEW] Transfer /org/bluez/obex/client/session0/transfer0
Transfer /org/bluez/obex/client/session0/transfer0
        Status: queued
        Name: uEnv.txt
        Size: 2069
        Filename: /boot/uEnv.txt
        Session: /org/bluez/obex/client/session0
[CHG] Transfer /org/bluez/obex/client/session0/transfer0 Status: complete
[DEL] Transfer /org/bluez/obex/client/session0/transfer0
[FC:02:96:A5:80:97]# quit
```

In this example, a text file names `uEnv.txt` which is located at `/boot` is sent to the target Bluetooth device.

### 4.3. BSP Interface for RZ/G2L and RZ/V2L Evaluation Kits (EVK)

Renesas provides a dedicated BSP Manual Set for the **RZ/G2L** and **RZ/V2L Evaluation Kits (EVKs)**, offering technical guidance on SoC configuration, supported drivers, and Linux system integration.

It is a key reference for developers working with the Verified Linux Package (VLP) on these platforms.

**Download the BSP Manual Set:** [RZ/G2L, RZ/Five, RZ/V2L BSP Manual Set (v4.00)](https://www.renesas.com/en/document/mas/rzg2lfivev2l-group-bsp-manual-set-rtk0ef0045z9006azj-v400zip?queryID=61e0a4d75b9dbf72d4403d438ecf6afd)

### 4.4. BSP Interface for RZ/V2H Evaluation Kit (EVK)

A dedicated **BSP Manual Set** is also available for the **RZ/V2H Evaluation Kit (EVK)**, covering SoC-specific configuration, supported drivers, and integration steps.

This manual is recommended for developers working with the RZ/V2H platform and Verified Linux Package.

**Download the RZ/V2H BSP Manual Set:** [RZ/V2H BSP Manual Set (v1.01)](https://www.renesas.com/en/document/mas/rzv2h-bsp-manual-set-rtk0ef0045z94001azj-v101zip?queryID=d686656abe19aa9183debd3bc17b5b28)