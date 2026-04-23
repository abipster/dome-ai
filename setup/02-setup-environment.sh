#!/bin/bash
set -o allexport
[ -f /opt/dome/docker/.env ] || { echo "Error: .env file not found"; exit 1; }
source /opt/dome/docker/.env
set +o allexport


echo $DOCKERDIR
echo $DOCKERLOGS
echo $DOCKERRUNTIME

# mount shared directories
# TODO

# Create required directories
# app directories

# mkdir -p $DOCKERDIR # already exists
# mkdir -p $DOCKER_RUNTIME/postgres
mkdir -p $DOCKERRUNTIME/ollama

# log directories
mkdir -p $DOCKERLOGS


## Set owners and permissions
sudo chown -R dome:dome $DOCKERDIR
sudo chown -R dome:dome $DOCKERLOGS
sudo chown -R dome:dome $DOCKERRUNTIME

echo "== Setup SSH =="
echo "run the following instructions manually:"
echo "1. Generate SSH key pair:"
echo "ssh-keygen -t ed25519 -C \"your_email@example.com\""
echo "If your system doesn’t support Ed25519, use:"
echo "ssh-keygen -t rsa -b 4096 -C \"your_email@example.com\""
echo "Add your new key to the SSH agent:"
echo "eval \"\$(ssh-agent -s)\""
echo "ssh-add ~/.ssh/id_ed25519"
echo "Copy your public key to your clipboard:"
echo "cat ~/.ssh/id_ed25519.pub"
echo "Go to GitHub SSH settings, click New SSH key, paste your key, and save."
echo "Clone the repository using SSH to verify everything is set up correctly:"
echo "git clone https://github.com/user/repo.git /opt/dome"