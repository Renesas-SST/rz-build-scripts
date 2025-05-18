#!/bin/bash
##############################################################################
# This script to create the service in systemd
# The service will run a shell script to set the permissions of sudo files
##############################################################################

# Variables for file paths
SERVICE_FILE="/etc/systemd/system/set-permissions.service"
SCRIPT_FILE="/usr/local/bin/set-permissions.sh"

# Content for the service file
# This service will run the shell script to set the permissions of sudo files
SERVICE_CONTENT="[Unit]
Description=Set sudo permissions after boot
After=network.target

[Service]
Type=oneshot
ExecStart=${SCRIPT_FILE}

[Install]
WantedBy=multi-user.target
"

# Content for the script file
# This script will set the permissions of sudo files
SCRIPT_CONTENT="#!/bin/bash
chown root:root /usr/libexec/sudo/sudoers.so
chown root:root /etc/sudo.conf
chown root:root /etc/sudoers

chown root:root /etc/sudoers.d
chown root:root /etc/sudoers.d/README

chown root:root /usr/bin/sudo
chmod 4755 /usr/bin/sudo
"

# Create the systemd service file
echo "Creating systemd service file at $SERVICE_FILE"
echo "$SERVICE_CONTENT" | sudo tee "$SERVICE_FILE" > /dev/null

# Create the shell script
echo "Creating shell script at $SCRIPT_FILE"
echo "$SCRIPT_CONTENT" | sudo tee "$SCRIPT_FILE" > /dev/null

# Make the shell script executable
echo "Making the shell script executable"
sudo chmod +x "$SCRIPT_FILE"

# Reload systemd to apply the new service
echo "Reloading systemd daemon"
sudo systemctl daemon-reload

# Enable the service to run on boot
echo "Enabling the systemd service"
sudo systemctl enable set-permissions.service

echo "Setup complete. "
