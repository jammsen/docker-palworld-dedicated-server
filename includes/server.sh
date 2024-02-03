#!/bin/bash
# Stop on errors, comment in, if needed
#set -e
source /config.sh
source /cron.sh
source /install.sh
source /rcon.sh
source /security.sh
source /webhook.sh

GAME_PATH="/palworld"

function start_server() {
    # IF Bash extension used:
    # https://stackoverflow.com/a/13864829
    # https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02

    echo ">>> Starting the gameserver"
    cd $GAME_PATH

    setup_engine_ini
    setup_pal_world_settings_ini

    START_OPTIONS=""
    if [[ -n $COMMUNITY_SERVER ]] && [[ $COMMUNITY_SERVER == "true" ]]; then
        echo "> Setting Community-Mode to enabled"
        START_OPTIONS="$START_OPTIONS EpicApp=PalServer"
    fi
    if [[ -n $MULTITHREAD_ENABLED ]] && [[ $MULTITHREAD_ENABLED == "true" ]]; then
        echo "> Setting Multi-Core-Enchancements to enabled"
        START_OPTIONS="$START_OPTIONS -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS"
    fi
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_start_notification
    fi
    ./PalServer.sh "$START_OPTIONS"
}

function start_main() {
    check_for_default_credentials
    setup_crons
    if [ ! -f "$GAME_PATH/PalServer.sh" ]; then
        install_server
    fi
    if [ $ALWAYS_UPDATE_ON_START == "true" ]; then
        update_server
    fi
    start_server
}

term_handler() {
  local exit_code = ${1:-143}

  if [ -z "$(pidof PalServer-Linux-Test)" ]; then
    exit $exit_code
  fi

  if [[ ! -z ${RCON_ENABLED+x} ]]; then
      save_and_shutdown_server
  fi
	kill -SIGTERM $(pidof PalServer-Linux-Test)
	tail --pid=$(pidof PalServer-Linux-Test) -f 2>/dev/null
  send_stop_notification

	exit $exit_code;
}
