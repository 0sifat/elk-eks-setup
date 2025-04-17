#!/bin/bash

# === VARIABLES ===
WAR_FILE="ROOT.war"
BACKUP_DIR="war-backup"
TARGET_IP="52.66.13.94"
TARGET_USER="centos"
TARGET_PATH="/home/centos/"
SSH_KEY="/home/centos/.ssh/id_rsa"
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

# === STEP 1: Transfer WAR ===
cd /bits/sbicloud/MS-tomcat9090/webapps/ || { echo "Source directory not found"; exit 1; }
echo "Transferring $WAR_FILE to $TARGET_IP..."
scp -i "$SSH_KEY" -P $PORT "$WAR_FILE" "$TARGET_USER@$TARGET_IP:$TARGET_PATH"

if [[ $? -eq 0 ]]; then
  echo "WAR file transferred to $TARGET_IP"
  ssh -i "$SSH_KEY" -p $PORT "$TARGET_USER@$TARGET_IP" "echo 'Access successful.'" >/dev/null 2>&1
  [[ $? -eq 0 ]] && echo "SSH access confirmed" || echo "Unable to SSH into $TARGET_IP"
else
  echo "WAR transfer failed"
  exit 1
fi

# === STEP 2: Shutdown Tomcat ===
cd "$TOMCAT_DIR" || { echo "Tomcat directory not found"; exit 1; }
echo "Shutting down Tomcat..."
./bin/shutdown.sh

# === STEP 3: Backup Old WAR ===
cd "$DEPLOY_DIR" || { echo "Webapps directory not found"; exit 1; }
mkdir -p "$BACKUP_DIR"
mv "$WAR_FILE" "$BACKUP_DIR/ROOT.war.$DATE"
echo "Old WAR moved to $BACKUP_DIR/ROOT.war.$DATE"

# === STEP 4: Deploy New WAR ===
cd /home/centos/ || { echo "New WAR not found in /home/centos"; exit 1; }
mv "$WAR_FILE" "$DEPLOY_DIR/"
echo "New WAR deployed to $DEPLOY_DIR"

# === STEP 5: Database Setup ===
echo "Example DB name: sbicloud_master_06_01_2025.sql"
read -p "Dump from RDS or MySQL? (Enter rds/mysql): " db_type

if [[ "$db_type" == "rds" ]]; then
  read -p "Enter name for SQL dump file to generate: " db_name
  echo "Using DBAdmin. Password will be prompted."
  mysqldump -h bracint-db-master-003-v2.c9llct4yizbm.ap-south-1.rds.amazonaws.com -P 3306 -u DBAdmin -p sbicloud_master > "$db_name.sql"

elif [[ "$db_type" == "mysql" ]]; then
  read -p "Enter new database name to create: " db_name
  echo "Try password: '#@biTSBr@C#@'. If it fails, try: 'M/ooszx2i9n0hMFwPMPEYA='"
  mysql -u sbicloudapp -p -e "CREATE DATABASE $db_name;"
  echo "Database $db_name created."

  read -p "Enter full path to dump file to restore into $db_name: " dump_file
  mysql -u sbicloudapp -p "$db_name" < "$dump_file"
else
  echo "Invalid database type"
  exit 1
fi

# === STEP 6: Update Config File ===
echo "Updating JDBC URL in $CONFIG_FILE..."
sed -i "s|url *= *\"jdbc:mariadb://localhost:3306/.*\"|url = \"jdbc:mariadb://localhost:3306/$db_name\"|" "$CONFIG_FILE"

# === STEP 7: SQL Fixes ===
echo "Running SQL cleanup and resets..."
mysql -u sbicloudapp -p "$db_name" <<EOF
USE $db_name;

UPDATE application_user
SET last_login_date=NOW(),
password_expired=FALSE,
password_is_default=TRUE,
account_locked=FALSE,
temporary_lock=FALSE,
enabled=TRUE,
failed_login_date=NULL,
failed_login_count=0,
last_password_change_date=NOW(),
PASSWORD='f882b83fc0a5579fb57d34ad6660ad38921a59e7d1611121e5b0a6f1f7faf969'
WHERE application_user_type='INTERNAL';

UPDATE application_user SET email_address='';
UPDATE employee_contact_info SET office_email='';
UPDATE employee_info SET email_address='';
DELETE FROM web_route_table;
DELETE FROM email_creator_mapping;
EOF

# === STEP 8: Start Tomcat ===
echo "Starting Tomcat..."
cd "$TOMCAT_DIR"
./bin/startup.sh && tail -f logs/catalina.out
