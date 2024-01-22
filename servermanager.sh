#!/bin/bash

GAME_PATH="/palworld"

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
    # IF Bash extendion usaged:
    # https://stackoverflow.com/a/13864829
    # https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02

    echo ">>> Starting the gameserver"
    cd $GAME_PATH

    echo "Checking if config exists"
    if [ ! -f ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini ]; then
        echo "No config found, generating one"
        if [ ! -d ${GAME_PATH}/Pal/Saved/Config/LinuxServer ]; then
            mkdir -p ${GAME_PATH}/Pal/Saved/Config/LinuxServer
        fi
        # Copy default-config, which comes with the server to gameserver-save location
        cp ${GAME_PATH}/DefaultPalWorldSettings.ini ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi

    if [[ ! -z ${RCON_ENABLED+x} ]]; then
        echo "Setting rcon-enabled to $RCON_ENABLED"
        sed -i "s/RCONEnabled=[a-zA-Z]*/RCONEnabled=$RCON_ENABLED/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${RCON_PORT+x} ]]; then
        echo "Setting rcon-port to $RCON_PORT"
        sed -i "s/RCONPort=[0-9]*/RCONPort=$RCON_PORT/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PUBLIC_IP+x} ]]; then
        echo "Setting public ip to $PUBLIC_IP"
        sed -i "s/PublicIP=\"[^\"]*\"/PublicIP=\"$PUBLIC_IP\"/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PUBLIC_PORT+x} ]]; then
        echo "Setting public port to $PUBLIC_PORT"
        sed -i "s/PublicPort=[0-9]*/PublicPort=$PUBLIC_PORT/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${SERVER_NAME+x} ]]; then
        echo "Setting server name to $SERVER_NAME"
        sed -i "s/ServerName=\"[^\"]*\"/ServerName=\"$SERVER_NAME\"/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
        if [[ "$SERVER_NAME" == *"###RANDOM###"* ]]; then
            RAND_VALUE=$RANDOM
            echo "Found standard template, using random numbers in server name"
            sed -i -e "s/###RANDOM###/$RAND_VALUE/g" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
            echo "Server name is now jammsen-docker-generated-$RAND_VALUE"
        fi
    fi
    if [[ ! -z ${SERVER_DESCRIPTION+x} ]]; then
        echo "Setting server description to $SERVER_DESCRIPTION"
        sed -i "s/ServerDescription=\"[^\"]*\"/ServerDescription=\"$SERVER_DESCRIPTION\"/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${SERVER_PASSWORD+x} ]]; then
        echo "Setting server password to $SERVER_PASSWORD"
        sed -i "s/ServerPassword=\"[^\"]*\"/ServerPassword=\"$SERVER_PASSWORD\"/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${ADMIN_PASSWORD+x} ]]; then
        echo "Setting server admin password to $ADMIN_PASSWORD"
        sed -i "s/AdminPassword=\"[^\"]*\"/AdminPassword=\"$ADMIN_PASSWORD\"/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${MAX_PLAYERS+x} ]]; then
        echo "Setting max-players to $MAX_PLAYERS"
        sed -i "s/ServerPlayerMaxNum=[0-9]*/ServerPlayerMaxNum=$MAX_PLAYERS/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
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

term_handler() {
	kill -SIGTERM $(pidof PalServer-Linux-Test)
	tail --pid=$(pidof PalServer-Linux-Test) -f 2>/dev/null
	exit 143;
}

trap 'kill ${!}; term_handler' SIGTERM

startMain &
killpid="$!"
while true
do
  wait $killpid
  exit 0;
done
