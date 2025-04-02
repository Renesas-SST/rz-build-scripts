#!/bin/bash
# ------------------------------------------------------------------------------------------#
# This script is intended to be run inside a chroot environment to install ROS2 packages as
# well as dependency packages and perform system updates. It first checks if the script is 
# executed as root, updates the package list, and installs various required utilities and packages.
# ------------------------------------------------------------------------------------------#

export LC_ALL=C
chmod 777 /tmp
apt update
apt clean
apt autoclean
apt upgrade -y
apt update

# Set DEBIAN_FRONTEND globally
export DEBIAN_FRONTEND=noninteractive

# 1. Setup locale
apt update && apt install locales -y
locale-gen en_US en_US.UTF-8
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# 2. Enable required repositories
# Ensure that the Ubuntu Universe repository is enabled properly.
apt update && apt install software-properties-common -y
add-apt-repository universe -y

# Add the ROS 2 GPG key with apt
apt update && apt install curl -y
curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

# Add the repository to your sources list
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Install development tools
apt update && apt install ros-dev-tools -y

# 3. Install ROS2
# INSTALL ROS2 JAZZY
apt update && apt upgrade -y
apt install ros-jazzy-ros-base -y

# Install colcon and other dependencies
apt install python3-colcon-common-extensions -y # colcon
apt install python3-rosdep -y # rosdep
rosdep init
sudo -u rzpi rosdep update

# Notify
echo "ROS2 installation complete!"