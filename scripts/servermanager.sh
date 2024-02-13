#!/bin/bash
# shellcheck disable=SC1091
# IF Bash extension used:
# https://stackoverflow.com/a/13864829
# https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02

set -e

source /includes/colors.sh
source /includes/config.sh
source /includes/cron.sh
source /includes/security.sh
source /includes/server.sh
source /includes/webhook.sh

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

    killpid="$!"
    e "> Server main thread started with pid ${killpid}"
    wait ${killpid}

    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_stop_notification
    fi
    exit 0;
done
