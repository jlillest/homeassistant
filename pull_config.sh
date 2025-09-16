#!/bin/bash

# --- VARIABLES ---
# Path to your Home Assistant configuration directory.
# This should be the same path you used when setting up the Docker container.
CONFIG_DIR="/home/pi/homeassistant/config"

# --- MAIN SCRIPT ---

echo "Starting Home Assistant configuration update process..."

# 1. Update Home Assistant Core
echo "Checking for Home Assistant Core updates..."
# This command pulls the latest image from Docker Hub.
docker pull homeassistant/home-assistant:stable

# 2. Update Configuration from Git
echo "Pulling latest configuration from Git repository..."
cd "$CONFIG_DIR"
git pull

# 3. Restart the Home Assistant Container
echo "Restarting Home Assistant container to apply changes..."
# The --name should match the name of your container.
docker restart homeassistant

echo "Update process complete."