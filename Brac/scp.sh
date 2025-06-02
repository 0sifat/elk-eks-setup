#!/bin/bash

# Variables
KEY_PATH="/home/centos/.ssh/id_rsa"
SRC_SERVER="13.126.173.220"
DST_SERVER="52.66.13.94"
TOMCAT_SERVER="15.206.49.232"
WAR_FILE_PATH="/production-data/backup/dbbackup/master/db/"
DB_BACKUP_PATH="/home/centos/"

# Step 1: SSH into source server 13.126.173.220 and list files
echo "Accessing source server ${SRC_SERVER}..."
ssh -i $KEY_PATH -p 222 centos@$SRC_SERVER <<EOF
    cd $WAR_FILE_PATH
    ls -lh
EOF

# Step 2: SCP the chosen file to destination server 52.66.13.94
echo "Please enter the filename to SCP:"
read FILENAME
scp -i $KEY_PATH -P 222 "$WAR_FILE_PATH/$FILENAME" centos@$DST_SERVER:/home/centos/

# Step 3: SSH into another server (Tomcat server 15.206.49.232)
echo "Accessing Tomcat server ${TOMCAT_SERVER}..."
ssh -i $KEY_PATH -p 222 centos@$TOMCAT_SERVER <<EOF
    scp -i $KEY_PATH -P 222 /bits/sbicloud/MS-tomcat9090/webapps/ROOT.war centos@$DST_SERVER:/home/centos/
EOF



scp -i /home/centos/.ssh/id_rsa -P 222 /bits/sbicloud/MS-tomcat9090/webapps/ROOT.war centos@52.66.13.94:/home/centos/



#!/bin/bash

# Variables
KEY_PATH="/home/centos/.ssh/id_rsa"
SRC_SERVER="13.126.173.220"
DST_SERVER="52.66.13.94"
TOMCAT_SERVER="15.206.49.232"
WAR_FILE_PATH="/production-data/backup/dbbackup/master/db/"
DB_BACKUP_PATH="/home/centos/"

scp -i $KEY_PATH -P 222 "$WAR_FILE_PATH/$FILENAME" centos@$DST_SERVER:/home/centos/


#!/bin/bash

# Variables
KEY_PATH="/home/centos/.ssh/id_rsa"
DST_SERVER="52.66.13.94"
TOMCAT_SERVER="15.206.49.232"
WAR_FILE_PATH="/bits/sbicloud/MS-tomcat9090/webapps/ROOT.war"
DB_BACKUP_PATH="/home/centos/"

scp -i $KEY_PATH -P 222 "$WAR_FILE_PATH/$FILENAME" centos@$DST_SERVER:/home/centos