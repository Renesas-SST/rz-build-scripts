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
- **ROOTFS_SPACE**: Additional space for the rootfs partition in MB.
- **core_image_qt_name**: Input rootfs (contains Qt libraries, bootloader, kernel, etc. - generated from Yocto) file name.
- **UBUNTU_BASE_FILE_NAME**: The file name of the Ubuntu base that will be downloaded.
- **UBUNTU_BASE_LINK**: The link to download the Ubuntu base file.
- **OUTPUT_ROOTFS**: The output file name for the rootfs.
- **OUTPUT_WIC**: The output file name for the wic image.
- **TIME_ZONE_AREA**: The time zone area (e.g., "Asia").
- **TIME_ZONE_CITY**: The time zone city (e.g., "Ho_Chi_Minh").
- **SSH_NO_PASS_LOGIN**: Set to 1 to enable users to log in without a password.
- **IS_WESTON_ENABLE**: Set to 0 to disable the Weston compositor.

> :memo: **Note:** Host PC with Ubuntu 22.04 is recommended for the build. Prepare environment for building package and local build environment.

Then we can execute the script as follows (using setting in config.ini):
```
chmod +x rzsbc_ubuntu.sh
sudo ./rzsbc_ubuntu.sh
```

We can pass a parameter (which will override the current setting in config.ini) next to script:
```
chmod +x rzsbc_ubuntu.sh
sudo ./rzsbc_ubuntu.sh "ubuntu-core"
sudo ./rzsbc_ubuntu.sh "ubuntu-lxde"
sudo ./rzsbc_ubuntu.sh "all-ubuntu-images"
```

**Explanation workflow of the main script:**
- **Running the Script**:
This command executes the script rzsbc_ubuntu.sh with superuser (root) privileges, thanks to the sudo command.

- **Environment Configuration**:
Inside rzsbc_ubuntu.sh, the script reads the environment settings from a file named config.ini. This configuration file likely contains parameters that specify the type of Ubuntu system to be built.

- **Sub-shell Execution**:
The script then launches a sub-shell under the current user’s privileges. This means that any processes started in this sub-shell will run with the permissions of the user who invoked the script, not as the root user.

- **Building Yocto**:
Within this sub-shell, the script will use the Yocto build script located in the rz-sbc folder. Yocto is a project that helps developers create custom Linux distributions, and this step involves compiling the necessary components based on the configurations specified earlier.

- **Executing Remaining Build as Root**:
After the Yocto build process is complete, the script uses root privileges (via sudo) to perform any remaining tasks in the Ubuntu build process. This ensures that any actions requiring elevated permissions can be executed without interruption.

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
│   └── ubuntu_core
│       └── network_interfaces.conf
├── config.ini
├── docs
│   └── ubuntu_core
│       └── README.md
├── include
│   ├── common
│   │   ├── allow_empty_password.sh
│   │   ├── create_wic.sh
│   │   ├── install_gstreamer.sh
│   │   ├── install_weston.sh
│   │   ├── prepare_env.sh
│   │   ├── prepare_ubuntu_base.sh
│   │   └── yocto_working.sh
│   └── ubuntu_core
│       ├── mount.sh
│       ├── prepare_conf.sh
│       └── prepare_rootfs_qt.sh
├── rzsbc_ubuntu.sh
└── script
    └── ubuntu_core
        ├── apt_install_base.sh
        └── set_root_password.sh

```

**Output folder outline:**
```
ubuntu/
|-- README.md                               <---- This file
|-- config.ini                              <---- User configuration
|-- core-image-qt-rzpi.tar.bz2              <---- Generated by yocto
|-- rzsbc_ubuntu.sh                          <---- Main execution
|-- rootfs.tar.zst                          <---- Output rootfs
|-- script
|   |-- apt_install_base.sh
|   `-- set_root_password.sh
`-- ubuntu-base-24.04.01-base-arm64.tar.gz

rz-sbc/yocto_rzsbc_board/build/tmp/deploy/images/rzpi/target/images
|-- rootfs
|   `-- ubuntu-image-qt-rzpi.tar.bz2        <---- Output compressed rootfs
`-- ubuntu-image-qt-rzpi.wic.gz         <---- Output compressed WIC
```
### U-boot environment
Please refer to the original package at `Renesas-SST/rz-build-scripts` as all images follow the same procedure.

## Confirm supported features on RZG2L-SBC
### 40 IO expansion interface settings

The 40 IO Expansion Interface on RZG2L-SBC supports for I2C channel 0 and channel 3, SPI channel 0, SCIF channel 0, CAN channel 0 and channel 1 and GPIO pin-function (default).

By default, I2C channel 0 and SCIF channel 0 are enabled. Users can configure to use other channels.

We support an FDT overlays appoach to easily reconfigure for this Expansion Interface.

The specific description is as follows:

```
## For RZ SBC U-Boot Env
/------------------------------|--------------|------------------------------
|       Config                 | Value if set |     To be loading
|------------------------------|--------------|------------------------------
| enable_overlay_i2c           | '1' or 'yes' |  rzpi-ext-i2c.dtbo
|------------------------------|--------------|------------------------------
| enable_overlay_spi           | '1' or 'yes' |  rzpi-ext-spi.dtbo
|------------------------------|--------------|------------------------------
| enable_overlay_can           | '1' or 'yes' |  rzpi-can.dtbo
|------------------------------|--------------|------------------------------
| enable_overlay_dsi           | '1' or 'yes' |  rzpi-dsi.dtbo
|------------------------------|--------------|------------------------------
| enable_overlay_csi_ov5640    | '1' or 'yes' |  rzpi-ov5640.dtbo
|----------------------------------------------------------------------------
| fdtfile   : is a base dtb file, should be set rzpi.dtb
|----------------------------------------------------------------------------
| uboot env : you could set U-Boot's environment variables here, such as 'console=' 'bootargs='
\---------------------------------------------------------------------------

default settings:
    fdtfile=rzpi.dtb
    #enable_overlay_i2c=1
    #enable_overlay_spi=1
    #enable_overlay_can=1
    #enable_overlay_dsi=1
    #enable_overlay_csi_ov5640=1
```

You can refer to the `readme.txt` file in `/boot` folder for the FDT overlays information.

After changing the value of overlays options, we need to run `sync` to ensure that the changes are affected. Then, execute `reboot` to apply the changes.

The below section shows how to configure for each GPIO function:

#### GPIO

System uses /sys/class/gpio to control the GPIO pin, please refer to the following table:

```
/-----------|---------------|-------|-----|-----------|-----|-------|---------------|-------------\
|   pinum   |   Function    | group | pin |   J3 PIN  | pin | group |   Function    |   pinum     |
|-----------|---------------|-------|-----|-----------|-----|-------|---------------|-------------|
|           |   3.3V        |       |     |   1   2   |     |       |   5V          |             |
|   490     |   RIIC3 SDA   |   46  |  2  |   3   4   |     |       |   5V          |             |
|   491     |   RIIC3 SCL   |   46  |  3  |   5   6   |     |       |   GND         |             |
|   304     |   GPIO        |   23  |  0  |   7   8   |  0  |   38  |   SCIF0 TX    |   424       |
|           |   GND         |       |     |   9   10  |  1  |   38  |   SCIF0 RX    |   425       |
|   456     |   GPIO        |   42  |  0  |   11  12  |  2  |   7   |   GPIO        |   178       |
|   336     |   GPIO        |   27  |  0  |   13  14  |     |       |   GND         |             |
|   345     |   GPIO        |   28  |  1  |   15  16  |  0  |   8   |   GPIO        |   184       |
|           |   3.3V        |       |     |   17  18  |  0  |   15  |   GPIO        |   240       |
|   465     |   RSPI0 MOSI  |   43  |  1  |   19  20  |     |       |   GND         |             |
|   466     |   RSPI0 MISO  |   43  |  2  |   21  22  |  1  |   14  |   GPIO        |   233       |
|   464     |   RSPI0 CK    |   43  |  0  |   23  24  |  3  |   43  |   RSPI0 SSL   |   467       |
|           |   GND         |       |     |   25  26  |  1  |   11  |   GPIO        |   209       |
|           |   RIIC0 SDA   |       |     |   27  28  |     |       |   RIIC0 SCL   |             |
|   152     |   GPIO        |   4   |  0  |   29  30  |     |       |   GND         |             |
|   153     |   GPIO        |   4   |  1  |   31  32  |  0  |   32  |   GPIO        |   376       |
|   297     |   GPIO        |   22  |  1  |   33  34  |     |       |   GND         |             |
|   457     |   CAN0 TX     |   42  |  1  |   35  36  |  1  |   23  |   GPIO        |   305       |
|   208     |   CAN0 RX     |   11  |  0  |   37  38  |  0  |   46  |   CAN1 TX     |   488       |
|           |   GND         |       |     |   39  40  |  1  |   46  |   CAN1 RX     |   489       |
\-----------|---------------|-------|-----|-----------|-----|-------|---------------|-------------/
```

pinum = $group * $groupin + $pin + $pinbase (where pinbase=120, groupin=8)

Example for J3 PIN 7:
                              23*8 + 0 + 120 = 304 = pinum

To set GPIO pin, move to GPIO sysfs directory and set values as shown below:

```
root@localhost:~# cd /sys/class/gpio/
root@localhost:~# echo 304 > export
root@localhost:~# echo out > P23_0/direction
root@localhost:~# echo 1 > P23_0/value
root@localhost:~# echo 0 > P23_0/value
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
        Name: 'rzpi'
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
192.168.0.100 rzpi.example.com rzpi

# The following lines are desirable for IPv6 capable hosts
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

Now, we will change the hostname of our machine as follows:

```bash
sudo echo rzpi > /etc/hostname 
sudo hostname rzpi
```

The first command sets the hostname "rzpi" in the /etc/hostname file. This file is read by the system at boot time. The second command sets the hostname in the current session so we don't have to restart the server to apply the hostname.

As an alternative to the two commands above you can use the hostnamectl command which is part of the systemd package.

```bash
sudo hostnamectl set-hostname rzpi
```

Afterward, run:

```bash
hostname
hostname -f
```

The first command returns the short hostname while the second command shows the fully qualified domain name:
```bash
root@rzpi:/home/root# hostname
rzpi
root@rzpi:/home/root# hostname -f
rzpi.example.com
root@rzpi:/home/root#
```
