echo "Enabling and starting systemd service..."
systemctl enable systemd-resolved.service
systemctl enable systemd-timesyncd
systemctl start systemd-resolved.service
systemctl start systemd-timesyncd

rm -f /etc/resolv.conf
ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
