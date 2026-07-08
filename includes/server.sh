# shellcheck disable=SC2148,SC1091

source /includes/colors.sh
source /includes/restapi.sh
source /includes/webhook.sh

function check_and_run_custom_script() {
    if [[ -z $CUSTOM_SCRIPT_ENABLED ]] || [[ "${CUSTOM_SCRIPT_ENABLED,,}" != "true" ]]; then
        return 0
    fi

    ei ">>> Custom script is enabled"

    # Validate CUSTOM_SCRIPT_PATH is set
    if [[ -z $CUSTOM_SCRIPT_PATH ]]; then
        ee ">>> CUSTOM_SCRIPT_PATH is not set, skipping custom script execution"
        return 0
    fi

    # Security: require an absolute path to prevent relative-path or injection tricks
    if [[ "$CUSTOM_SCRIPT_PATH" != /* ]]; then
        ee ">>> CUSTOM_SCRIPT_PATH must be an absolute path (got: '$CUSTOM_SCRIPT_PATH'), skipping"
        return 0
    fi

    # Security: reject any path containing '..' to prevent traversal
    if [[ "$CUSTOM_SCRIPT_PATH" == *".."* ]]; then
        ee ">>> CUSTOM_SCRIPT_PATH must not contain '..', skipping"
        return 0
    fi

    # Check that the target is a regular file
    if [[ ! -f "$CUSTOM_SCRIPT_PATH" ]]; then
        ew "> Custom script not found at '$CUSTOM_SCRIPT_PATH', skipping"
        return 0
    fi

    ei "> Found custom script at '$CUSTOM_SCRIPT_PATH', preparing to execute"
    chmod u+x "$CUSTOM_SCRIPT_PATH"

    ei "> Executing custom script..."
    local custom_script_exit_code=0
    # The '||' prevents set -e from aborting on a non-zero exit so we can log it
    "$CUSTOM_SCRIPT_PATH" || custom_script_exit_code=$?

    if [[ $custom_script_exit_code -ne 0 ]]; then
        ee ">>> Custom script exited with error code $custom_script_exit_code, continuing server startup"
    else
        es ">>> Custom script completed successfully"
    fi
}

function start_server() {
    cd "$GAME_ROOT" || exit
    setup_configs
    ei ">>> Preparing to start the gameserver"
    START_OPTIONS=()
    if [[ -n $COMMUNITY_SERVER ]] && [[ "${COMMUNITY_SERVER,,}" == "true" ]]; then
        e "> Setting Community-Mode to enabled"
        START_OPTIONS+=("-publiclobby")
    fi
    if [[ -n $MULTITHREAD_ENABLED ]] && [[ "${MULTITHREAD_ENABLED,,}" == "true" ]]; then
        e "> Setting Multi-Core-Enhancements to enabled"
        START_OPTIONS+=("-useperfthreads" "-NoAsyncLoadingThread" "-UseMultithreadForDS")
    fi
    if [[ -n $WEBHOOK_ENABLED ]] && [[ "${WEBHOOK_ENABLED,,}" == "true" ]]; then
        send_start_notification
    fi
    check_and_run_custom_script

    es ">>> Starting the gameserver"
    ./PalServer.sh "${START_OPTIONS[@]}"
}

function stop_server() {
    ew ">>> Stopping server..."
    kill -SIGTERM "${PLAYER_DETECTION_PID}"
    if [[ -n $RESTAPI_ENABLED ]] && [[ "${RESTAPI_ENABLED,,}" == "true" ]]; then
        save_and_shutdown_server
    fi
	kill -SIGTERM "$(pidof PalServer-Linux-Shipping)"
	tail --pid="$(pidof PalServer-Linux-Shipping)" -f 2>/dev/null
    if [[ -n $WEBHOOK_ENABLED ]] && [[ "${WEBHOOK_ENABLED,,}" == "true" ]]; then
        send_stop_notification
    fi
    ew ">>> Server stopped gracefully"
    exit 143;
}

function run_steamcmd() {
    local attempt exit_code
    for attempt in 1 2 3; do
        exit_code=0
        # The '||' prevents set -e from aborting on a non-zero exit so we can retry
        "${STEAMCMD_PATH}"/steamcmd.sh "$@" || exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            return 0
        fi
        ew ">>> SteamCMD failed with exit code ${exit_code} (attempt ${attempt}/3) - clearing SteamCMD update state and retrying"
        rm -rf "${STEAMCMD_PATH}/package"
        sleep 5
    done
    ee ">>> SteamCMD failed 3 times in a row - giving up, container will restart"
    exit 1
}

function fresh_install_server() {
    ei ">>> Doing a fresh install of the gameserver..."
    if [[ -n $WEBHOOK_ENABLED ]] && [[ "${WEBHOOK_ENABLED,,}" == "true" ]]; then
        send_install_notification
    fi
    run_steamcmd +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 validate +quit
    es "> Done installing the gameserver"
}

function update_server() {
    # Workaround fix for 0x6 error
    ei ">>> Checking if appmainfest_2394010.acf exists, which can cause the 'Error! App '2394010' state is 0x6 after update job"
    if [[ -f /palworld/steamapps/appmanifest_2394010.acf ]]; then
        ei ">>> Applying workaround fix for 'Error! App '2394010' state is 0x6 after update job.' message, since update 0.3.X..."
        rm -f /palworld/steamapps/appmanifest_2394010.acf
    fi
    if [[ -n $STEAMCMD_VALIDATE_FILES ]] && [[ "${STEAMCMD_VALIDATE_FILES,,}" == "true" ]]; then
        ei ">>> Doing an update with validation of the gameserver files..."
        if [[ -n $WEBHOOK_ENABLED ]] && [[ "${WEBHOOK_ENABLED,,}" == "true" ]]; then
            send_update_notification
        fi
        run_steamcmd +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 validate +quit
        es ">>> Done updating and validating the gameserver files"
    else
        ei ">>> Doing an update of the gameserver files..."
        if [[ -n $WEBHOOK_ENABLED ]] && [[ "${WEBHOOK_ENABLED,,}" == "true" ]]; then
            send_update_notification
        fi
        run_steamcmd +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 +quit
        es ">>> Done updating the gameserver files"
    fi
}
