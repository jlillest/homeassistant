#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting Home Assistant Kiosk setup..."

# --- Step 1: Update and Upgrade the System ---
echo "Updating and upgrading system packages..."
sudo apt update
sudo apt upgrade -y

# --- Step 2: Install Docker ---
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# --- Step 3: Install Home Assistant Core in Docker ---
echo "Installing Home Assistant Core in a Docker container..."
echo "Please enter your timezone (e.g., America/New_York):"
TIMEZONE="America/New_York"

echo "Creating Home Assistant configuration directory..."
mkdir -p "$HOME/homeassistant/config"

docker run -d \
    --name homeassistant \
    --restart unless-stopped \
    --privileged \
    -v "$HOME/homeassistant/config":/config \
    -e TZ="$TIME_ZONE" \
    -p 8123:8123 \
    homeassistant/home-assistant:stable

echo "Waiting for Home Assistant to start (this may take a few minutes)..."
sleep 60

# --- Step 4: Configure Kiosk Mode and Autostart ---
echo "Configuring Chromium for kiosk mode..."

# Create autostart directory if it doesn't exist
mkdir -p "$HOME/.config/lxsession/LXDE-pi"

# Create or overwrite the autostart file
cat <<EOF > "$HOME/.config/lxsession/LXDE-pi/autostart"
@lxpanel --profile LXDE-pi
@pcmanfm --profile LXDE-pi
@xset s off
@xset -dpms
@xset noblank
@chromium-browser --no-touch-feedback --noerrdialogs --kiosk http://homeassistant.local:8123
EOF

# Add configuration update script
UPDATE_SCRIPT=/home/pi/homeassistant/pull_config.sh
LOG_FILE=/var/log/homeassistant_update.log
CRON_JOB="0 * * * * $UPDATE_SCRIPT >> $LOG_FILE 2>&1"

# Get the current crontab and store it in a temporary file.
crontab -l > /tmp/crontab_temp.txt

# Check if the cron job already exists to avoid duplication.
if grep -qF -- "$CRON_JOB" /tmp/crontab_temp.txt; then
  echo "Cron job already exists. No action needed."
  rm /tmp/crontab_temp.txt
  exit 0
fi

# Add a newline to the temporary file for proper formatting.
echo "" >> /tmp/crontab_temp.txt

# Append the new cron job to the temporary file.
echo "$CRON_JOB" >> /tmp/crontab_temp.txt

# Overwrite the existing crontab with the updated file.
crontab /tmp/crontab_temp.txt

# Remove the temporary file.
rm /tmp/crontab_temp.txt

echo "Cron job successfully added."

echo "Setup complete! Please reboot the device to see the changes."
echo "You can access your Home Assistant dashboard from another device at http://homeassistant.local:8123."
