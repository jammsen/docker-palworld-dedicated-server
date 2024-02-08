# shellcheck disable=SC2148
#Save and shutdown the server
function save_and_shutdown_server() {
    rconcli 'broadcast Server-shutdown-was-requested-init-saving'
    rconcli 'save'
    rconcli 'broadcast Done-saving-server-shuts-down-now'
}

function broadcast_backup_start() {
    time=$(date '+%H:%M:%S')

    rconcli "broadcast ${time}-Saving-in-5-seconds"
    sleep 5
    rconcli 'broadcast Saving-world...'
    rconcli 'save'
    rconcli 'broadcast Saving-done'
    rconcli 'broadcast Creating-backup'
}

function broadcast_backup_success() {
    rconcli 'broadcast Backup-done'
}

function broadcast_backup_failed() {
    rconcli 'broadcast Backup-failed'
}