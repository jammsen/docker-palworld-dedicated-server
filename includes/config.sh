# shellcheck disable=SC2148,SC1091

source /includes/colors.sh

current_setting=1
settings_amount=89

function setup_engine_ini() {
    pattern1="OnlineSubsystemUtils.IpNetDriver"
    pattern2="^NetServerMaxTickRate=[0-9]*"
    ei ">>> Setting up Engine.ini ..."
    e "> Checking if config already exists..."
    if [ ! -f "${GAME_ENGINE_FILE}" ]; then
        ew "> No config found, generating one!"
        if [ ! -d "${GAME_CONFIG_PATH}" ]; then
            mkdir -p "${GAME_CONFIG_PATH}/"
        fi
        # Create empty Engine.ini file
        echo "" > "${GAME_ENGINE_FILE}"
    else
        e "> Found existing config!"
    fi
    if grep -qE "${pattern1}" "${GAME_ENGINE_FILE}" 2>/dev/null; then
        e "> Found [/Script/OnlineSubsystemUtils.IpNetDriver] section"
    else
        ew "> Found no [/Script/OnlineSubsystemUtils.IpNetDriver], adding it"
        echo -e "[/Script/OnlineSubsystemUtils.IpNetDriver]" >> "${GAME_ENGINE_FILE}"
    fi
    if grep -qE "${pattern2}" "${GAME_ENGINE_FILE}" 2>/dev/null; then
        e "> Found NetServerMaxTickRate parameter, changing it to '${NETSERVERMAXTICKRATE}'"
        sed -E -i "s/${pattern2}/NetServerMaxTickRate=${NETSERVERMAXTICKRATE}/" "${GAME_ENGINE_FILE}"
    else
        ew "> Found no NetServerMaxTickRate parameter, adding it with value '${NETSERVERMAXTICKRATE}'"
        echo "NetServerMaxTickRate=${NETSERVERMAXTICKRATE}" >> "${GAME_ENGINE_FILE}"
    fi
    es ">>> Finished setting up Engine.ini!"
}

function e_with_counter() {
    local padded_number
    padded_number=$(printf "%02d" $current_setting)
    # shellcheck disable=SC2145
    e "> ($padded_number/$settings_amount) Setting $@"
    current_setting=$((current_setting + 1))
}

function setup_palworld_settings_ini() {
    ei ">>> Setting up PalWorldSettings.ini ..."
    if [ ! -d "${GAME_CONFIG_PATH}" ]; then
        mkdir -p "${GAME_CONFIG_PATH}/" || {
            ee "Failed to create directory ${GAME_CONFIG_PATH}"
            return 1
        }
    fi

    # if SERVER_NAME contains ###RANDOM###, replace it now
    if [[ "${SERVER_NAME:-}" == *"###RANDOM###"* ]]; then
        # generate a 6-char alphanumeric token
        rand="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)"
        export SERVER_NAME="${SERVER_NAME//###RANDOM###/${rand}}"
    fi

    # Copy default-config, which comes with SteamCMD to gameserver save location
    ew "> Copying PalWorldSettings.ini.template to ${GAME_SETTINGS_FILE}"
    ENVSUBST_SELECTORS='$DIFFICULTY $RANDOMIZER_TYPE $RANDOMIZER_SEED $IS_RANDOMIZER_PAL_LEVEL_RANDOM 
        $DAYTIME_SPEEDRATE $NIGHTTIME_SPEEDRATE $EXP_RATE $PAL_CAPTURE_RATE 
        $PAL_SPAWN_NUM_RATE $PAL_DAMAGE_RATE_ATTACK $PAL_DAMAGE_RATE_DEFENSE 
        $PLAYER_DAMAGE_RATE_ATTACK $PLAYER_DAMAGE_RATE_DEFENSE 
        $PLAYER_STOMACH_DECREASE_RATE $PLAYER_STAMINA_DECREACE_RATE 
        $PLAYER_AUTO_HP_REGENE_RATE $PLAYER_AUTO_HP_REGENE_RATE_IN_SLEEP 
        $PAL_STOMACH_DECREACE_RATE $PAL_STAMINA_DECREACE_RATE 
        $PAL_AUTO_HP_REGENE_RATE $PAL_AUTO_HP_REGENE_RATE_IN_SLEEP 
        $BUILD_OBJECT_HP_RATE $BUILD_OBJECT_DAMAGE_RATE 
        $BUILD_OBJECT_DETERIORATION_DAMAGE_RATE $COLLECTION_DROP_RATE 
        $COLLECTION_OBJECT_HP_RATE $COLLECTION_OBJECT_RESPAWN_SPEED_RATE 
        $ENEMY_DROP_ITEM_RATE $DEATH_PENALTY $ENABLE_PLAYER_TO_PLAYER_DAMAGE 
        $ENABLE_FRIENDLY_FIRE $ENABLE_INVADER_ENEMY $ACTIVE_UNKO 
        $ENABLE_AIM_ASSIST_PAD $ENABLE_AIM_ASSIST_KEYBOARD $DROP_ITEM_MAX_NUM 
        $DROP_ITEM_MAX_NUM_UNKO $BASE_CAMP_MAX_NUM $BASE_CAMP_WORKER_MAXNUM 
        $DROP_ITEM_ALIVE_MAX_HOURS $AUTO_RESET_GUILD_NO_ONLINE_PLAYERS 
        $AUTO_RESET_GUILD_TIME_NO_ONLINE_PLAYERS $GUILD_PLAYER_MAX_NUM 
        $BASE_CAMP_MAX_NUM_IN_GUILD $PAL_EGG_DEFAULT_HATCHING_TIME 
        $WORK_SPEED_RATE $AUTO_SAVE_SPAN $IS_MULTIPLAY $IS_PVP $HARDCORE 
        $PAL_LOST $CHARACTER_RECREATE_IN_HARDCORE 
        $CAN_PICKUP_OTHER_GUILD_DEATH_PENALTY_DROP $ENABLE_NON_LOGIN_PENALTY 
        $ENABLE_FAST_TRAVEL $IS_START_LOCATION_SELECT_BY_MAP 
        $EXIST_PLAYER_AFTER_LOGOUT $ENABLE_DEFENSE_OTHER_GUILD_PLAYER 
        $INVISBIBLE_OTHER_GUILD_BASE_CAMP_AREA_FX $BUILD_AREA_LIMIT 
        $ITEM_WEIGHT_RATE $COOP_PLAYER_MAX_NUM $MAX_PLAYERS $SERVER_NAME 
        $SERVER_DESCRIPTION $ADMIN_PASSWORD $SERVER_PASSWORD $PUBLIC_PORT 
        $PUBLIC_IP $RCON_ENABLED $RCON_PORT $REGION $USEAUTH $BAN_LIST_URL 
        $RESTAPI_ENABLED $RESTAPI_PORT $SHOW_PLAYER_LIST 
        $CHAT_POST_LIMIT_PER_MINUTE $CROSSPLAY_PLATFORMS $ENABLE_WORLD_BACKUP 
        $LOG_FORMAT_TYPE $SUPPLY_DROP_SPAN $ENABLE_PREDATOR_BOSS_PAL 
        $MAX_BUILDING_LIMIT_NUM $SERVER_REPLICATE_PAWN_CULL_DISTANCE 
        $ALLOW_GLOBAL_PALBOX_EXPORT $ALLOW_GLOBAL_PALBOX_IMPORT 
        $EQUIPMENT_DURABILITY_DAMAGE_RATE $ITEM_CONTAINER_FORCE_MARK_DIRTY_INTERVAL'
    

    if ! envsubst "$ENVSUBST_SELECTORS" < "${PALWORLD_TEMPLATE_FILE}" > "${GAME_SETTINGS_FILE}"; then
        ee "Failed to generate ${GAME_SETTINGS_FILE}"
        return 1
    fi
    es ">>> Finished setting up PalWorldSettings.ini"
}

function setup_configs() {
    if [[ -n ${SERVER_SETTINGS_MODE} ]] && [[ ${SERVER_SETTINGS_MODE} == "auto" ]]; then
        ew ">>> SERVER_SETTINGS_MODE is set to '${SERVER_SETTINGS_MODE}', using environment variables to configure the server"
        setup_engine_ini
        setup_palworld_settings_ini
    elif [[ -n ${SERVER_SETTINGS_MODE} ]] && [[ ${SERVER_SETTINGS_MODE} == "rcononly" ]]; then
        ew ">>> SERVER_SETTINGS_MODE 'rcononly' is deprecated — RCON tooling has been replaced by the REST API."
        ew ">>> No settings will be applied. Switch to 'auto' or 'manual' mode."
    else
        ew ">>> SERVER_SETTINGS_MODE is set to '${SERVER_SETTINGS_MODE}', NOT using environment variables to configure the server!"
        ew ">>> ALL SETTINGS have to be done manually by the user!"
    fi
}
