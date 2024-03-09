#!/bin/env/python

import requests, ipaddress, boto3, json, logging, time
from pathlib import Path

# Configuration path
config_path = Path('./.config.json')
# Path to store the last known IP
last_ip_path = Path('./last_ip.txt')
# Log file
log_file = Path('./dynamic53.log')

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                    handlers=[logging.FileHandler(log_file), logging.StreamHandler()])

def trim_log_file(log_file_path, max_lines=500):
    try:
        with open(log_file_path, 'r') as file:
            lines = file.readlines()

        if len(lines) > max_lines:
            with open(log_file_path, 'w') as file:
                file.writelines(lines[-max_lines:])
    except Exception as e:
        print(f"Error trimming log file: {e}")

def load_config(config_path):
    try:
        with open(config_path) as config_file:
            return json.load(config_file)
    except FileNotFoundError:
        logging.error(f'Configuration file not found at {config_path}. Exiting...')
        exit(1)
    except json.JSONDecodeError:
        logging.error('Error decoding the configuration file. Please check its format.')
        exit(1)

def save_last_ip(ip, path):
    with open(path, 'w') as file:
        file.write(ip)

def load_last_ip(path):
    if not path.is_file():
        path.touch()
        return None
    try:
        with open(path) as file:
            return file.read().strip()
    except Exception:
        return None

def get_public_ip(services):
    for service in services:
        try:
            response = requests.get(service['url'], timeout=5)
            if service['response_type'] == 'json':
                ip = response.json().get(service['json_key'])
            else:
                ip = response.text.strip()

            if ip and is_valid_ip(ip):
                logging.info(f'Valid IP retrieved from {service["url"]}: {ip}')
                return ip
            else:
                continue
        except requests.RequestException as e:
            logging.warning(f"Error accessing {service['url']}: {e}")
            continue
    logging.error('Failed to retrieve public IP from all services.')
    return None

def is_valid_ip(ip_str):
    try:
        ipaddress.ip_address(ip_str)
        return True
    except ValueError:
        return False

def update_dns_records(config, public_ip):
    route53 = boto3.client(
        'route53',
        aws_access_key_id=config['aws_credentials']['access_key'],
        aws_secret_access_key=config['aws_credentials']['secret_key']
    )
    for record in config['records']:
        try:
            response = route53.change_resource_record_sets(
                HostedZoneId=config['zone_id'],
                ChangeBatch={
                    'Comment': 'Update via DDNS Script',
                    'Changes': [{
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': record['name'],
                            'Type': record['type'],
                            'TTL': record['ttl'],
                            'ResourceRecords': [{'Value': public_ip}]
                        }
                    }]
                }
            )
            logging.info(f"Updated DNS record for {record['name']} to {public_ip}. Response: {response['ChangeInfo']['Status']}")
            # Check if DNS record is updated
            time.sleep(5)
            if not check_dns_record_update(route53, config['zone_id'], record['name'], public_ip):
                logging.error(f"DNS record for {record['name']} not updated to {public_ip} yet.")
            else:
                logging.info(f"DNS record for {record['name']} successfully updated to {public_ip}.")  

        except Exception as e:
            logging.error(f"Failed to update DNS record for {record['name']}: {e}")

def check_dns_record_update(route53, hosted_zone_id, record_name, expected_ip):
    try:
        response = route53.list_resource_record_sets(HostedZoneId=hosted_zone_id)
        for record_set in response['ResourceRecordSets']:
            if record_set['Name'] == record_name + '.' and record_set['Type'] == 'A':
                current_ip = record_set['ResourceRecords'][0]['Value']
                return current_ip == expected_ip
    except Exception as e:
        logging.error(f"Error checking DNS record update for {record_name}: {e}")
    return False

def main_loop(config, services, check_interval):
    while True:
        last_ip = load_last_ip(last_ip_path)
        public_ip = get_public_ip(services)
        if public_ip and public_ip != last_ip:
            update_dns_records(config, public_ip)
            save_last_ip(public_ip, last_ip_path)
        elif public_ip == last_ip:
            logging.info('Public IP has not changed. No update needed.')
        else:
            logging.error('Failed to obtain a valid public IP.')
        trim_log_file(log_file)
        time.sleep(check_interval)

if __name__ == '__main__':
    config = load_config(config_path)
    services = config.get('services', [])
    check_interval = config.get('check_interval')
    main_loop(config, services, check_interval)
