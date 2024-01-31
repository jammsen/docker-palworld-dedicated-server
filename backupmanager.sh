#!/bin/bash

DATE=$(date +%Y%m%d_%H%M%S)
TIME=$(date +%H-%M-%S)

mkdir -p /palworld/backups
if [[ -n $BACKUP_RETENTION_POLICY ]] && [[ $BACKUP_RETENTION_POLICY == "true" ]]; then
    cd /palworld/backups
    echo ">>> The Backup retention policy is enabled - Keeping latest $BACKUP_RETENTION_AMOUNT_TO_KEEP backups"
    ls -1t saved-*.tar.gz | tail -n +$(($BACKUP_RETENTION_AMOUNT_TO_KEEP + 1)) | xargs -d '\n' rm -f --
fi
cd ~/steamcmd/
rconcli "broadcast $TIME-Saving-in-5-seconds"
sleep 5
rconcli 'save'
rconcli 'broadcast Saving-done'
sleep 1
rconcli 'broadcast Creating-backup'
cd /palworld/Pal
tar cfz /palworld/backups/saved-$DATE.tar.gz Saved/
cd ~/steamcmd/
rconcli 'broadcast Backup-done'
