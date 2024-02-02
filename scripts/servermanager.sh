#!/bin/bash
# shellcheck disable=SC1091

# Stop on errors, comment in, if needed
#set -e

### Includes
source /includes/config.sh
source /includes/cron.sh
source /includes/rcon.sh
source /includes/security.sh
source /includes/webhook.sh
source /includes/colors.sh

steamcmd_dir="/home/steam/steamcmd"

### Server Functions

function start_server() {
    # IF Bash extension used:
    # https://stackoverflow.com/a/13864829
    # https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02

    es "\n>>> Starting the gameserver\n"
    cd "$GAME_ROOT" || exit

    setup_configs

    START_OPTIONS=""
    if [[ -n $COMMUNITY_SERVER ]] && [[ $COMMUNITY_SERVER == "true" ]]; then
        ei "> Setting Community-Mode to enabled\n"
        START_OPTIONS="$START_OPTIONS EpicAcolorful_echos=PalServer"
    fi
    if [[ -n $MULTITHREAD_ENABLED ]] && [[ $MULTITHREAD_ENABLED == "true" ]]; then
        ei "> Setting Multi-Core-Enhancements to enabled\n"
        START_OPTIONS="$START_OPTIONS -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS"
    fi
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_webhook_notification "$WEBHOOK_START_TITLE" "$WEBHOOK_START_DESCRIPTION" "$WEBHOOK_START_COLOR"
    fi
    ./PalServer.sh "$START_OPTIONS"
}

function stop_server() {
    ew ">>> Stopping server...\n\n"

    rcon 'broadcast Server_Shutdown_requested'
    rcon 'broadcast Saving...'
    rcon 'save'
    rcon 'broadcast Done...'

	kill -SIGTERM "$(pidof PalServer-Linux-Test)"
	tail --pid="$(pidof PalServer-Linux-Test)" -f 2>/dev/null

    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_webhook_notification "$WEBHOOK_STOP_TITLE" "$WEBHOOK_STOP_DESCRIPTION" "$WEBHOOK_STOP_COLOR"
    fi
	
    exit 143;
}

function install_server() {
    # Force a fresh install of all
    es "\n>>> Doing a fresh install of the gameserver...\n\n"
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_webhook_notification "Installing server" "Server is beeing installed" "$WEBHOOK_INFO_COLOR"
    fi
    ${steamcmd_dir}/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 validate +quit
    es ">>> Done installing the gameserver.\n"
}

function update_server() {
    # Force an update and validation
    if [[ -n $STEAMCMD_VALIDATE_FILES ]] && [[ $STEAMCMD_VALIDATE_FILES == "true" ]]; then
        es "\n>>> Doing an update and validate of the gameserver files...\n\n"
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_webhook_notification "Updating server" "Server is beeing updated and validated" "$WEBHOOK_INFO_COLOR"
        fi
        ${steamcmd_dir}/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 validate +quit
        es ">>> Done updating and validating the gameserver files.\n"

    else
        es "\n>>> Doing an update of the gameserver files...\n\n"
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_webhook_notification "Updating server" "Server is beeing updated" "$WEBHOOK_INFO_COLOR"
        fi
        ${steamcmd_dir}/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 +quit
        es ">>> Done updating the gameserver files.\n"
    fi
}


### Signal Handling (Handlers & Traps)

# Handler for SIGTERM from docker stop command
function termHandler() {
    stopServer
}

function start_handlers() {
    es "\n>>> Starting handlers...\n"

    es "> Starting termination handler...\n"
    # If SIGTERM is sent to the process, call termHandler function
    trap 'kill ${!}; termHandler' SIGTERM

    es "> Termination handler started!\n"
}


### Main Function

function start_main() {
    es "\n>>> Starting main thread <<<\n"

    check_for_default_credentials

    # Check if server is installed, if not try again
    if [ ! -f "${GAME_ROOT}/PalServer.sh" ]; then
        install_server
    fi
    if [ "${ALWAYS_UPDATE_ON_START}" == "true" ]; then
        update_server
    fi
    
    setup_crons
    
    start_server
}


### Server Manager Initialization

# Server manager is running in a loop, so we can restart the server
while true
do
    es ">>> Starting server manager <<<\n"
    start_handlers

    # Start the server manager
    start_main &

    killpid="$!"
    es "\n>>> Server main thread started with pid ${killpid}\n"
    wait ${killpid}
    
    ew "\n\n>>> Exiting server...\n"

    exit 0;
done
