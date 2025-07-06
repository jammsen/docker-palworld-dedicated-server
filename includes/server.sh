# shellcheck disable=SC2148,SC1091

source /includes/colors.sh
source /includes/rcon.sh
source /includes/webhook.sh

function start_server() {
    cd "$GAME_ROOT" || exit
    setup_configs
    ei ">>> Preparing to start the gameserver"
    START_OPTIONS=()
    if [[ -n $COMMUNITY_SERVER ]] && [[ $COMMUNITY_SERVER == "true" ]]; then
        e "> Setting Community-Mode to enabled"
        START_OPTIONS+=("-publiclobby")
    fi
    if [[ -n $MULTITHREAD_ENABLED ]] && [[ $MULTITHREAD_ENABLED == "true" ]]; then
        e "> Setting Multi-Core-Enhancements to enabled"
        START_OPTIONS+=("-useperfthreads" "-NoAsyncLoadingThread" "-UseMultithreadForDS")
    fi
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_start_notification
    fi
    if [[ -n $ENABLE_UE4SS ]] && [[ $ENABLE_UE4SS == "true" ]]; then
        if [ ! -f "./PalServerUE4SS.sh" ]; then
            e "> Installing UE4SS and setting up LD_PRELOAD"
            UE4SS_ROOT=${GAME_ROOT}/ue4ss
            mkdir -p ${UE4SS_ROOT}

            # Install UE4SS linux build as per https://github.com/UE4SS-RE/RE-UE4SS/issues/364#issuecomment-2578762122
            curl -fsSLo ${UE4SS_ROOT}/UE4SS.zip https://github.com/Yangff/RE-UE4SS/releases/download/linux-experiment/UE4SS_0.0.0.zip
            unzip -uo ${UE4SS_ROOT}/UE4SS.zip -d ${UE4SS_ROOT}
            rm ${UE4SS_ROOT}/UE4SS.zip

            sed -i "s|^\(GuiConsoleEnabled =\).*|\1 0|" ${UE4SS_ROOT}/UE4SS-settings.ini
            sed -i "s|^\(bUseUObjectArrayCache =\).*|\1 false|" ${UE4SS_ROOT}/UE4SS-settings.ini

            # BPModLoaderMod workaround
            curl -fsSLo ${UE4SS_ROOT}/Mods/BPModLoaderMod/Scripts/main.lua https://raw.githubusercontent.com/Okaetsu/RE-UE4SS/refs/heads/logicmod-temp-fix/assets/Mods/BPModLoaderMod/Scripts/main.lua

            # Update MemberVariableLayout as per https://github.com/UE4SS-RE/RE-UE4SS/issues/802#issuecomment-2698705933
            curl -fsSLo ${UE4SS_ROOT}/MemberVariableLayout.ini https://raw.githubusercontent.com/UE4SS-RE/RE-UE4SS/main/assets/MemberVarLayoutTemplates/MemberVariableLayout_5_01_Template.ini
            crudini --set ${UE4SS_ROOT}/MemberVariableLayout.ini UEnum CppForm 0x58
            crudini --set ${UE4SS_ROOT}/MemberVariableLayout.ini UEnum CppType 0x30
            crudini --set ${UE4SS_ROOT}/MemberVariableLayout.ini UEnum EnumDisplayNameFn 0x60
            crudini --del ${UE4SS_ROOT}/MemberVariableLayout.ini UEnum EnumFlags
            crudini --set ${UE4SS_ROOT}/MemberVariableLayout.ini UEnum EnumFlags_Internal 0x5C
            crudini --set ${UE4SS_ROOT}/MemberVariableLayout.ini UEnum EnumPackage 0x68
            crudini --set ${UE4SS_ROOT}/MemberVariableLayout.ini UEnum Names 0x48

            cp ./PalServer.sh ./PalServerUE4SS.sh
            sed -i 's|^\("$UE_PROJECT_ROOT/Pal/Binaries/Linux/PalServer-Linux-Shipping" Pal "$@"\)|LD_PRELOAD=${GAME_ROOT}/ue4ss/libUE4SS.so \1|' ./PalServerUE4SS.sh
        fi
    fi
    es ">>> Starting the gameserver"
    if [[ -n $ENABLE_UE4SS ]] && [[ $ENABLE_UE4SS == "true" ]]; then
        ./PalServerUE4SS.sh "${START_OPTIONS[@]}"
    else
        ./PalServer.sh "${START_OPTIONS[@]}"
    fi
}

function stop_server() {
    ew ">>> Stopping server..."
    kill -SIGTERM "${PLAYER_DETECTION_PID}"
    if [[ -n $RCON_ENABLED ]] && [[ $RCON_ENABLED == "true" ]]; then
        save_and_shutdown_server
    fi
	kill -SIGTERM "$(pidof PalServer-Linux-Shipping)"
	tail --pid="$(pidof PalServer-Linux-Shipping)" -f 2>/dev/null
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_stop_notification
    fi
    ew ">>> Server stopped gracefully"
    exit 143;
}

function fresh_install_server() {
    ei ">>> Doing a fresh install of the gameserver..."
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_install_notification
    fi
    "${STEAMCMD_PATH}"/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 validate +quit
    es "> Done installing the gameserver"
}

function update_server() {
    # Workaround fix for 0x6 error
    ei ">>> Applying workaround fix for 'Error! App '2394010' state is 0x6 after update job.' message, since update 0.3.X..."
    rm -f /palworld/steamapps/appmanifest_2394010.acf
    if [[ -n $STEAMCMD_VALIDATE_FILES ]] && [[ $STEAMCMD_VALIDATE_FILES == "true" ]]; then
        ei ">>> Doing an update with validation of the gameserver files..."
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_update_notification
        fi
        "${STEAMCMD_PATH}"/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 validate +quit
        es ">>> Done updating and validating the gameserver files"
    else
        ei ">>> Doing an update of the gameserver files..."
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_update_notification
        fi
        "${STEAMCMD_PATH}"/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 +quit
        es ">>> Done updating the gameserver files"
    fi
}
