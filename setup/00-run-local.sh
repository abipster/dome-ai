#!/bin/bash

PUBKEYPATH="$HOME/.ssh/id_rsa.pub"
REMOTE_USER="dome"
# Set REMOTE_HOST to the server IP address. Override by setting the REMOTE_HOST environment variable.
REMOTE_HOST="${REMOTE_HOST:-192.168.10.26}"

echo "copying user setup scripts to remote server"
# rsync -azPv setup/01-create-user.sh root@$REMOTE_HOST:/root

# rsync -azPv setup/dome.passwd root@$REMOTE_HOST:/root

# echo "run 01-create-user.sh on remote server"

echo "copying public key to remote server"
ssh-copy-id -i "$PUBKEYPATH" "$REMOTE_USER@$REMOTE_HOST"


# echo "copying environment setup scripts to remote server"
# rsync -azPv setup/02-setup-environment.sh $REMOTE_USER@$REMOTE_HOST:/opt/dome

# rsync -azPv docker/.env $REMOTE_USER@$REMOTE_HOST:/opt/dome

# rsync -azPv docker/docker-compose.yml $REMOTE_USER@$REMOTE_HOST:/opt/dome

# echo "run 02-setup-environment.sh on remote server"