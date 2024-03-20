#!/bin/bash

# Ensure running as root
if [ "$(id -u)" -ne "0" ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Variables
SERVICE_USER="ddns_user"
SERVICE_FILE="/etc/systemd/system/dynamic53.service"
INSTALL_DIR="/opt/ddns_updater"

# Stop the service
systemctl stop dynamic53.service

# Disable the service
systemctl disable dynamic53.service > /dev/null 2>&1

# Remove the systemd service file
rm -f "$SERVICE_FILE"

# Reload systemd
systemctl daemon-reload

# Remove the dedicated user
userdel -r "$SERVICE_USER" > /dev/null 2>&1

# Execute removal of dir after script is done running (preventing conflicts)
nohup sh -c "sleep 5; rm -rf \"$INSTALL_DIR\"" &> /dev/null &

echo "Uninstall complete. Dynamic53 has been removed from your system."
