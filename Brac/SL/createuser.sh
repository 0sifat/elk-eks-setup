#!/bin/bash

SLACK_WEBHOOK="$1"
SCRIPT_OWNER="$2"
SCRIPT_OWNER="Sifat Shaharia"
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')


echo "🔧 What do you want to do?"
echo "1) Create new user(s)"
echo "2) Change password of existing user"
read -p "Choose an option (1 or 2): " action

# === CREATE NEW USERS ===
if [[ "$action" == "1" ]]; then
  while true; do
    read -p "👤 Enter a username to create: " username

    if id "$username" &>/dev/null; then
      echo "❌ User '$username' already exists."
    else
      sudo adduser "$username"
      sudo usermod -aG sudo "$username"
      sudo usermod -aG wheel "$username"
      echo "✅ User '$username' added to 'sudo' and 'wheel' groups."
      echo "🔐 Set password for $username:"
      sudo passwd "$username"
    fi

    read -p "Do you want to create another user? (yes/no): " another
    [[ "$another" =~ ^(no|n)$ ]] && break
  done

# === CHANGE PASSWORD OF EXISTING USER ===
elif [[ "$action" == "2" ]]; then
  echo "👥 Available users:"
  cut -d: -f1 /etc/passwd | grep -vE '^(sync|shutdown|halt|nobody|dbus|systemd|root|bin|daemon|adm|lp|mail|news|uucp|operator|games|gopher|ftp|nfsnobody)$'

  read -p "Enter the username to change password: " target_user
  if id "$target_user" &>/dev/null; then
    echo "🔐 Changing password for $target_user:"
    sudo passwd "$target_user"
  else
    echo "❌ User '$target_user' does not exist."
    exit 1
  fi

else
  echo "🚫 Invalid option selected."
  exit 1
fi

# === SSH CONFIGURATION FIX ===

echo "🔧 Updating /etc/ssh/sshd_config..."
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

echo "🔧 Updating /etc/ssh/sshd_config.d/60-cloudimg-settings.conf..."
if [ -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf ]; then
  sudo sed -i 's/^/#/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
  echo "PasswordAuthentication yes" | sudo tee /etc/ssh/sshd_config.d/60-cloudimg-settings.conf > /dev/null
fi

# Restart ssh service
echo "🔁 Restarting SSH service..."
sudo systemctl restart sshd


SLACK_MESSAGE=":rocket: *User information Updated Successfully!*%0A
*👨‍💻 Script Owner:* $SCRIPT_OWNER%0A
*🖥️ Host:* $HOSTNAME%0A
*🕒 Time:* $TIMESTAMP"


echo "✅ All done. SSH password login is enabled. Enjoy your Day!"