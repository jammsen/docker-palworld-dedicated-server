#!/bin/bash

DATE=$(date +%Y%m%d_%H%M%S)
TIME=$(date +%H-%M-%S)

mkdir -p /palworld/backups
if [[ -n $BACKUP_RETENTION_POLICY ]] && [[ $BACKUP_RETENTION_POLICY == "true" ]]; then
    cd /palworld/backups
    echo ">>> The Backup retention policy is enabled"
    echo "> Keeping latest $BACKUP_RETENTION_AMOUNT_TO_KEEP backups"
    ls -1t saved-*.tar.gz | tail -n +$(($BACKUP_RETENTION_AMOUNT_TO_KEEP + 1)) | xargs -d '\n' rm -f --
    echo ">>> Cleanup finished"
fi
echo ">>> Creating backup"
echo "> Sending message to gameserver"
cd ~/steamcmd/
rconcli "broadcast $TIME-Backup-in-progress"
sleep 1
rconcli 'broadcast Saving...'
rconcli 'save'
rconcli 'broadcast Done...'
sleep 15
# Create backup dir and change into it
cd /palworld/Pal
tar cfz /palworld/backups/saved-$DATE.tar.gz Saved/
echo ">>> Done"
