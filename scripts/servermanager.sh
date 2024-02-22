#!/bin/bash
# shellcheck disable=SC1091
# IF Bash extension used:
# https://stackoverflow.com/a/13864829
# https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02

set -e

source /includes/colors.sh
source /includes/config.sh
source /includes/cron.sh
source /includes/playerdetection.sh
source /includes/security.sh
source /includes/server.sh
source /includes/webhook.sh

START_MAIN_PID=
PLAYER_DETECTION_PID=



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
    current_date=$(date +%Y-%m-%d)
    current_time=$(date +%H:%M:%S)
    ei ">>> Starting server manager"
    e "> Started at: $current_date $current_time"
    start_main &
    START_MAIN_PID="$!"

    if [[ -n $RCON_PLAYER_DETECTION ]] && [[ $RCON_PLAYER_DETECTION == "true" ]] && [[ -n $RCON_ENABLED ]] && [[ $RCON_ENABLED == "true" ]]; then
       player_detection_loop &
       PLAYER_DETECTION_PID="$!"
       echo $PLAYER_DETECTION_PID > PLAYER_DETECTION.PID
       e "> Player detection thread started with pid ${PLAYER_DETECTION_PID}"
    fi

    e "> Server main thread started with pid ${START_MAIN_PID}"
    wait ${START_MAIN_PID}

    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_stop_notification
    fi
    exit 0;
done
