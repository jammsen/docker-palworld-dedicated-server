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

    if [ ! -f ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini ]; then
        if [ ! -d ${GAME_PATH}/Pal/Saved/Config/LinuxServer ]; then
            mkdir -p ${GAME_PATH}/Pal/Saved/Config/LinuxServer
        fi
        wget -qO ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini https://raw.githubusercontent.com/jammsen/docker-palworld-dedicated-server/master/PalWorldSettings.ini
        sed -i -e "s/###RANDOM###/$RANDOM/g" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
        if [[ -n $PUBLIC_IP ]]; then
            sed -i -e "s/###IP###/$PUBLIC_IP/g" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
        fi
        if [[ -n $PUBLIC_PORT ]]; then
            sed -i -e "s/###PORT###/$PUBLIC_PORT/g" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
        fi
    fi

    START_OPTIONS=""
    if [[ -n $COMMUNITY_SERVER ]] && [[ $COMMUNITY_SERVER == "true" ]]; then
        START_OPTIONS="$START_OPTIONS EpicApp=PalServer"
    fi
    if [[ -n $MULTITHREAD_ENABLED ]] && [[ $MULTITHREAD_ENABLED == "true" ]]; then
        START_OPTIONS="$START_OPTIONS -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS"
    fi
    ./PalServer.sh "$START_OPTIONS" 
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
