# shellcheck disable=SC2148

function get_time() {
    date '+[%H:%M:%S]'
}

function save_and_shutdown_server() {
    rconcli broadcast "$(get_time) Server shutdown requested. Saving..."
    rconcli save
    rconcli broadcast "$(get_time) Saving done. Server shutting down..."
}

function broadcast_automatic_restart() {
    for ((counter=1; counter<=15; counter++)); do
        rconcli "broadcast ${time}-AUTOMATIC-RESTART-IN-$counter-MINUTES"
        sleep 1
    done
    rconcli broadcast "$(get_time) Saving world before restart..."
    rconcli save
    rconcli broadcast "$(get_time) Saving done"
    rconcli broadcast "$(get_time) Creating backup..."
    rcon "Shutdown 10"
}

function broadcast_backup_start() {
    rconcli broadcast "$(get_time) Saving in 5 seconds..."
    sleep 5
    rconcli broadcast "$(get_time) Saving world..."
    rconcli save
    rconcli broadcast "$(get_time) Saving done"
    rconcli broadcast "$(get_time) Creating backup..."
}

function broadcast_backup_success() {
    rconcli broadcast "$(get_time) Backup done"
}

function broadcast_backup_failed() {
    rconcli broadcast "$(get_time) Backup failed"
}

function broadcast_player_join() {
    rconcli broadcast "$(get_time) $1 joined the server"
}

function broadcast_player_name_change() {
    rconcli broadcast "$(get_time) $1 renamed to $2"
}

function broadcast_player_leave() {
    rconcli broadcast "$(get_time) $1 left the server"
}

function check_is_server_empty() {
    num_players=$(rcon -c "$RCON_CONFIG_FILE" showplayers | tail -n +2 | wc -l)
    if [ "$num_players" -eq 0 ]; then
        return 0  # Server empty
    else
        return 1  # Server not empty
    fi
}
