#!/bin/bash

GAME_PATH="/palworld/"

function installServer() {
    # force a fresh install of all
    echo ">>> Doing a fresh install of the gameserver"
    /home/steam/steamcmd/steamcmd.sh +force_install_dir "/palworld" +login anonymous +app_update 2394010 validate +quit
}

function updateServer() {
    # force an update and validation
    echo ">>> Doing an update of the gameserver"
    /home/steam/steamcmd/steamcmd.sh +force_install_dir "/palworld" +login anonymous +app_update 2394010 validate +quit
}

function startServer() {
    echo ">>> Starting the gameserver"
    cd $GAME_PATH
    START_OPTIONS=""
    if [[ -n $COMMUNITY_SERVER ]] && [[ $COMMUNITY_SERVER == "true" ]]; then
        START_OPTIONS="$START_OPTIONS EpicApp=PalServer"
    fi
    if [[ -n $MULTITHREAD_ENABLED ]] && [[ $MULTITHREAD_ENABLED == "true" ]]; then
        START_OPTIONS="$START_OPTIONS -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS"
    fi
    if [[ -n $PUBLIC_IP ]]; then
        START_OPTIONS="$START_OPTIONS -publicip=$PUBLIC_IP"
    fi
    if [[ -n $PUBLIC_PORT ]]; then
        START_OPTIONS="$START_OPTIONS -publicport=$PUBLIC_PORT"
    fi
    if [[ -n $SERVER_PASSWORD ]]; then
        START_OPTIONS="$START_OPTIONS -serverpassword=$SERVER_PASSWORD"
    fi

    ./PalServer.sh port="$GAME_PORT" players="$MAX_PLAYERS" "$START_OPTIONS" -servername="$SERVER_NAME"
}

function startMain() {
    # Check if server is installed, if not try again
    if [ ! -f "/palworld/PalServer.sh" ]; then
        installServer
    fi
    if [ $ALWAYS_UPDATE_ON_START == "true" ]; then
        updateServer
    fi
    startServer
}

startMain
