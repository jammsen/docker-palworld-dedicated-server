#!/bin/bash

DATE=$(date +%Y%m%d_%H%M%S)
TIME=$(date +%H-%M-%S)

echo ">>> Creating backup"
echo "> Sending message to gameserver"
cd ~/steamcmd/
rconcli "broadcast $TIME-Backup_in_progress"
sleep 1
rconcli 'broadcast Saving...'
rconcli 'save'
rconcli 'broadcast Done...'
sleep 15
# Create backup dir and change into it
mkdir -p /palworld/backups && cd /palworld/Pal
tar cfz /palworld/backups/saved-$DATE.tar.gz Saved/
echo ">>> Done"
