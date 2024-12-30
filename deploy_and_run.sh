#!/bin/bash

# Server details
SERVER="172.16.4.56"
USER="root"
REMOTE_DIR="~"
SCRIPT="test_kudu_timeout.sh"

# Install sshpass if not exists
if ! command -v sshpass &> /dev/null
then
    echo "sshpass not found. Installing..."
    sudo apt-get install -y sshpass
fi

# Copy script to server
sshpass -p 'root' scp $SCRIPT $USER@$SERVER:$REMOTE_DIR

# Execute script on server
sshpass -p 'root' ssh $USER@$SERVER "chmod +x $REMOTE_DIR/$SCRIPT && $REMOTE_DIR/$SCRIPT"

# Copy results back
sshpass -p 'root' scp $USER@$SERVER:$REMOTE_DIR/kudu_timeout_results.csv .

echo "Test completed. Results saved to kudu_timeout_results.csv"
