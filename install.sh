#!/bin/bash

# Script/Config
SCRIPT_NAME="dynamic53.py"
CONFIG_NAME=".config.json"
UNINSTALL_NAME="uninstall.sh"

# Install directory
INSTALL_DIR="/opt/ddns_updater"

# Dedicated user
SERVICE_USER="ddns_user"

# Ensure running as root
if [ "$(id -u)" -ne "0" ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Create a dedicated user for running the script
useradd -m -d "$INSTALL_DIR" -s /usr/sbin/nologin "$SERVICE_USER"

# Install Python3 and pip if they're not already installed
echo "Updating repos..."
apt-get update > /dev/null 2>&1
echo "Confirming Python installation..."
apt-get install -y python3 python3-pip > /dev/null 2>&1

# Install required Python packages
echo "Getting necessary modules..."
pip3 install boto3 requests > /dev/null 2>&1
echo ""

# Check for AWS credentials
if [ -f "$HOME/.aws/credentials" ]; then
    echo "AWS credentials file found! Let's go!"
    ACCESS_KEY=$(grep -oP 'aws_access_key_id\s*=\s*\K(.*)' "$HOME/.aws/credentials")
    SECRET_KEY=$(grep -oP 'aws_secret_access_key\s*=\s*\K(.*)' "$HOME/.aws/credentials")
else
    echo "AWS credentials file not found. Please enter your AWS credentials."
    read -p "AWS Access Key ID: " ACCESS_KEY
    read -p "AWS Secret Access Key: " SECRET_KEY
    echo
fi

# Ask for hosted zone ID, timer, and records
read -p "Enter your Route 53 hosted zone ID: " ZONE_ID
read -p "Enter check interval in seconds (default is 900): " CHECK_INTERVAL
read -p "How many A records do you want to configure? " NUM_RECORDS

# Prep configuration
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
mv "$(dirname "$0")/*" "$INSTALL_DIR"
echo $CONFIG > "$INSTALL_DIR/$CONFIG_NAME"

# Change ownership of the directory to dedicated user
chown -R "$SERVICE_USER":"$SERVICE_USER" "$INSTALL_DIR"

# Secure directory and configuration file
chmod 700 "$INSTALL_DIR"
chmod 600 "$INSTALL_DIR/$CONFIG_NAME"

# Setup uninstall script
mv "$(dirname "$0")/$UNINSTALL_NAME" "$INSTALL_DIR"
chmod 700 "$INSTALL_DIR/$UNINSTALL_NAME"
chown root:root "$INSTALL_DIR/$UNINSTALL_NAME"

# Create a systemd service
SERVICE_FILE="/etc/systemd/system/dynamic53.service"
echo "[Unit]
Description=Dynamic53 DDNS Service
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
ExecStart=/usr/bin/env python3 $INSTALL_DIR/$SCRIPT_NAME
WorkingDirectory=$INSTALL_DIR
Restart=on-failure

[Install]
WantedBy=multi-user.target" > $SERVICE_FILE

# Enable and start the service
systemctl daemon-reload
systemctl enable dynamic53.service > /dev/null 2>&1
systemctl start dynamic53.service

# Cleanup
echo "Cleaning up the mess"
rm -- "$0"
rm -- "$(dirname "$0")/$SCRIPT_NAME"
echo ""
echo -e "Congrats! You've made it! Dynamic53 has been successfully installed.\n\nPlease view the README file for details on logs and configurations @ https://github.com/ClairDeCoder"
