# dynamic53
A self-hosted DDNS solution for Route 53 hosted domains

## Features

- **Support for Multiple A Records**: Easily configure multiple A records to be updated simultaneously.
- **Automated IP Checking**: Periodically checks the public IP and updates DNS records if a change is detected.
- **AWS Credentials Handling**: Utilizes existing AWS credentials when available; prompts for manual input if not.
- **Robust Logging**: Detailed logging for monitoring updates and troubleshooting issues.
- **Ease of Installation**: Comes with a Bash installation script to automate setup and dependency management.

## Prerequisites

- Python 3.x
- pip (Python package installer)
- AWS account and Route 53 hosted domain(s)

## Installation

1. Clone this repository to your local machine or server:
   ```bash
   git clone https://github.com/ClairDeCoder/dynamic53.git
