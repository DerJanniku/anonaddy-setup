# AnonAddy Setup - Hardened & Automated

This repository provides a comprehensive, automated, and hardened setup for self-hosting AnonAddy on a Debian or Ubuntu server. The script is designed to be modular, allowing you to enable or disable features based on your needs.

## Features

- **Automated Installation**: Deploys AnonAddy with a single script.
- **Hardened Security**: Implements best practices for securing your server.
- **Dockerized Environment**: Uses Docker and Docker Compose for easy management.
- **Reverse Proxy with SSL**: Integrates Traefik for automatic SSL certificate generation via Let's Encrypt.
- **Dynamic DNS Support**: Includes support for DuckDNS and Cloudflare.
- **Firewall Configuration**: Sets up UFW with sensible defaults.
- **Intrusion Prevention**: Configures Fail2Ban to protect against brute-force attacks.
- **Automated Backups**: Creates daily backups of your AnonAddy data.
- **System Monitoring**: Installs Netdata for real-time server monitoring.
- **Container Updates**: Uses Watchtower to automatically update your Docker containers.
- **TOR Hardening**: Includes options to harden your server's TOR configuration.
- **IP Blacklisting**: Automatically updates IP blacklists to block malicious actors.

## Prerequisites

- A fresh Debian or Ubuntu server.
- A domain name (or a DuckDNS/Cloudflare account).
- Root access to your server.

## Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/anonaddy-setup.git
    cd anonaddy-setup
    ```

2.  **Configure your setup:**
    Copy the example configuration file:
    ```bash
    cp config.env.example config.env
    ```
    Now, edit `config.env` with your desired settings.

3.  **Make the installation script executable:**
    ```bash
    chmod +x install.sh
    ```

4.  **Run the installation script:**
    ```bash
    sudo ./install.sh
    ```

## Configuration

All configuration is done in the `config.env` file. Here's an overview of the available options:

| Variable                 | Description                                                                 |
| ------------------------ | --------------------------------------------------------------------------- |
| `DOMAIN`                 | Your primary domain for AnonAddy.                                           |
| `EMAIL`                  | Your email address for Let's Encrypt notifications.                         |
| `USE_DUCKDNS`            | Set to `true` to use DuckDNS for dynamic DNS.                               |
| `DUCKDNS_DOMAIN`         | Your DuckDNS domain.                                                        |
| `DUCKDNS_TOKEN`          | Your DuckDNS token.                                                         |
| `USE_CLOUDFLARE`         | Set to `true` to use Cloudflare for DNS updates.                            |
| `CF_API_TOKEN`           | Your Cloudflare API token.                                                  |
| `CF_ZONE_ID`             | Your Cloudflare Zone ID.                                                    |
| `CF_RECORD_NAME`         | The DNS record to update in Cloudflare.                                     |
| `ENABLE_UFW`             | Set to `true` to enable and configure UFW.                                  |
| `ENABLE_FAIL2BAN`        | Set to `true` to install and configure Fail2Ban.                            |
| `ENABLE_TRAEFIK`         | Set to `true` to deploy Traefik as a reverse proxy.                         |
| `ENABLE_ANONADDY`        | Set to `true` to deploy AnonAddy.                                           |
| `ENABLE_WATCHTOWER`      | Set to `true` to deploy Watchtower for automatic container updates.         |
| `ENABLE_BACKUP`          | Set to `true` to enable daily backups.                                      |
| `ENABLE_MONITORING`      | Set to `true` to install Netdata for monitoring.                            |
| `ENABLE_TOR_HARDEN`      | Set to `true` to apply TOR hardening settings.                              |
| `ENABLE_IP_BLACKLIST`    | Set to `true` to enable automatic IP blacklisting.                          |
| `BACKUP_DIR`             | The directory where backups will be stored.                                 |

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)
