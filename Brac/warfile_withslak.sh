#!/bin/bash

# === DECLARATION MESSAGE ===
echo "***************************************************************"
echo "⚠️ WARNING: This script must be run from the server:"
echo "  Server: Training-sbicloud"
echo "  IP Address: 52.66.13.94"
echo "***************************************************************"
read -p "Are you sure you want to proceed? (yes/no): " confirmation

if [[ "$confirmation" != "yes" ]]; then
  echo "Aborting script. Please run this script from the correct server."
  exit 1
fi

# === SLACK CONFIG ===
# SLACK_WEBHOOK="$1"
# SCRIPT_OWNER="$2"
# SCRIPT_OWNER="Sifat Shaharia"
# HOSTNAME=$(hostname)
# TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# === VARIABLES ===
WAR_FILE="ROOT.war"
BACKUP_DIR="war-backup"
SOURCE_SERVER_IP="15.206.49.232"   # Source server where the WAR file exists
TARGET_IP="52.66.13.94"
MYSQL_DBIP="13.126.173.220"
TARGET_USER="centos"
TARGET_PATH="/home/centos/"
SSH_KEY="/home/centos/.ssh/id_rsa"   # Correct private key file
PORT=222
TOMCAT_DIR="/bits/sbicloud/HRT-tomcat9010"
DEPLOY_DIR="$TOMCAT_DIR/webapps"
CONFIG_FILE="$TOMCAT_DIR/lib/sbicloud-config.groovy"
DATE=$(date +%Y_%m_%d)

# === CHECK ROOT ===
if [[ $EUID -ne 0 ]]; then
  echo "Run as root using sudo."
  exit 1
fi

# === STEP 1: Add Remote Host to Known Hosts ===
# Ensure the server is in known_hosts to prevent the warning
echo "Adding remote server to known hosts..."
ssh-keyscan -p $PORT $TARGET_IP >> ~/.ssh/known_hosts

# === STEP 2: Transfer WAR from Source Server ===
echo "Transferring $WAR_FILE from $SOURCE_SERVER_IP to $TARGET_IP..."
scp -i "$SSH_KEY" -P $PORT "$TARGET_USER@$SOURCE_SERVER_IP:/bits/sbicloud/MS-tomcat9090/webapps/$WAR_FILE" "$TARGET_USER@$TARGET_IP:$TARGET_PATH"

# if [[ $? -eq 0 ]]; then
#   echo "WAR file transferred from $SOURCE_SERVER_IP to $TARGET_IP"
#   ssh -i "$SSH_KEY" -p $PORT "$TARGET_USER@$TARGET_IP" "echo 'Access successful.'" >/dev/null 2>&1
#   [[ $? -eq 0 ]] && echo "SSH access confirmed" || echo "Unable to SSH into $TARGET_IP"
# else
#   echo "WAR transfer failed"
#   exit 1
# fi

# === STEP 3: Backup Database (Optional) ===
read -p "Do you want to take a backup of the database from the backup location? (yes/no): " backup_choice

if [[ "$backup_choice" == "yes" ]]; then
  echo "Logging into the system user 'centos' on IP $"
  ssh -i "$SSH_KEY" -p $PORT "$TARGET_USER@$MYSQL_DBIP" <<EOF
    sudo su
    cd /production-data/backup/dbbackup/master/db/
    echo "Printing list of backup files..."
    ls -lh
    echo "Please select a backup file to copy to the server."
    read -p "Enter the backup filename: " backup_filename
    echo "Copying $backup_filename to $TARGET_PATH on the server..."
    scp "$backup_filename" "$TARGET_USER@$TARGET_IP:$TARGET_PATH" // need to acces the server using 222 port
EOF
fi

# === STEP 4: Shutdown Tomcat ===
cd "$TOMCAT_DIR" || { echo "Tomcat directory not found"; exit 1; }
echo "Shutting down Tomcat..."
./bin/shutdown.sh

# === STEP 5: Backup Old WAR ===
cd "$DEPLOY_DIR" || { echo "Webapps directory not found"; exit 1; }

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
  mkdir -p "$BACKUP_DIR"  # Only create the backup directory if it does not exist
fi

mv "$WAR_FILE" "$BACKUP_DIR/ROOT.war.$DATE"
echo "Old WAR moved to $BACKUP_DIR/ROOT.war.$DATE"

# === STEP 6: Deploy New WAR ===
cd /home/centos/ || { echo "New WAR not found in /home/centos"; exit 1; }
mv "$WAR_FILE" "$DEPLOY_DIR/"SLACK_MESSAGE=":rocket: *Deployment Completed Successfully!*%0A
# *📦 WAR File:* $WAR_FILE%0A
# *💾 Database:* $db_name%0A
# *🛠️ Tomcat:* $TOMCAT_DIR%0A
# *👨‍💻 Script Owner:* $SCRIPT_OWNER%0A
# *🖥️ Host:* $HOSTNAME%0A
# *🕒 Time:* $TIMESTAMP"
echo "New WAR deployed to $DEPLOY_DIR"

# === STEP 7: Database Setup ===
echo "Example DB name: sbicloud_master_06_01_2025.sql"
read -p "Dump from RDS or MySQL? (Enter rds/mysql): " db_type

if [[ "$db_type" == "rds" ]]; then
  read -p "Enter name for SQL dump file to generate: " db_name
  echo "Using DBAdmin with preset password."
  mysqldump -h bracint-db-master-003-v2.c9llct4yizbm.ap-south-1.rds.amazonaws.com -P 3306 -u DBAdmin -pN6G63HkRQs9h9uCJ sbicloud_master > "$db_name.sql"

elif [[ "$db_type" == "mysql" ]]; then
  echo "Available databases:"
  mysql -u sbicloudapp -p -e "SHOW DATABASES;"

  read -p "Enter new database name to create: " db_name
  echo "Try password: '#@biTSBr@C#@'. If it fails, try: 'M/ooszx2i9n0hMFwPMPEYA='"
  mysql -u sbicloudapp -p -e "CREATE DATABASE $db_name;"
  echo "Database $db_name created."

  read -p "Enter full path to dump file to restore into $db_name: " dump_file

  if [[ "$backup_choice" == "yes" ]]; then
    echo "Using the backup file from the remote system"
    dump_file="$TARGET_PATH/$backup_filename"
  fi

  mysql -u sbicloudapp -p "$db_name" < "$dump_file"
else
  echo "Invalid database type"
  exit 1
fi

# === STEP 8: Backup Config File ===
echo "Backing up the config file before update..."
cp "$CONFIG_FILE" "$CONFIG_FILE.bak.$DATE"
echo "Backup of config file created: $CONFIG_FILE.bak.$DATE"

# === STEP 9: Update Config File ===
echo "Updating JDBC URL in $CONFIG_FILE..."
sed -i "s|url *= *\"jdbc:mariadb://localhost:3306/.*\"|url = \"jdbc:mariadb://localhost:3306/$db_name\"|" "$CONFIG_FILE"

# === STEP 10: SQL Fixes ===
echo "Running SQL cleanup and resets..."
mysql -u sbicloudapp -p "$db_name" <<EOF
USE $db_name;

UPDATE application_user
SET last_login_date=NOW(),
password_expired=FALSE,
password_is_default=TRUE,
account_locked=FALSE,SLACK_MESSAGE=":rocket: *Deployment Completed Successfully!*%0A
# *📦 WAR File:* $WAR_FILE%0A
# *💾 Database:* $db_name%0A
# *🛠️ Tomcat:* $TOMCAT_DIR%0A
# *👨‍💻 Script Owner:* $SCRIPT_OWNER%0A
# *🖥️ Host:* $HOSTNAME%0A
# *🕒 Time:* $TIMESTAMP"
temporary_lock=FALSE,
enabled=TRUE,
failed_login_date=NULL,
failed_login_count=0,
last_password_change_date=NOW(),
PASSWORD='f882b83fc0a5579fb57d34ad6660ad38921a59e7d1611121e5b0a6f1f7faf969'
WHERE application_user_type='INTERNAL';

UPDATE application_user SET email_address='';
UPDATE employee_contact_info SET office_email='';
UPDATE employee_info SET emaiSLACK_MESSAGE=":rocket: *Deployment Completed Successfully!*%0A
# *📦 WAR File:* $WAR_FILE%0A
# *💾 Database:* $db_name%0A
# *🛠️ Tomcat:* $TOMCAT_DIR%0A
# *👨‍💻 Script Owner:* $SCRIPT_OWNER%0A
# *🖥️ Host:* $HOSTNAME%0A
# *🕒 Time:* $TIMESTAMP"l_address='';
DELETE FROM web_route_table;
DELETE FROM email_creator_mapping;
EOF

# === STEP 11: Start Tomcat ===
echo "Starting Tomcat..."
cd "$TOMCAT_DIR"
./bin/startup.sh && tail -f logs/catalina.out &

# === FINAL STEP: Send Slack Notification on Success ===
# SLACK_MESSAGE=":rocket: *Deployment Completed Successfully!*%0A
# *📦 WAR File:* $WAR_FILE%0A
# *💾 Database:* $db_name%0A
# *🛠️ Tomcat:* $TOMCAT_DIR%0A
# *👨‍💻 Script Owner:* $SCRIPT_OWNER%0A
# *🖥️ Host:* $HOSTNAME%0A
# *🕒 Time:* $TIMESTAMP"

echo ">>> Sending Slack notification..."
curl -s -X POST -H 'Content-type: application/json' \
--data "{\"text\": \"$SLACK_MESSAGE\"}" "$SLACK_WEBHOOK"

echo ">>> Slack notification sent."

# === BROWSE APP INSTRUCTION ===
echo "✅ Deployment complete. Please browse: https://master-training.brac.net/"
