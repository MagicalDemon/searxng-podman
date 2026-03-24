#!/bin/bash
# Filename: install_serxng_fedora_42_plus.sh
# Created: 21th June, 2024
# Updated: 15th March, 2026
# Description: This script automates the installation and setup of SearXNG using Podman on Fedora 42 or greater versions.
# It includes steps to update the system, install Podman, pull the SearXNG Docker image, create necessary
# configuration files, run the SearXNG container with the correct port mapping, and set up a systemd service
# to ensure the container starts automatically on system boot.

# Update system
sudo dnf update -y

# Install Podman
sudo dnf install -y podman

# Verify Podman installation
podman --version

# Pull the SearXNG Docker image
podman pull docker.io/searxng/searxng:latest

# Create a directory for SearXNG configuration in your home directory
mkdir -p ~/searxng/settings

# Create a configuration file with default settings
curl -o ~/searxng/settings/settings.yml https://raw.githubusercontent.com/searxng/searxng/refs/heads/master/searx/settings.yml

# Comment the secret_key line in the settings.yml file
sed -i 's/secret_key: "ultrasecretkey"  # Is overwritten by ${SEARXNG_SECRET}/# &/' ~/searxng/settings/settings.yml

# Run the SearXNG container with correct port mapping
podman run -d --name searxng -p 8888:8080 -v ~/searxng/settings/settings.yml:/etc/searxng/settings.yml:Z docker.io/searxng/searxng:latest

# Verify the container is running
podman ps

# Create Quadlets file for searxng
mkdir -p ~/.config/systemd/user 

# Create a systemd service file for the SearXNG container
sudo tee ~/.config/containers/systemd/searxng.container > /dev/null <<'EOF'
[Unit]
Description=SearXNG container
After=network-online.target
Wants=network-online.target

[Container]
Image=docker.io/searxng/searxng:latest
ContainerName=searxng
PublishPort=8888:8080
Volume=%h/searxng/settings/settings.yml:/etc/searxng/settings.yml:Z

[Service]
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF


# Reload systemd to recognize the new service
sudo systemctl --user daemon-reload

# Starting the service will enable the SearXNG service to start on boot
sudo systemctl --user start degoog.service

# Fetch the server's hostname
hostname=$(hostname)

# Output the URL to access SearXNG
echo "SearXNG is running. Access it at http://$hostname:8888/"

# Credit to the original file owner https://gist.github.com/ParkWardRR/602e01042aceedc882972bb3ec5c1e4f