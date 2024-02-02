# Function to install the gameserver
function install_server() {
    # force a fresh install of all
    echo ">>> Doing a fresh install of the gameserver"
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_webhook_notification "Installing server" "Server is being installed" "$WEBHOOK_INFO_COLOR"
    fi
    /home/steam/steamcmd/steamcmd.sh +force_install_dir "$GAME_PATH" +login anonymous +app_update 2394010 validate +quit
}

# Function to update the gameserver
function update_server() {
    # force an update and validation
    if [[ -n $STEAMCMD_VALIDATE_FILES ]] && [[ $STEAMCMD_VALIDATE_FILES == "true" ]]; then
        echo ">>> Doing an update and validate of the gameserver files"
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_webhook_notification "Updating server" "Server is being updated and validated" "$WEBHOOK_INFO_COLOR"
        fi
        /home/steam/steamcmd/steamcmd.sh +force_install_dir "$GAME_PATH" +login anonymous +app_update 2394010 validate +quit
    else
        echo ">>> Doing an update of the gameserver files"
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_webhook_notification "Updating server" "Server is being updated" "$WEBHOOK_INFO_COLOR"
        fi
        /home/steam/steamcmd/steamcmd.sh +force_install_dir "$GAME_PATH" +login anonymous +app_update 2394010 +quit
    fi
}
