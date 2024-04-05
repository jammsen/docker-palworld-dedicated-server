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
    readarray -t current_players < <(rcon showplayers 2> /dev/null | tail -n +2)

    for player_info in "${current_players[@]}"; do
        # Extract player name, UID, and Steam ID from player info
        # This part sets the Internal Field Separator (IFS) variable to ','.
        # In Bash, the IFS variable determines how Bash recognizes word boundaries.
        # By default, it includes space, tab, and newline characters.
        # By setting it to ',', we're telling Bash to split input lines at commas.
        # https://tldp.org/LDP/abs/html/internalvariables.html#IFSREF
        IFS=',' read -r -a player_data <<< "$player_info"
        local steamid="${player_data[-1]}"
        local playeruid="${player_data[-2]}"
        local name="${player_data[*]::${#player_data[@]}-2}"

        # Strip special characters from the player name
        name="$(echo "$name" | tr -cd '[:alnum:]')"

        local found=false
        for old_player_info in "${old_players[@]}"; do
            IFS=',' read -r -a old_player_data <<< "$old_player_info"
            local old_steamid="${old_player_data[-1]}"
            local old_playeruid="${old_player_data[-2]}"
            local old_name="${old_player_data[*]::${#old_player_data[@]}-2}"

            # Strip special characters from the old player name
            old_name="$(echo "$old_name" | tr -cd '[:alnum:]')"

            if [[ "$old_steamid" == "$steamid" ]]; then
                found=true
                if [[ "$old_playeruid" == "00000000" && "$playeruid" != "00000000" ]]; then
                    announce_name_change "$old_name" "$name"
                fi
                break
            fi
        done
        if ! $found; then
            announce_join "$name"
        fi
    done

    for old_player_info in "${old_players[@]}"; do
        IFS=',' read -r -a old_player_data <<< "$old_player_info"
        local old_steamid="${old_player_data[-1]}"
        local old_playeruid="${old_player_data[-2]}"
        local old_name="${old_player_data[*]::${#old_player_data[@]}-2}"

        # Strip special characters from the old player name
        old_name="$(echo "$old_name" | tr -cd '[:alnum:]')"

        local found=false
        for player_info in "${current_players[@]}"; do
            IFS=',' read -r -a player_data <<< "$player_info"
            local steamid="${player_data[-1]}"
            if [[ "$old_steamid" == "$steamid" ]]; then
                found=true
                break
            fi
        done
        if ! $found; then
            announce_leave "$old_name"
        fi
    done
}


# Function to announce a player join
announce_join() {
    time=$(date '+[%H:%M:%S]')
    message="Player $1 has joined the server."
    echo "${time}: $message"
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_info_notification "$message"
    fi
    if [[ -n $RCON_ENABLED ]] && [[ $RCON_ENABLED == "true" ]]; then
        broadcast_player_join "${1}"
    fi
}

# Function to announce a player join
announce_name_change() {
    time=$(date '+[%H:%M:%S]')
    message="Player $1 has changed their name to $2."
    echo "${time}: $message"
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_info_notification "$message"
    fi
    if [[ -n $RCON_ENABLED ]] && [[ $RCON_ENABLED == "true" ]]; then
        broadcast_player_name_change "${1}" "${2}"
    fi
}

# Function to announce a player leave
announce_leave() {
    time=$(date '+[%H:%M:%S]')
    message="Player $1 has left the server."
    echo "${time}: $message"
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_info_notification "$message"
    fi
    if [[ -n $RCON_ENABLED ]] && [[ $RCON_ENABLED == "true" ]]; then
        broadcast_player_leave "${1}"
    fi
}
