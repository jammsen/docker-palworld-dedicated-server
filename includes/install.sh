# Function to install the gameserver
function install_server() {
    # force a fresh install of all
    echo ">>> Doing a fresh install of the gameserver"
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_install_notification
    fi
    /home/steam/steamcmd/steamcmd.sh +force_install_dir "$GAME_PATH" +login anonymous +app_update 2394010 validate +quit
}

# Function to update the gameserver
function update_server() {
    # force an update and validation
    if [[ -n $STEAMCMD_VALIDATE_FILES ]] && [[ $STEAMCMD_VALIDATE_FILES == "true" ]]; then
        echo ">>> Doing an update and validate of the gameserver files"
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_update_and_validate_notification
        fi
        /home/steam/steamcmd/steamcmd.sh +force_install_dir "$GAME_PATH" +login anonymous +app_update 2394010 validate +quit
    else
        echo ">>> Doing an update of the gameserver files"
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_update_notification
        fi
        /home/steam/steamcmd/steamcmd.sh +force_install_dir "$GAME_PATH" +login anonymous +app_update 2394010 +quit
    fi
}
