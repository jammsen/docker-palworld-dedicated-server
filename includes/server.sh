# shellcheck disable=SC2148,SC1091

source /includes/colors.sh
source /includes/rcon.sh
source /includes/webhook.sh

function start_server() {
    cd "$GAME_ROOT" || exit
    setup_configs
    ei ">>> Preparing to start the gameserver"
    START_OPTIONS=()
    if [[ -n $COMMUNITY_SERVER ]] && [[ $COMMUNITY_SERVER == "true" ]]; then
        e "> Setting Community-Mode to enabled"
        START_OPTIONS+=("EpicApp=PalServer")
    fi
    if [[ -n $MULTITHREAD_ENABLED ]] && [[ $MULTITHREAD_ENABLED == "true" ]]; then
        e "> Setting Multi-Core-Enhancements to enabled"
        START_OPTIONS+=("-useperfthreads" "-NoAsyncLoadingThread" "-UseMultithreadForDS")
    fi
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_start_notification
    fi

    if [[ -n $RCON_ENABLED ]] && [[ $RCON_ENABLED == "true" ]] && \
       [ "${ENABLE_PLAYER_LOGGING,,}" = true ] && [[ "${PLAYER_LOGGING_POLL_PERIOD}" =~ ^[0-9]+$ ]]; then
        player_logging &
    fi

    es ">>> Starting the gameserver"
    ./PalServer.sh "${START_OPTIONS[@]}"
}

function stop_server() {
    ew ">>> Stopping server..."
    if [[ -n $RCON_ENABLED ]] && [[ $RCON_ENABLED == "true" ]]; then
        save_and_shutdown_server
    fi
	kill -SIGTERM "$(pidof PalServer-Linux-Test)"
	tail --pid="$(pidof PalServer-Linux-Test)" -f 2>/dev/null
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_stop_notification
    fi
    ew ">>> Server stopped gracefully"
    exit 143;
}

function fresh_install_server() {
    ei ">>> Doing a fresh install of the gameserver..."
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_install_notification
    fi
    "${STEAMCMD_PATH}"/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 validate +quit
    es "> Done installing the gameserver"
}

function update_server() {
    if [[ -n $STEAMCMD_VALIDATE_FILES ]] && [[ $STEAMCMD_VALIDATE_FILES == "true" ]]; then
        ei ">>> Doing an update with validation of the gameserver files..."
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_update_notification
        fi
        "${STEAMCMD_PATH}"/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 validate +quit
        es ">>> Done updating and validating the gameserver files"
    else
        ei ">>> Doing an update of the gameserver files..."
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_update_notification
        fi
        "${STEAMCMD_PATH}"/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 +quit
        es ">>> Done updating the gameserver files"
    fi
}
