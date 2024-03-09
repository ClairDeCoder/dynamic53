#!/bin/bash

# Script and config file names
SCRIPT_NAME="dynamic53.py"
CONFIG_NAME=".config.json"

# Installation directory
INSTALL_DIR="/opt/ddns_updater"

# Ensure running as root
if [ "$(id -u)" -ne "0" ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Install Python3 and pip if they're not already installed
apt-get update
apt-get install -y python3 python3-pip

# Install required Python packages
pip3 install boto3 requests
echo ""

# Check for AWS credentials
if [ -f "$HOME/.aws/credentials" ]; then
    echo "AWS credentials file found."
    ACCESS_KEY=$(grep -oP 'aws_access_key_id\s*=\s*\K(.*)' "$HOME/.aws/credentials")
    SECRET_KEY=$(grep -oP 'aws_secret_access_key\s*=\s*\K(.*)' "$HOME/.aws/credentials")
else
    echo "AWS credentials file not found. Please enter your AWS credentials."
    read -p "AWS Access Key ID: " ACCESS_KEY
    read -p "AWS Secret Access Key: " SECRET_KEY
    echo
fi

# Ask for hosted zone ID and other inputs
read -p "Enter your Route 53 hosted zone ID: " ZONE_ID
read -p "Enter check interval in seconds (default is 900): " CHECK_INTERVAL
read -p "How many A records do you want to configure? " NUM_RECORDS

# Prepare configuration
CONFIG="{\"aws_credentials\": {\"access_key\": \"$ACCESS_KEY\", \"secret_key\": \"$SECRET_KEY\"}, \"check_interval\": $CHECK_INTERVAL, \"zone_id\": \"$ZONE_ID\", \"records\": ["

for ((i=1; i<=NUM_RECORDS; i++)); do
    read -p "Enter domain name for A record #$i: " DOMAIN_NAME
    CONFIG="$CONFIG {\"name\": \"$DOMAIN_NAME\", \"type\": \"A\", \"ttl\": 300}"
    if [ "$i" -lt "$NUM_RECORDS" ]; then
        CONFIG="$CONFIG,"
    fi
done

CONFIG="$CONFIG ], \"services\": [{\"url\": \"https://ifconfig.me\", \"response_type\": \"text\"}, {\"url\": \"http://httpbin.org/ip\", \"response_type\": \"json\", \"json_key\": \"origin\"}, {\"url\": \"http://ipecho.net/plain\", \"response_type\": \"text\"}]}"

# Create installation directory, move script, and write configuration
mkdir -p "$INSTALL_DIR"
cp "$(dirname "$0")/$SCRIPT_NAME" "$INSTALL_DIR"
echo $CONFIG > "$INSTALL_DIR/$CONFIG_NAME"

# Create a systemd service file
SERVICE_FILE="/etc/systemd/system/dynamic53.service"
echo "[Unit]
Description=Dynamic53 DDNS Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/env python3 $INSTALL_DIR/$SCRIPT_NAME
WorkingDirectory=$INSTALL_DIR
Restart=on-failure

[Install]
WantedBy=multi-user.target" > $SERVICE_FILE

# Enable and start the service
systemctl daemon-reload
systemctl enable dynamic53.service
systemctl start dynamic53.service

echo "Dynamic53 installed and started successfully."

# Cleanup
echo "Would you like to remove the installer and original script files? This cannot be undone. [y/N]"
read -p "Proceed with cleanup? " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    rm -- "$0"  # Remove this installer script
    rm -- "$(dirname "$0")/$SCRIPT_NAME"  # Remove the original dynamic53.py script
    echo "Cleanup completed."
else
    echo "Cleanup skipped."
fi
