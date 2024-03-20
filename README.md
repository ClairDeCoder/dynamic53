# Dynamic53
A self-hosted DDNS solution for Route 53 hosted domains, for use on Ubuntu/Debian servers and desktops

## Features

- **Support for Multiple A Records**: Easily configure multiple A records to be updated simultaneously.
- **Automated IP Checking**: Periodically checks the public IP and updates DNS records if a change is detected.
- **AWS Credentials Handling**: Utilizes existing AWS credentials when available; prompts for manual input if not.
- **Robust Logging**: Detailed logging for monitoring updates and troubleshooting issues.
- **Ease of Installation**: Comes with a Bash installation script to automate setup and dependency management.
- **Security Aware**: If not utilizing AWS CLI credentials, Dynamic53 will securely store your input credentials into a hidden file that only the Dynamic53 (no-login) user has access to.

## Prerequisites

- Python 3.x
- pip (Python package installer)
- AWS account and Route 53 hosted domain(s)
- IAM user with Access ID & Secret Access Key

## Installation (CLONE)

1. Clone this repository to your local machine or server:
   ```bash
   git clone https://github.com/ClairDeCoder/dynamic53.git
2. Change directories into the new dynamic53 folder:
   ```bash
   cd dynamic53/
3. Make install.sh executable:
   ```bash
   sudo chmod +x install.sh
4. Run install:
   ```bash
   sudo ./install.sh

# Installation (Compressed Download)

1. Download the tar.gz file with the link below for graphical systems:  
   https://github.com/ClairDeCoder/dynamic53/files/14663107/dynamic53.tar.gz  
   **OR**  
   For headless (terminal only):
   ```bash
   wget https://github.com/ClairDeCoder/dynamic53/files/14663107/dynamic53.tar.gz
2. Unzip the file:
   ```bash
   tar -xvzf dynamic53.tar.gz
3. Change directories:
   ```bash
   cd dynamic53
4. Set install command to execute:
   ```bash
   sudo chmod +x ./install.sh
5. Run install:
   ```bash
   sudo ./install.sh

# Usage

After installation, Dynamic53 will run as a service, automatically checking and updating your DNS records based on the configured interval. This program was built for Ubuntu & Debian, based as a systemd service.

1. You can view the logs for detailed information about the service's operations:
   ```bash
   sudo tail -f /opt/ddns_updater/dynamic53.log
   ```
   **OR**
   ```bash
   sudo cat /opt/ddns_updater/dynamic53.log
2. You can change your A records or AWS credentials anytime by editing the configuration:
   ```bash
   sudo nano /opt/ddns_updater/.config.json
   ```
   **OR**
   ```bash
   sudo vi /opt/ddns_updater/.config.json
4. You can check the service status of Dynamic53:
   ```bash
   sudo systemctl status dynamic53.service
5. The directory for the program is located in:
   ```bash
   /opt/ddns_updater/*
6. The systemd service file is located in:
   ```bash
   /etc/systemd/system/dynamic53.service
7. You can easily uninstall Dynamic53 with the uninstall script built into the program directory:
   ```bash
   sudo /opt/ddns_updater/uninstall.sh

# Contributing

Contributions to Dynamic53 are welcome! Please feel free to submit issues, enhancements requests, and pull requests through the GitHub repository.

# License

Dynamic53 is released under the MIT License.
