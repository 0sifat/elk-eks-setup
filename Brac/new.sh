#!/bin/bash

# Define variables
SSH_KEY_PATH="/home/centos/.ssh/id_rsa"
SERVER_1="13.126.173.220"
SERVER_2="52.66.13.94"
SERVER_3="15.206.49.232"
PORT="222"
REMOTE_DIR="/production-data/backup/dbbackup/master/db/"
LOCAL_DIR="/home/centos/"

# Step 1: SSH into the first server
echo "Accessing the first server..."
ssh -i $SSH_KEY_PATH -p $PORT centos@$SERVER_1 << EOF
  # Step 2: Navigate to the directory and list files
  sudo cd $REMOTE_DIR
  echo "Listing files..."
  ls -lh

  # Step 3: Get the most recent .gz file
  # Assuming the most recent .gz file is the last one when sorted by time
  recent_file=\$(ls -t *.gz | head -n 1)
  echo "Most recent file: \$recent_file"
EOF

# Step 4: SCP the recent file to second server with sudo (if required)
echo "Transferring file to second server..."
scp -i $SSH_KEY_PATH -P $PORT "$recent_file" centos@$SERVER_2:$LOCAL_DIR

# Step 5: SSH into the second server
echo "Accessing the second server..."
ssh -i $SSH_KEY_PATH -p $PORT centos@$SERVER_3 << EOF
  # Step 6: SCP file from the second server to the target server with sudo (if required)
  echo "Transferring ROOT.war file to target server..."
  sudo scp -i $SSH_KEY_PATH -P $PORT /bits/sbicloud/MS-tomcat9090/webapps/ROOT.war centos@$SERVER_2:$LOCAL_DIR
EOF

echo "Script completed."
