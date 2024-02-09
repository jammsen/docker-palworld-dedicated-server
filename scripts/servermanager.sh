#!/bin/bash
# shellcheck disable=SC1091
# IF Bash extension used:
# https://stackoverflow.com/a/13864829
# https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02

set -e

source /includes/install.sh
source /includes/config.sh
source /includes/cron.sh
source /includes/security.sh
source /includes/webhook.sh
source /includes/colors.sh

function start_server() {
    cd "$GAME_ROOT" || exit
    setup_configs
    START_OPTIONS=()
    if [[ -n $COMMUNITY_SERVER ]] && [[ $COMMUNITY_SERVER == "true" ]]; then
        ei "> Setting Community-Mode to enabled\n"
        START_OPTIONS+=("EpicApp=PalServer")
    fi
    if [[ -n $MULTITHREAD_ENABLED ]] && [[ $MULTITHREAD_ENABLED == "true" ]]; then
        ei "> Setting Multi-Core-Enhancements to enabled\n"
        START_OPTIONS+=("-useperfthreads" "-NoAsyncLoadingThread" "-UseMultithreadForDS")
    fi
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_start_notification
    fi
    es ">>> Starting the gameserver\n"
    ./PalServer.sh "${START_OPTIONS[@]}"
}

function stop_server() {
    ew ">>> Stopping server...\n"
    if [[ -n $RCON_ENABLED ]] && [[ $RCON_ENABLED == "true" ]]; then
        save_and_shutdown_server
    fi
	kill -SIGTERM "$(pidof PalServer-Linux-Test)"
	tail --pid="$(pidof PalServer-Linux-Test)" -f 2>/dev/null
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_stop_notification
    fi
    ew ">>> Server stopped gracefully.\n\n"
    exit 143;
}

# Handler for SIGTERM from docker-based stop events
function term_handler() {
    stop_server
}

# Main process thread
function start_main() {
    check_for_default_credentials
    if [ ! -f "${GAME_ROOT}/PalServer.sh" ]; then
        fresh_install_server
    fi
    if [ "${ALWAYS_UPDATE_ON_START}" == "true" ]; then
        update_server
    fi
    setup_crons
    start_server
}

# Bash-Trap for exit signals to handle
trap 'kill ${!}; term_handler' SIGTERM

# Main process loop
while true
do
    ei ">>> Starting server manager\n"
    start_main &

    killpid="$!"
    ei "> Server main thread started with pid ${killpid}\n"
    wait ${killpid}

    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_stop_notification
    fi
    exit 0;
done
