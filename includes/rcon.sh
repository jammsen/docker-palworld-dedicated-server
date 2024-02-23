# shellcheck disable=SC2148

function save_and_shutdown_server() {
    rconcli 'broadcast Server-shutdown-was-requested-init-saving'
    rconcli 'save'
    rconcli 'broadcast Done-saving-server-shuts-down-now'
}

function broadcast_automatic_restart() {
    time=$(date '+%H:%M:%S')

    for ((counter=1; counter<=15; counter++)); do
        rconcli "broadcast ${time}-AUTOMATIC-RESTART-IN-$counter-MINUTES"
        sleep 1
    done
    rconcli 'broadcast Saving-world-before-restart...'
    rconcli 'save'
    rconcli 'broadcast Saving-done'
    rconcli 'broadcast Creating-backup'
    rcon "Shutdown 10"
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

function broadcast_player_join() {
    time=$(date '+%H:%M:%S')
    rconcli "broadcast ${time}-$1-joined-the-server"
}

function broadcast_player_name_change() {
    time=$(date '+%H:%M:%S')
    rconcli "broadcast ${time}-$1-renamed-to-$2"
}

function broadcast_player_leave() {
    time=$(date '+%H:%M:%S')
    rconcli "broadcast ${time}-$1-left-the-server"
}