# shellcheck disable=SC2148,SC1091

source /includes/colors.sh
source /includes/rcon.sh
source /includes/webhook.sh

player_detection_loop() {
    sleep "$RCON_PLAYER_DETECTION_STARTUP_DELAY"
    while true; do
        compare_players
        sleep "$RCON_PLAYER_DETECTION_CHECK_INTERVAL"
    done 
}

 # Function to compare current and previous player lists
compare_players() {
    local old_players=("${current_players[@]}")
    readarray -t current_players < <(rcon showplayers | tail -n +2 | awk -F ',' '{print $1}')

    for player in "${current_players[@]}"; do
        local found=false
        for old_player in "${old_players[@]}"; do
            if [ "$old_player" = "$player" ]; then
                found=true
                break
            fi
        done
        if ! $found; then
            announce_join "$player"
        fi
    done
    for player in "${old_players[@]}"; do
        local found=false
        for current_player in "${current_players[@]}"; do
            if [ "$current_player" = "$player" ]; then
                found=true
                break
            fi
        done
        if ! $found; then
            announce_leave "$player"
        fi
    done
}

# Function to announce a player join
announce_join() {
    time=$(date '+%H:%M:%S')
    message="Player $1 has joined the server."
    echo "${time}: $message"
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_player_join_notification "$message"
    fi
    if [[ -n $RCON_ENABLED ]] && [[ $RCON_ENABLED == "true" ]]; then
       broadcast_player_join "$1"
    fi
}

# Function to announce a player leave
announce_leave() {
    time=$(date '+%H:%M:%S')
    message="Player $1 has left the server."
    echo "${time}: $message"
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_player_leave_notification "$message"
    fi
    if [[ -n $RCON_ENABLED ]] && [[ $RCON_ENABLED == "true" ]]; then
       broadcast_player_leave "$1"
    fi
}