#!/bin/bash

SLACK_WEBHOOK="$1"
SCRIPT_OWNER="$2"
SCRIPT_OWNER="Sifat Shaharia"
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Must run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root or with sudo."
  exit 1
fi

read -p "📥 Enter the new SSH port number (1024-65535): " new_port

# Validate port number
if ! [[ "$new_port" =~ ^[0-9]+$ ]] || [ "$new_port" -lt 1024 ] || [ "$new_port" -gt 65535 ]; then
  echo "⚠️ Invalid port. Please enter a number between 1024 and 65535."
  exit 1
fi

# Backup sshd_config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
echo "📦 Backup created at /etc/ssh/sshd_config.bak"

# Update or add the Port entry
if grep -q "^#*Port " /etc/ssh/sshd_config; then
  sed -i "s/^#*Port .*/Port $new_port/" /etc/ssh/sshd_config
else
  echo "Port $new_port" >> /etc/ssh/sshd_config
fi

# Restart SSH
echo "🔁 Restarting SSH service..."
if systemctl restart sshd; then
  echo "✅ SSH port changed to $new_port and service restarted."
else
  echo "❌ Failed to restart SSH. Reverting changes..."
  mv /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
  systemctl restart sshd
  exit 1
fi

SLACK_MESSAGE=":rocket: *SSH Port information Updated Successfully!*%0A
*👨‍💻 Script Owner:* $SCRIPT_OWNER%0A
*🖥️ Host:* $HOSTNAME%0A
*🕒 Time:* $TIMESTAMP"


# Show new listening port
echo "📡 Current SSH listening ports:"
ss -tuln | grep ssh

