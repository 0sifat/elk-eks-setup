#!/bin/bash

# Set the necessary variables
KEY_PATH="/home/centos/.ssh/id_rsa"
SRC_SERVER="13.126.173.220"
TOMCAT_SERVER="15.206.49.232"
DST_SERVER="52.66.13.94"
TOMCAT_SHUTDOWN_PATH="/bits/sbicloud/HRT-tomcat9010/bin/shutdown.sh"
TOMCAT_STARTUP_PATH="/bits/sbicloud/HRT-tomcat9010/bin/startup.sh"
DB_BACKUP_PATH="/production-data/backup/dbbackup/master/db/"
WAR_FILE_PATH="/home/centos/ROOT.war"
TOMCAT_WEBAPPS_PATH="/bits/sbicloud/HRT-tomcat9010/webapps/"
MYSQL_USER="sbicloudapp"

# Function to access source server and SCP the file
scp_file_from_server() {
    echo "Accessing source server ${SRC_SERVER}..."
    ssh -i $KEY_PATH -p 222 centos@$SRC_SERVER <<EOF
        cd $DB_BACKUP_PATH
        ls -lh
        # User chooses which file to SCP
        read -p "Enter the filename you want to SCP: " filename
        scp -i $KEY_PATH -P 222 "\$filename" centos@$DST_SERVER:/home/centos/
        exit
EOF
}

# Function to SCP the war file from tomcat server
scp_war_file() {
    echo "Accessing tomcat server ${TOMCAT_SERVER}..."
    ssh -i $KEY_PATH -p 222 centos@$TOMCAT_SERVER <<EOF
        scp -i $KEY_PATH -P 222 /bits/sbicloud/MS-tomcat9090/webapps/ROOT.war centos@$DST_SERVER:/home/centos/
        exit
EOF
}

# Function to stop the tomcat
stop_tomcat() {
    echo "Stopping Tomcat..."
    ssh -i $KEY_PATH -p 222 centos@$DST_SERVER <<EOF
        cd $TOMCAT_SERVER
        ./bin/shutdown.sh
        exit
EOF
}

# Function to backup the current war file
backup_war() {
    echo "Backing up the current war file..."
    ssh -i $KEY_PATH -p 222 centos@$DST_SERVER <<EOF
        cd $TOMCAT_WEBAPPS_PATH
        mv ROOT.war ./war-backup/ROOT.war.\$(date +\%F)
        exit
EOF
}

# Function to move the new war file
move_new_war() {
    echo "Moving new WAR file..."
    ssh -i $KEY_PATH -p 222 centos@$DST_SERVER <<EOF
        mv /home/centos/ROOT.war $TOMCAT_WEBAPPS_PATH/
        exit
EOF
}

# Function to decompress the .gz file
decompress_file() {
    echo "Decompressing the file..."
    ssh -i $KEY_PATH -p 222 centos@$DST_SERVER <<EOF
        cd /home/centos/
        gunzip \$1
        exit
EOF
}

# Function to create a new MySQL database
create_mysql_db() {
    echo "Creating new MySQL database..."
    ssh -i $KEY_PATH -p 222 centos@$DST_SERVER <<EOF
        mysql -u $MYSQL_USER -p
        CREATE DATABASE \$1;
        exit
EOF
}this is the server where the war file is and .gz file need to scp 52.66.13.94

then 


1st need to access this server 13.126.173.220 user centos key patha /home/centos/.ssh/id_rsa
ssh -i /home/centos/.ssh/id_rsa -p 222 centos@13.126.173.220

then run

cd /production-data/backup/dbbackup/master/db/

then run
ls -lh

system will take the most recent file .gz file
then run
scp -i /home/centos/.ssh/id_rsa -P 222 "filename that i want to scp" centos@52.66.13.94:/home/centos/


then run 
ssh -i /home/centos/.ssh/id_rsa -p 222 centos@15.206.49.232


scp -i /home/centos/.ssh/id_rsa -P 222 /bits/sbicloud/MS-tomcat9090/webapps/ROOT.war centos@52.66.13.94:/home/centos/

then 


into this server 52.66.13.94

Step1: Stop the tomcat
cd /bits/sbicloud/HRT-tomcat9010/​
then run
./bin/shutdown.sh

Step 2: Move the current war file to backup
cd webapps/​
mv ROOT.war ./war-backup with a new name like ROOT.war.current_date

Step 3: Move the new war file
cd /home/centos/​
mv ROOT.war /bits/sbicloud/HRT-tomcat9010/webapps/

the run
cd /home/centos/​
gunzip the file that get from the server 13.126.173.220


then run mysql -u sbicloudapp -p​

after login need to create a new database

then exit

then Run

cd /home/centos/​ of 52.66.13.94
mysql -u sbicloudapp -p newlly created db < that file i unzip 

then r
url= "jdbc:mariadb://localhost:3306/newly created db"

then run 

mysql -u sbicloudapp -p

use newly created db;

then run

UPDATE application_user​
SET last_login_date=NOW(),​
password_expired= FALSE,​
password_is_default= TRUE,​
account_locked= FALSE,​
temporary_lock=FALSE,​
enabled = TRUE,​
failed_login_date = NULL,​
failed_login_count=0,​
last_password_change_date=NOW(),​
PASSWORD =
'f882b83fc0a5579fb57d34ad6660ad38921a59e7d1611121e5b0a6f1f7faf969'​
WHERE application_user_type = 'INTERNAL';​
​
UPDATE application_user e SET e.email_address = '';​
​
UPDATE employee_contact_info e SET e.office_email = '' ;​
​
UPDATE employee_info e SET e.email_address = '';​
​
DELETE FROM web_route_table;​
​
DELETE FROM email_creator_mapping;
 the exit

Step 9: Start the tomcat
cd /bits/sbicloud/HRT-tomcat9010/​
./bin/startup.sh && tail -f logs/catalina.out



















#!/bin/bash

# Set the necessary variables
KEY_PATH="/home/centos/.ssh/id_rsa"
SRC_SERVER="13.126.173.220"
TOMCAT_SERVER="15.206.49.232"
DST_SERVER="52.66.13.94"
TOMCAT_SHUTDOWN_PATH="/bits/sbicloud/HRT-tomcat9010/bin/shutdown.sh"
TOMCAT_STARTUP_PATH="/bits/sbicloud/HRT-tomcat9010/bin/startup.sh"
DB_BACKUP_PATH="/production-data/backup/dbbackup/master/db/"
WAR_FILE_PATH="/home/centos/ROOT.war"
TOMCAT_WEBAPPS_PATH="/bits/sbicloud/HRT-tomcat9010/webapps/"
MYSQL_USER="sbicloudapp"

# Function to access source server and SCP the file
scp_file_from_server() {
    echo "Accessing source server ${SRC_SERVER}..."
    ssh -i $KEY_PATH -p 222 centos@$SRC_SERVER <<EOF
        cd $DB_BACKUP_PATH
        ls -lh
        # User chooses which file to SCP
        read -p "Enter the filename you want to SCP: " filename
        scp -i $KEY_PATH -P 222 "\$filename" centos@$DST_SERVER:/home/centos/
        exit
EOF
}

# Function to SCP the war file from tomcat server

scp_war_file() {
    echo "Accessing tomcat server ${TOMCAT_SERVER}..."
    ssh -i $KEY_PATH -p 222 centos@$TOMCAT_SERVER <<EOF
        scp -i $KEY_PATH -P 222 /bits/sbicloud/MS-tomcat9090/webapps/ROOT.war centos@$DST_SERVER:/home/centos/
        exit
EOF
}

# Function to stop the tomcat
stop_tomcat() {
    echo "Stopping Tomcat..."
    ssh -i $KEY_PATH -p 222 centos@$DST_SERVER <<EOF
        cd $TOMCAT_SERVER
        ./bin/shutdown.sh
        exit
EOF
}

# Function to backup the current war file
backup_war() {
    echo "Backing up the current war file..."
    ssh -i $KEY_PATH -p 222 centos@$DST_SERVER <<EOF
        cd $TOMCAT_WEBAPPS_PATH
        mv ROOT.war ./war-backup/ROOT.war.\$(date +\%F)
        exit
EOF
}

# Function to move the new war file
move_new_war() {
    echo "Moving new WAR file..."
    ssh -i $KEY_PATH -p 222 centos@$DST_SERVER <<EOF
        mv /home/centos/ROOT.war $TOMCAT_WEBAPPS_PATH/
        exit
EOF
}

# Function to decompress the .gz file
decompress_file() {
    echo "Decompressing the file..."
    ssh -i $KEY_PATH -p 222 centos@$DST_SERVER <<EOF
        cd /home/centos/
        gunzip \$1
        exit
EOF
}

# Function to create a new MySQL database
create_mysql_db() {
    echo "Creating new MySQL database..."
    ssh -i $KEY_PATH -p 222 centos@$DST_SERVER <<EOF
        mysql -u $MYSQL_USER -p
        CREATE DATABASE \$1;
        exit
EOF
}

# Function to import the SQL dump file
import_sql_dump() {
    echo "Importing SQL dump..."
    ssh -i $KEY_PATH -p 222 centos@$DST_SERVER <<EOF
        mysql -u $MYSQL_USER -p \$1 < \$2
        exit
EOF
}

# Function to update the application user table
update_application_user() {
    echo "Updating application user..."
    ssh -i $KEY_PATH -p 222 centos@$DST_SERVER <<EOF
        mysql -u $MYSQL_USER -p
        USE \$1;
        UPDATE application_user SET last_login_date=NOW(), password_expired=FALSE, password_is_default=TRUE, account_locked=FALSE, temporary_lock=FALSE, enabled=TRUE, failed_login_date=NULL, failed_login_count=0, last_password_change_date=NOW(), PASSWORD='f882b83fc0a5579fb57d34ad6660ad38921a59e7d1611121e5b0a6f1f7faf969' WHERE application_user_type='INTERNAL';
        UPDATE application_user e SET e.email_address='';
        UPDATE employee_contact_info e SET e.office_email='';
        UPDATE employee_info e SET e.email_address='';
        DELETE FROM web_route_table;
        DELETE FROM email_creator_mapping;
        exit
EOF
}

# Function to start the tomcat
start_tomcat() {
    echo "Starting Tomcat..."
    ssh -i $KEY_PATH -p 222 centos@$DST_SERVER <<EOF
        cd $TOMCAT_STARTUP_PATH
        ./bin/startup.sh
        tail -f logs/catalina.out
        exit
EOF
}

# Main script execution
scp_file_from_server
scp_war_file
stop_tomcat
backup_war
move_new_war
decompress_file "backup_file.sql.gz" # Replace with the actual filename you want to decompress
create_mysql_db "new_database_name" # Replace with the new DB name
import_sql_dump "new_database_name" "backup_file.sql" # Replace with actual DB name and file
update_application_user "new_database_name" # Replace with DB name
start_tomcat

echo "Script completed."
