# shellcheck disable=SC2148,SC1091
#
# Player name sanitization — sed 's/[\x00-\x1F\x7F"\\]//g'
# Strips the following characters from player names before use in broadcast messages
# and webhook payloads, while preserving all Unicode (Chinese, Japanese, etc.):
#   \x00        — null byte (would silently truncate strings in many tools)
#   \x01-\x1F   — ASCII control characters (tab, newline, carriage return, ESC, etc.)
#   \x7F        — DEL character
#   "           — double-quote (would break JSON string encoding)
#   \           — backslash (would break JSON escape sequences)
# Detection logic (userId/playerId comparison) is NOT affected — raw JSON from the API is used there.

source /includes/colors.sh
source /includes/restapi.sh
source /includes/webhook.sh

current_players=()

player_detection_loop() {
    sleep "$PLAYER_DETECTION_STARTUP_DELAY"
    while true; do
        compare_players
        sleep "$PLAYER_DETECTION_CHECK_INTERVAL"
    done
}

restapi_showplayers_with_retry() {
    local amount_of_retries=5
    local wait_in_seconds=3
    local command_output get_result

    for ((i=0; i<amount_of_retries; i++)); do
        command_output=$(restapi_get "players" 2>/dev/null)
        get_result=$?
        if [[ -n $PLAYER_DETECTION_DEBUG ]] && [[ "${PLAYER_DETECTION_DEBUG,,}" == "true" ]]; then
            ew "Debug: command_output = '$command_output'"
            ew "Debug: exit code was: $get_result"
        fi
        if [[ $get_result -eq 0 ]]; then
            # Store each player as a compact JSON object — no delimiter parsing needed.
            # playerId is "None" while a player is in the character creator (before saving a character).
            # userId has a "steam_" prefix; we strip it later when comparing.
            local parsed
            parsed=$(echo "$command_output" | jq -c '.players[]?' 2>/dev/null)
            if [[ -n "$parsed" ]]; then
                readarray -t current_players <<< "$parsed"
            else
                # Valid response but no players online
                current_players=()
            fi
            if [[ -n $PLAYER_DETECTION_DEBUG ]] && [[ "${PLAYER_DETECTION_DEBUG,,}" == "true" ]]; then
                ew "Debug: current_players = ${current_players[*]}"
            fi
            return 0
        fi
        sleep $wait_in_seconds
    done

    ew ">>> REST API player fetch failed after $amount_of_retries attempts."
    return 1
}

# Function to compare current and previous player lists
compare_players() {
    local old_players=("${current_players[@]}")

    if ! restapi_showplayers_with_retry; then
        ew "> Skipping player comparison due to REST API failure."
        return
    fi

    if [[ -n $PLAYER_DETECTION_DEBUG ]] && [[ "${PLAYER_DETECTION_DEBUG,,}" == "true" ]]; then
        ew "Debug: current_players = ${current_players[*]}"
    fi

    for player_info in "${current_players[@]}"; do
        if [[ -z "$player_info" ]]; then continue; fi
        if [[ -n $PLAYER_DETECTION_DEBUG ]] && [[ "${PLAYER_DETECTION_DEBUG,,}" == "true" ]]; then
            ew "For-Loop-Debug: player_info = '$player_info'"
        fi

        # Each entry is a compact JSON object — extract fields with jq.
        # No delimiter parsing; player names with any characters (commas, quotes,
        # Chinese/Japanese/etc.) are handled correctly by jq.
        local userid playerid name
        userid=$(echo "$player_info" | jq -r '.userId | ltrimstr("steam_")')
        playerid=$(echo "$player_info" | jq -r '.playerId // "None"')
        name=$(echo "$player_info" | jq -r '.name' | sed 's/[\x00-\x1F\x7F"\\]//g')

        local found=false
        for old_player_info in "${old_players[@]}"; do
            if [[ -z "$old_player_info" ]]; then continue; fi
            local old_userid old_playerid old_name
            old_userid=$(echo "$old_player_info" | jq -r '.userId | ltrimstr("steam_")')
            old_playerid=$(echo "$old_player_info" | jq -r '.playerId // "None"')
            old_name=$(echo "$old_player_info" | jq -r '.name' | sed 's/[\x00-\x1F\x7F"\\]//g')

            if [[ "$old_userid" == "$userid" ]]; then
                found=true
                # playerId transitions from "None" to a real UID once the player
                # finishes character creation — treat that as a name-change event
                if [[ "$old_playerid" == "None" && "$playerid" != "None" ]]; then
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
        if [[ -z "$old_player_info" ]]; then continue; fi
        local old_userid old_name
        old_userid=$(echo "$old_player_info" | jq -r '.userId | ltrimstr("steam_")')
        old_name=$(echo "$old_player_info" | jq -r '.name' | sed 's/[\x00-\x1F\x7F"\\]//g')

        local found=false
        for player_info in "${current_players[@]}"; do
            if [[ -z "$player_info" ]]; then continue; fi
            local userid
            userid=$(echo "$player_info" | jq -r '.userId | ltrimstr("steam_")')
            if [[ "$old_userid" == "$userid" ]]; then
                found=true
                break
            fi
        done
        if ! $found; then
            announce_leave "$old_name"
        fi
    done

    if [[ ${#current_players[@]} -eq 0 ]]; then
        e "No players currently on the server."
    fi
}


# Function to announce a player join
announce_join() {
    time=$(date '+[%H:%M:%S]')
    message="Player $1 has joined the server."
    echo "${time}: $message"
    if [[ -n $WEBHOOK_ENABLED ]] && [[ "${WEBHOOK_ENABLED,,}" == "true" ]]; then
        send_info_notification "$message"
    fi
    if [[ -n $RESTAPI_ENABLED ]] && [[ "${RESTAPI_ENABLED,,}" == "true" ]]; then
        broadcast_player_join "${1}"
    fi
}

# Function to announce a player name change
announce_name_change() {
    time=$(date '+[%H:%M:%S]')
    message="Player $1 has changed their name to $2."
    echo "${time}: $message"
    if [[ -n $WEBHOOK_ENABLED ]] && [[ "${WEBHOOK_ENABLED,,}" == "true" ]]; then
        send_info_notification "$message"
    fi
    if [[ -n $RESTAPI_ENABLED ]] && [[ "${RESTAPI_ENABLED,,}" == "true" ]]; then
        broadcast_player_name_change "${1}" "${2}"
    fi
}

# Function to announce a player leave
announce_leave() {
    time=$(date '+[%H:%M:%S]')
    message="Player $1 has left the server."
    echo "${time}: $message"
    if [[ -n $WEBHOOK_ENABLED ]] && [[ "${WEBHOOK_ENABLED,,}" == "true" ]]; then
        send_info_notification "$message"
    fi
    if [[ -n $RESTAPI_ENABLED ]] && [[ "${RESTAPI_ENABLED,,}" == "true" ]]; then
        broadcast_player_leave "${1}"
    fi
}
