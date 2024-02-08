# shellcheck disable=SC2148,SC1091

source /includes/colors.sh
source /includes/webhook.sh

steamcmd_dir="/home/steam/steamcmd"

# Function to install the gameserver
function install_server() {
    # Force a fresh install of all
    ew ">> Doing a fresh install of the gameserver..."

    send_install_notification

    "${steamcmd_dir}"/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 validate +quit
    es ">>> Done installing the gameserver."
}

function update_server() {
    if [[ -n $STEAMCMD_VALIDATE_FILES ]] && [[ $STEAMCMD_VALIDATE_FILES == "true" ]]; then
        ew ">> Doing an update and validate of the gameserver files..."
        
        send_update_and_validate_notification

        "${steamcmd_dir}"/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 validate +quit
        es ">>> Done updating and validating the gameserver files."

    else
        ew ">> Doing an update of the gameserver files..."

        send_update_notification

        "${steamcmd_dir}"/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 +quit
        es ">>> Done updating the gameserver files."
    fi
}
