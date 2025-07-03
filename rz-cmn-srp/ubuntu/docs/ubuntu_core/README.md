# Ubuntu Core System development on RZG2L SBC board #
This is the quick startup guide for RZG2L SBC board (hereinafter referred to as `RZG2L-SBC`) to develop on Ubuntu headless (no Desktop environment support).

The following sections will describe how to build this custom Ubuntu Core image and set up the development environment for the RZG2L-SBC.

## Status
This is a Custom Ubuntu Core release of the RZG2L development product for RZG2L-SBC.

This release provides the following features:

 - Custom Ubuntu Core build scripts for easy setup and deployment.
 - RZG2L-SBC Linux BSP functionalities
 - 40 IO expansion interface supported
 - On-board Wireless Modules enabled (only support for Wi-Fi)
 - On-board Audio Codec with Stereo Jack Analog Audio IO
 - Generic USB Bluetooth framework supported
 - MIPI DSI enabled
 - Bootloader with U-Boot Fastboot UDP enabled.

Known issues:

 - Only support for 48 Khz audio sampling rate family.

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
- **DEFAULT_ROOTFS_INTERNAL_FREE_SPACE_MB**: Default extra *free* space to add *inside* the root filesystem (in MB). This space is available to the user/system after booting.
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
│   │   ├── prepare_rootfs_qt.sh
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

16 directories, 73 files
```

**Output folder outline:**

The image build is controlled by the main build script `rzsbc_builder.sh` located at the root of the repository. Running this script initiates the complete build process, producing the output images and root filesystem archives as shown below.

To build the Ubuntu Core image, run the main build script with the following command:

```shell
IMAGE=ubuntu-core ./rzsbc_builder.sh build
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
├── renesas-ubuntu-rzg2l-sbc.tar.bz2             <---- Roofs that generated by yocto
├── setup_ubuntu_environment.sh                  <---- Setup environment for main build script
├── script
│   ├── common
│   ├── ubuntu_core
│   └── ubuntu_lxde
└── ubuntu-base-24.04-base-arm64.tar.gz

yocto_rzsbc_board/build/tmp/deploy/images/rzg2l-sbc/target/images
├── rootfs
|   └── ubuntu-core-image-rzg2l-sbc.tar.bz2        <---- Output compressed rootfs
└──  ubuntu-core-image-rzg2l-sbc.wic.gz            <---- Output compressed WIC
```

### U-boot environment
For more information about the U-Boot environment configuration, please refer to the original documentation provided in the [Renesas-SST/meta-renesas](https://github.com/Renesas-SST/meta-renesas/blob/styhead/rz-sbc/recipes-docs/rzg2l-sbc-readme/files/README.md) layer.

## Confirm supported features on RZG2L-SBC
### 40 IO expansion interface settings

The 40 IO Expansion Interface on RZG2L-SBC supports for I2C channel 0 and channel 3, SPI channel 0, SCIF channel 0, CAN channel 0 and channel 1 and GPIO pin-function (default).

By default, I2C Channel 0 and SCIF Channel 0 are enabled. However, you can easily reconfigure the interface to use other channels and functions using FDT overlays.

#### Understanding FDT Overlays and uEnv.txt

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

#### How to Edit uEnv.txt

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
root@localhost:/tmp# nano uEnv.txt
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

#### Configuring GPIO Pins

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

#### I2C function (channel 3 - RIIC3)

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

#### SPI function (channel 0 - RSPI0)

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

#### CAN function (channel 0,1 - CAN0, CAN1)

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

### On-board Wi-Fi Modules configurations

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
root@localhost:~# ifconfig eth0 down
root@localhost:~# ifconfig eth1 down
```
### On-board Audio Codec with Stereo Jack Analog Audio IO configurations

RZG2L-SBC has an On-board Audio Codec - DA7219. It is the default audio device of RZG2L-SBC
and it will be enabled automatically when the system comes up.

Before playing an audio file, connect an audio device such as 3.5mm headset to J8.

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
### MIPI DSI with display panels

RZG2L-SBC supports the MIPI DSI interface and the Waveshare 5 inch Touchscreen Monitor MIPI-DSI LCD is enabled and tested.

You should edit `uEnv.txt` as follows to enable MIPI DSI interface with the panel supported:

```
enable_overlay_dsi=1
```

**Please note that selecting the MIPI DSI display will cause the HDMI display be disabled.**

### Generic USB Bluetooth framework

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

- Step 2: Verify whether the TP-Link UB500 adapter is properly attached.

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
        Name: 'rz'
        Class: 0x000000
        Service Classes: Unspecified
        Device Class: Miscellaneous,
        HCI Version: 5.1 (0xa)  Revision: 0x9dc6
        LMP Version: 5.1 (0xa)  Subversion: 0xd922
        Manufacturer: Realtek Semiconductor Corporation (93)
```

The TP-Link UB500 adapter is now ready to connect.

- Step 3: Connect Bluetooth Device

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

#### Send files over Bluetooth

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

### Package Management

The distribution comes with Debian package manager `apt-get` and `dpkg` for binary package handling.

#### Setting up Debian as a backend source
The default configuration for the `sources.list` file, which defines the package repositories, is as follows:

```
deb [arch=arm64] http://ports.ubuntu.com/ focal main multiverse universe
deb [arch=arm64] http://ports.ubuntu.com/ focal-security main multiverse universe
deb [arch=arm64] http://ports.ubuntu.com/ focal-backports main multiverse universe
deb [arch=arm64] http://ports.ubuntu.com/ focal-updates main multiverse universe
```

#### Configuring the Debian package repository

`sources.list` is a critical configuration file for packages installation and updates used by package managers on Debian-based Linux distributions. The `sources.list` file contains a list of URLs or repository addresses where the package manager can find software packages. These repositories may be maintained by the Linux distribution itself or by third-party individuals or organizations.

The file is located at `/etc/apt/sources.list.d/sources.list`. You can modify it to add or change the repositories according to your needs.

After configuring the APT repositories, refresh the package database by running:

```
root@localhost:~# apt-get update
```

**Please make sure you have internet access before running `apt-get update`.**

This command refreshes the package database and ensures that your system is aware of the latest available packages from the configured repositories.

In the contents of `sources.list` file, you can see `[arch=arm64]` on each line. This is because the RZG2L-SBC's architecture is aarch64, as indicated by the output of the `lscpu` command:

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
deb http://deb.debian.org/debian bullseye main contrib non-free
```

Remember that sources doesn’t have to be a single origin. It's very common to add multiple repositories and sources for packages and manage them using keys.

The source management is beyond the scope of this document.

#### Using `apt-get` to install packages

To install a package using `apt-get`, use the following command:

```
root@localhost:~# apt-get install <package-name>
```

#### Using `DPKG` to install packages

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

### Configure the Network

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
