# shellcheck disable=SC2148

steamcmd_dir="/home/steam/steamcmd"

# Function to install the gameserver
function install_server() {
    # Force a fresh install of all
    ew ">>> Doing a fresh install of the gameserver...\n"
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_webhook_notification "Installing server" "Server is beeing installed" "$WEBHOOK_INFO_COLOR"
    fi
    "${steamcmd_dir}"/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 validate +quit
    es ">> Done installing the gameserver.\n"
}

# Function to update the gameserver
function update_server() {
    # Force an update and validation
    if [[ -n $STEAMCMD_VALIDATE_FILES ]] && [[ $STEAMCMD_VALIDATE_FILES == "true" ]]; then
        ew ">> Doing an update and validate of the gameserver files...\n"
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_webhook_notification "Updating server" "Server is beeing updated and validated" "$WEBHOOK_INFO_COLOR"
        fi
        "${steamcmd_dir}"/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 validate +quit
        es ">> Done updating and validating the gameserver files.\n"

    else
        ei ">> Doing an update of the gameserver files...\n"
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_webhook_notification "Updating server" "Server is beeing updated" "$WEBHOOK_INFO_COLOR"
        fi
        "${steamcmd_dir}"/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 +quit
        es ">> Done updating the gameserver files.\n"
    fi
}