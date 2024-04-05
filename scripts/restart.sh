#!/bin/bash
# shellcheck disable=SC1091

set -e

source /includes/colors.sh
source /includes/server.sh
source /includes/webhook.sh

function get_time() {
    date '+[%H:%M:%S]'
}

function schedule_restart() {
    ew ">>> Automatic restart was triggered..."
    PLAYER_DETECTION_PID=$(<PLAYER_DETECTION.PID)
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_restart_planned_notification
    fi

    for ((counter=15; counter>=1; counter--)); do
        if [[ -n $RCON_ENABLED ]] && [[ $RCON_ENABLED == "true" ]]; then
            if check_is_server_empty; then
                ew ">>> Server is empty, restarting now"
                if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
                    send_restart_now_notification
                fi
                break
            else
                ew ">>> Server has still players"
            fi
            rconcli broadcast "$(get_time) AUTOMATIC RESTART IN $counter MINUTES"
        fi
        if [[ -n $RESTART_DEBUG_OVERRIDE ]] && [[ $RESTART_DEBUG_OVERRIDE == "true" ]]; then
            sleep 1
        else
            sleep 60
        fi
    done

    if [[ -n $RCON_ENABLED ]] && [[ $RCON_ENABLED == "true" ]]; then
        rconcli broadcast "$(get_time) Saving world before restart..."
        rconcli save
        rconcli broadcast "$(get_time) Saving done"
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
        kill -SIGTERM "$(pidof PalServer-Linux-Shipping)"
        tail --pid="$(pidof PalServer-Linux-Shipping)" -f 2>/dev/null
        kill -SIGTERM "${PLAYER_DETECTION_PID}"
        ew ">>> Server stopped gracefully"
        exit 143;
    fi
}

schedule_restart
