#!/bin/bash
# shellcheck disable=SC1091

set -e

source /includes/colors.sh
source /includes/server.sh
source /includes/webhook.sh

function schedule_restart() {
    PLAYER_DETECTION_PID=$(<PLAYER_DETECTION.PID)
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_restart_notification
    fi

    for ((counter=15; counter>=1; counter--)); do
        if [[ -n $RCON_ENABLED ]] && [[ $RCON_ENABLED == "true" ]]; then
            time=$(date '+%H:%M:%S')
            rconcli "broadcast ${time}-AUTOMATIC-RESTART-IN-$counter-MINUTES"
        fi
        if [[ -n $RESTART_DEBUG_OVERRIDE ]] && [[ $RESTART_DEBUG_OVERRIDE == "true" ]]; then
            sleep 1
        else
            sleep 60
        fi 
    done

    if [[ -n $RCON_ENABLED ]] && [[ $RCON_ENABLED == "true" ]]; then
        rconcli 'broadcast Saving-world-before-restart...'
        rconcli 'save'
        rconcli 'broadcast Saving-done'
        sleep 15
        kill -SIGTERM "${PLAYER_DETECTION_PID}"
        rcon "Shutdown 10"
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_stop_notification
        fi
    else
        ew ">>> Stopping server..."
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_stop_notification
        fi
        kill -SIGTERM "$(pidof PalServer-Linux-Test)"
        tail --pid="$(pidof PalServer-Linux-Test)" -f 2>/dev/null
        kill -SIGTERM "${PLAYER_DETECTION_PID}"
        ew ">>> Server stopped gracefully"
        exit 143;
    fi
}

schedule_restart