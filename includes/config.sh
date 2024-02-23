# shellcheck disable=SC2148,SC1091

source /includes/colors.sh

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

function setup_palworld_settings_ini() {
    ei ">>> Setting up PalWorldSettings.ini ..."
    if [ ! -d "${GAME_CONFIG_PATH}" ]; then
        mkdir -p "${GAME_CONFIG_PATH}/"
    fi
    # Copy default-config, which comes with SteamCMD to gameserver save location
    ew "> Copying DefaultPalWorldSettings.ini to ${GAME_SETTINGS_FILE}"
    cp "${GAME_ROOT}/DefaultPalWorldSettings.ini" "${GAME_SETTINGS_FILE}"


    if [[ -n ${DIFFICULTY+x} ]]; then
        e "> Setting Difficulty to '$DIFFICULTY'"
        sed -E -i "s/Difficulty=[a-zA-Z]*/Difficulty=$DIFFICULTY/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${DAYTIME_SPEEDRATE+x} ]]; then
        e "> Setting DayTimeSpeedRate to '$DAYTIME_SPEEDRATE'"
        sed -E -i "s/DayTimeSpeedRate=[+-]?([0-9]*[.])?[0-9]+/DayTimeSpeedRate=$DAYTIME_SPEEDRATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${NIGHTTIME_SPEEDRATE+x} ]]; then
        e "> Setting NightTimeSpeedRate to '$NIGHTTIME_SPEEDRATE'"
        sed -E -i "s/NightTimeSpeedRate=[+-]?([0-9]*[.])?[0-9]+/NightTimeSpeedRate=$NIGHTTIME_SPEEDRATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${EXP_RATE+x} ]]; then
        e "> Setting ExpRate to '$EXP_RATE'"
        sed -E -i "s/ExpRate=[+-]?([0-9]*[.])?[0-9]+/ExpRate=$EXP_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PAL_CAPTURE_RATE+x} ]]; then
        e "> Setting PalCaptureRate to '$PAL_CAPTURE_RATE'"
        sed -E -i "s/PalCaptureRate=[+-]?([0-9]*[.])?[0-9]+/PalCaptureRate=$PAL_CAPTURE_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PAL_SPAWN_NUM_RATE+x} ]]; then
        e "> Setting PalSpawnNumRate to '$PAL_SPAWN_NUM_RATE'"
        sed -E -i "s/PalSpawnNumRate=[+-]?([0-9]*[.])?[0-9]+/PalSpawnNumRate=$PAL_SPAWN_NUM_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PAL_DAMAGE_RATE_ATTACK+x} ]]; then
        e "> Setting PalDamageRateAttack to '$PAL_DAMAGE_RATE_ATTACK'"
        sed -E -i "s/PalDamageRateAttack=[+-]?([0-9]*[.])?[0-9]+/PalDamageRateAttack=$PAL_DAMAGE_RATE_ATTACK/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PAL_DAMAGE_RATE_DEFENSE+x} ]]; then
        e "> Setting PalDamageRateDefense to '$PAL_DAMAGE_RATE_DEFENSE'"
        sed -E -i "s/PalDamageRateDefense=[+-]?([0-9]*[.])?[0-9]+/PalDamageRateDefense=$PAL_DAMAGE_RATE_DEFENSE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PLAYER_DAMAGE_RATE_ATTACK+x} ]]; then
        e "> Setting PlayerDamageRateAttack to '$PLAYER_DAMAGE_RATE_ATTACK'"
        sed -E -i "s/PlayerDamageRateAttack=[+-]?([0-9]*[.])?[0-9]+/PlayerDamageRateAttack=$PLAYER_DAMAGE_RATE_ATTACK/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PLAYER_DAMAGE_RATE_DEFENSE+x} ]]; then
        e "> Setting PlayerDamageRateDefense to '$PLAYER_DAMAGE_RATE_DEFENSE'"
        sed -E -i "s/PlayerDamageRateDefense=[+-]?([0-9]*[.])?[0-9]+/PlayerDamageRateDefense=$PLAYER_DAMAGE_RATE_DEFENSE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PLAYER_STOMACH_DECREASE_RATE+x} ]]; then
        e "> Setting PlayerStomachDecreaceRate to '$PLAYER_STOMACH_DECREASE_RATE'"
        sed -E -i "s/PlayerStomachDecreaceRate=[+-]?([0-9]*[.])?[0-9]+/PlayerStomachDecreaceRate=$PLAYER_STOMACH_DECREASE_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PLAYER_STAMINA_DECREACE_RATE+x} ]]; then
        e "> Setting PlayerStaminaDecreaceRate to '$PLAYER_STAMINA_DECREACE_RATE'"
        sed -E -i "s/PlayerStaminaDecreaceRate=[+-]?([0-9]*[.])?[0-9]+/PlayerStaminaDecreaceRate=$PLAYER_STAMINA_DECREACE_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PLAYER_AUTO_HP_REGENE_RATE+x} ]]; then
        e "> Setting PlayerAutoHPRegeneRate to '$PLAYER_AUTO_HP_REGENE_RATE'"
        sed -E -i "s/PlayerAutoHPRegeneRate=[+-]?([0-9]*[.])?[0-9]+/PlayerAutoHPRegeneRate=$PLAYER_AUTO_HP_REGENE_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PLAYER_AUTO_HP_REGENE_RATE_IN_SLEEP+x} ]]; then
        e "> Setting PlayerAutoHpRegeneRateInSleep to '$PLAYER_AUTO_HP_REGENE_RATE_IN_SLEEP'"
        sed -E -i "s/PlayerAutoHpRegeneRateInSleep=[+-]?([0-9]*[.])?[0-9]+/PlayerAutoHpRegeneRateInSleep=$PLAYER_AUTO_HP_REGENE_RATE_IN_SLEEP/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PAL_STOMACH_DECREACE_RATE+x} ]]; then
        e "> Setting PalStomachDecreaceRate to '$PAL_STOMACH_DECREACE_RATE'"
        sed -E -i "s/PalStomachDecreaceRate=[+-]?([0-9]*[.])?[0-9]+/PalStomachDecreaceRate=$PAL_STOMACH_DECREACE_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PAL_STAMINA_DECREACE_RATE+x} ]]; then
        e "> Setting PalStaminaDecreaceRate to '$PAL_STAMINA_DECREACE_RATE'"
        sed -E -i "s/PalStaminaDecreaceRate=[+-]?([0-9]*[.])?[0-9]+/PalStaminaDecreaceRate=$PAL_STAMINA_DECREACE_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PAL_AUTO_HP_REGENE_RATE+x} ]]; then
        e "> Setting PalAutoHPRegeneRate to '$PAL_AUTO_HP_REGENE_RATE'"
        sed -E -i "s/PalAutoHPRegeneRate=[+-]?([0-9]*[.])?[0-9]+/PalAutoHPRegeneRate=$PAL_AUTO_HP_REGENE_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PAL_AUTO_HP_REGENE_RATE_IN_SLEEP+x} ]]; then
        e "> Setting PalAutoHpRegeneRateInSleep to '$PAL_AUTO_HP_REGENE_RATE_IN_SLEEP'"
        sed -E -i "s/PalAutoHpRegeneRateInSleep=[+-]?([0-9]*[.])?[0-9]+/PalAutoHpRegeneRateInSleep=$PAL_AUTO_HP_REGENE_RATE_IN_SLEEP/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${BUILD_OBJECT_DAMAGE_RATE+x} ]]; then
        e "> Setting BuildObjectDamageRate to '$BUILD_OBJECT_DAMAGE_RATE'"
        sed -E -i "s/BuildObjectDamageRate=[+-]?([0-9]*[.])?[0-9]+/BuildObjectDamageRate=$BUILD_OBJECT_DAMAGE_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${BUILD_OBJECT_DETERIORATION_DAMAGE_RATE+x} ]]; then
        e "> Setting BuildObjectDeteriorationDamageRate to '$BUILD_OBJECT_DETERIORATION_DAMAGE_RATE'"
        sed -E -i "s/BuildObjectDeteriorationDamageRate=[+-]?([0-9]*[.])?[0-9]+/BuildObjectDeteriorationDamageRate=$BUILD_OBJECT_DETERIORATION_DAMAGE_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${COLLECTION_DROP_RATE+x} ]]; then
        e "> Setting CollectionDropRate to '$COLLECTION_DROP_RATE'"
        sed -E -i "s/CollectionDropRate=[+-]?([0-9]*[.])?[0-9]+/CollectionDropRate=$COLLECTION_DROP_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${COLLECTION_OBJECT_HP_RATE+x} ]]; then
        e "> Setting CollectionObjectHpRate to '$COLLECTION_OBJECT_HP_RATE'"
        sed -E -i "s/CollectionObjectHpRate=[+-]?([0-9]*[.])?[0-9]+/CollectionObjectHpRate=$COLLECTION_OBJECT_HP_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${COLLECTION_OBJECT_RESPAWN_SPEED_RATE+x} ]]; then
        e "> Setting CollectionObjectRespawnSpeedRate to '$COLLECTION_OBJECT_RESPAWN_SPEED_RATE'"
        sed -E -i "s/CollectionObjectRespawnSpeedRate=[+-]?([0-9]*[.])?[0-9]+/CollectionObjectRespawnSpeedRate=$COLLECTION_OBJECT_RESPAWN_SPEED_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${ENEMY_DROP_ITEM_RATE+x} ]]; then
        e "> Setting EnemyDropItemRate to '$ENEMY_DROP_ITEM_RATE'"
        sed -E -i "s/EnemyDropItemRate=[+-]?([0-9]*[.])?[0-9]+/EnemyDropItemRate=$ENEMY_DROP_ITEM_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${DEATH_PENALTY+x} ]]; then
        e "> Setting DeathPenalty to '$DEATH_PENALTY'"
        sed -E -i "s/DeathPenalty=[a-zA-Z]*/DeathPenalty=$DEATH_PENALTY/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${ENABLE_PLAYER_TO_PLAYER_DAMAGE+x} ]]; then
        e "> Setting bEnablePlayerToPlayerDamage to '$ENABLE_PLAYER_TO_PLAYER_DAMAGE'"
        sed -E -i "s/bEnablePlayerToPlayerDamage=[a-zA-Z]*/bEnablePlayerToPlayerDamage=$ENABLE_PLAYER_TO_PLAYER_DAMAGE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${ENABLE_FRIENDLY_FIRE+x} ]]; then
        e "> Setting bEnableFriendlyFire to '$ENABLE_FRIENDLY_FIRE'"
        sed -E -i "s/bEnableFriendlyFire=[a-zA-Z]*/bEnableFriendlyFire=$ENABLE_FRIENDLY_FIRE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${ENABLE_INVADER_ENEMY+x} ]]; then
        e "> Setting bEnableInvaderEnemy to '$ENABLE_INVADER_ENEMY'"
        sed -E -i "s/bEnableInvaderEnemy=[a-zA-Z]*/bEnableInvaderEnemy=$ENABLE_INVADER_ENEMY/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${ACTIVE_UNKO+x} ]]; then
        e "> Setting bActiveUNKO to '$ACTIVE_UNKO'"
        sed -E -i "s/bActiveUNKO=[a-zA-Z]*/bActiveUNKO=$ACTIVE_UNKO/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${ENABLE_AIM_ASSIST_PAD+x} ]]; then
        e "> Setting bEnableAimAssistPad to '$ENABLE_AIM_ASSIST_PAD'"
        sed -E -i "s/bEnableAimAssistPad=[a-zA-Z]*/bEnableAimAssistPad=$ENABLE_AIM_ASSIST_PAD/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${ENABLE_AIM_ASSIST_KEYBOARD+x} ]]; then
        e "> Setting bEnableAimAssistKeyboard to '$ENABLE_AIM_ASSIST_KEYBOARD'"
        sed -E -i "s/bEnableAimAssistKeyboard=[a-zA-Z]*/bEnableAimAssistKeyboard=$ENABLE_AIM_ASSIST_KEYBOARD/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${DROP_ITEM_MAX_NUM+x} ]]; then
        e "> Setting DropItemMaxNum to '$DROP_ITEM_MAX_NUM'"
        sed -E -i "s/DropItemMaxNum=[0-9]*/DropItemMaxNum=$DROP_ITEM_MAX_NUM/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${DROP_ITEM_MAX_NUM_UNKO+x} ]]; then
        e "> Setting DropItemMaxNum_UNKO to '$DROP_ITEM_MAX_NUM_UNKO'"
        sed -E -i "s/DropItemMaxNum_UNKO=[0-9]*/DropItemMaxNum_UNKO=$DROP_ITEM_MAX_NUM_UNKO/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${BASE_CAMP_MAX_NUM+x} ]]; then
        e "> Setting BaseCampMaxNum to '$BASE_CAMP_MAX_NUM'"
        sed -E -i "s/BaseCampMaxNum=[0-9]*/BaseCampMaxNum=$BASE_CAMP_MAX_NUM/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${BASE_CAMP_WORKER_MAXNUM+x} ]]; then
        e "> Setting BaseCampWorkerMaxNum to '$BASE_CAMP_WORKER_MAXNUM'"
        sed -E -i "s/BaseCampWorkerMaxNum=[0-9]*/BaseCampWorkerMaxNum=$BASE_CAMP_WORKER_MAXNUM/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${DROP_ITEM_ALIVE_MAX_HOURS+x} ]]; then
        e "> Setting DropItemAliveMaxHours to '$DROP_ITEM_ALIVE_MAX_HOURS'"
        sed -E -i "s/DropItemAliveMaxHours=[+-]?([0-9]*[.])?[0-9]+/DropItemAliveMaxHours=$DROP_ITEM_ALIVE_MAX_HOURS/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${AUTO_RESET_GUILD_NO_ONLINE_PLAYERS+x} ]]; then
        e "> Setting bAutoResetGuildNoOnlinePlayers to '$AUTO_RESET_GUILD_NO_ONLINE_PLAYERS'"
        sed -E -i "s/bAutoResetGuildNoOnlinePlayers=[a-zA-Z]*/bAutoResetGuildNoOnlinePlayers=$AUTO_RESET_GUILD_NO_ONLINE_PLAYERS/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${AUTO_RESET_GUILD_TIME_NO_ONLINE_PLAYERS+x} ]]; then
        e "> Setting AutoResetGuildTimeNoOnlinePlayers to '$AUTO_RESET_GUILD_TIME_NO_ONLINE_PLAYERS'"
        sed -E -i "s/AutoResetGuildTimeNoOnlinePlayers=[+-]?([0-9]*[.])?[0-9]+/AutoResetGuildTimeNoOnlinePlayers=$AUTO_RESET_GUILD_TIME_NO_ONLINE_PLAYERS/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${GUILD_PLAYER_MAX_NUM+x} ]]; then
        e "> Setting GuildPlayerMaxNum to '$GUILD_PLAYER_MAX_NUM'"
        sed -E -i "s/GuildPlayerMaxNum=[0-9]*/GuildPlayerMaxNum=$GUILD_PLAYER_MAX_NUM/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PAL_EGG_DEFAULT_HATCHING_TIME+x} ]]; then
        e "> Setting PalEggDefaultHatchingTime to '$PAL_EGG_DEFAULT_HATCHING_TIME'"
        sed -E -i "s/PalEggDefaultHatchingTime=[+-]?([0-9]*[.])?[0-9]+/PalEggDefaultHatchingTime=$PAL_EGG_DEFAULT_HATCHING_TIME/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${WORK_SPEED_RATE+x} ]]; then
        e "> Setting WorkSpeedRate to '$WORK_SPEED_RATE'"
        sed -E -i "s/WorkSpeedRate=[+-]?([0-9]*[.])?[0-9]+/WorkSpeedRate=$WORK_SPEED_RATE/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${IS_MULTIPLAY+x} ]]; then
        e "> Setting bIsMultiplay to '$IS_MULTIPLAY'"
        sed -E -i "s/bIsMultiplay=[a-zA-Z]*/bIsMultiplay=$IS_MULTIPLAY/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${IS_PVP+x} ]]; then
        e "> Setting bIsPvP to $IS_PVP"
        sed -E -i "s/bIsPvP=[a-zA-Z]*/bIsPvP=$IS_PVP/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${CAN_PICKUP_OTHER_GUILD_DEATH_PENALTY_DROP+x} ]]; then
        e "> Setting bCanPickupOtherGuildDeathPenaltyDrop to '$CAN_PICKUP_OTHER_GUILD_DEATH_PENALTY_DROP'"
        sed -E -i "s/bCanPickupOtherGuildDeathPenaltyDrop=[a-zA-Z]*/bCanPickupOtherGuildDeathPenaltyDrop=$CAN_PICKUP_OTHER_GUILD_DEATH_PENALTY_DROP/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${ENABLE_NON_LOGIN_PENALTY+x} ]]; then
        e "> Setting bEnableNonLoginPenalty to '$ENABLE_NON_LOGIN_PENALTY'"
        sed -E -i "s/bEnableNonLoginPenalty=[a-zA-Z]*/bEnableNonLoginPenalty=$ENABLE_NON_LOGIN_PENALTY/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${ENABLE_FAST_TRAVEL+x} ]]; then
        e "> Setting bEnableFastTravel to '$ENABLE_FAST_TRAVEL'"
        sed -E -i "s/bEnableFastTravel=[a-zA-Z]*/bEnableFastTravel=$ENABLE_FAST_TRAVEL/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${IS_START_LOCATION_SELECT_BY_MAP+x} ]]; then
        e "> Setting bIsStartLocationSelectByMap to '$IS_START_LOCATION_SELECT_BY_MAP'"
        sed -E -i "s/bIsStartLocationSelectByMap=[a-zA-Z]*/bIsStartLocationSelectByMap=$IS_START_LOCATION_SELECT_BY_MAP/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${EXIST_PLAYER_AFTER_LOGOUT+x} ]]; then
        e "> Setting bExistPlayerAfterLogout to '$EXIST_PLAYER_AFTER_LOGOUT'"
        sed -E -i "s/bExistPlayerAfterLogout=[a-zA-Z]*/bExistPlayerAfterLogout=$EXIST_PLAYER_AFTER_LOGOUT/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${ENABLE_DEFENSE_OTHER_GUILD_PLAYER+x} ]]; then
        e "> Setting bEnableDefenseOtherGuildPlayer to '$ENABLE_DEFENSE_OTHER_GUILD_PLAYER'"
        sed -E -i "s/bEnableDefenseOtherGuildPlayer=[a-zA-Z]*/bEnableDefenseOtherGuildPlayer=$ENABLE_DEFENSE_OTHER_GUILD_PLAYER/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${COOP_PLAYER_MAX_NUM+x} ]]; then
        e "> Setting CoopPlayerMaxNum to '$COOP_PLAYER_MAX_NUM'"
        sed -E -i "s/CoopPlayerMaxNum=[0-9]*/CoopPlayerMaxNum=$COOP_PLAYER_MAX_NUM/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${MAX_PLAYERS+x} ]]; then
        e "> Setting max-players to '$MAX_PLAYERS'"
        sed -E -i "s/ServerPlayerMaxNum=[0-9]*/ServerPlayerMaxNum=$MAX_PLAYERS/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${SERVER_NAME+x} ]]; then
        e "> Setting server name to '$SERVER_NAME'"
        sed -E -i "s/ServerName=\"[^\"]*\"/ServerName=\"$SERVER_NAME\"/" "$GAME_SETTINGS_FILE"
        if [[ "$SERVER_NAME" == *"###RANDOM###"* ]]; then
            RAND_VALUE=$RANDOM
            e "> Found standard template, using random numbers in server name"
            sed -E -i -e "s/###RANDOM###/$RAND_VALUE/g" "$GAME_SETTINGS_FILE"
            e "> Server name is now 'jammsen-docker-generated-$RAND_VALUE'"
        fi
    fi
    if [[ -n ${SERVER_DESCRIPTION+x} ]]; then
        e "> Setting server description to '$SERVER_DESCRIPTION'"
        sed -E -i "s/ServerDescription=\"[^\"]*\"/ServerDescription=\"$SERVER_DESCRIPTION\"/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${ADMIN_PASSWORD+x} ]]; then
        e "> Setting server admin password to [REDACTED]"
        sed -E -i "s/AdminPassword=\"[^\"]*\"/AdminPassword=\"$ADMIN_PASSWORD\"/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${SERVER_PASSWORD+x} ]]; then
        e "> Setting server password to [REDACTED]"
        sed -E -i "s/ServerPassword=\"[^\"]*\"/ServerPassword=\"$SERVER_PASSWORD\"/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PUBLIC_PORT+x} ]]; then
        e "> Setting public port to '$PUBLIC_PORT'"
        sed -E -i "s/PublicPort=[0-9]*/PublicPort=$PUBLIC_PORT/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${PUBLIC_IP+x} ]]; then
        e "> Setting public ip to '$PUBLIC_IP'"
        sed -E -i "s/PublicIP=\"[^\"]*\"/PublicIP=\"$PUBLIC_IP\"/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${RCON_ENABLED+x} ]]; then
        e "> Setting rcon-enabled to '$RCON_ENABLED'"
        sed -E -i "s/RCONEnabled=[a-zA-Z]*/RCONEnabled=$RCON_ENABLED/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${RCON_PORT+x} ]]; then
        e "> Setting RCONPort to '$RCON_PORT'"
        sed -E -i "s/RCONPort=[0-9]*/RCONPort=$RCON_PORT/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${REGION+x} ]]; then
        e "> Setting Region to '$REGION'"
        sed -E -i "s/Region=\"[^\"]*\"/Region=\"$REGION\"/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${USEAUTH+x} ]]; then
        e "> Setting bUseAuth to '$USEAUTH'"
        sed -E -i "s/bUseAuth=[a-zA-Z]*/bUseAuth=$USEAUTH/" "$GAME_SETTINGS_FILE"
    fi
    if [[ -n ${BAN_LIST_URL+x} ]]; then
        e "> Setting BanListURL to '$BAN_LIST_URL'"
        sed -E -i "s~BanListURL=\"[^\"]*\"~BanListURL=\"$BAN_LIST_URL\"~" "$GAME_SETTINGS_FILE"
    fi
    es ">>> Finished setting up PalWorldSettings.ini"
}

function setup_rcon_yaml () {
    if [[ -n ${RCON_ENABLED+x} ]] && [ "$RCON_ENABLED" == "true" ] ; then
        ei ">>> RCON is enabled - Setting up rcon.yaml ..."
        if [[ -n ${RCON_PORT+x} ]]; then
            sed -i "s/###RCON_PORT###/$RCON_PORT/" "$RCON_CONFIG_FILE"
        else
            ee "> RCON_PORT is not set, please set it for RCON functionality to work!"
        fi
        if [[ -n ${ADMIN_PASSWORD+x} ]]; then
            sed -i "s/###ADMIN_PASSWORD###/$ADMIN_PASSWORD/" "$RCON_CONFIG_FILE"
        else
            ee "> RCON_PORT is not set, please set it for RCON functionality to work!"
        fi
        es ">>> Finished setting up 'rcon.yaml' config file"
    else
        ei ">>> RCON is disabled, skipping 'rcon.yaml' config file!"
    fi
}

function setup_configs() {
    if [[ -n ${SERVER_SETTINGS_MODE} ]] && [[ ${SERVER_SETTINGS_MODE} == "auto" ]]; then
        ew ">>> SERVER_SETTINGS_MODE is set to '${SERVER_SETTINGS_MODE}', using environment variables to configure the server"
        setup_engine_ini
        setup_palworld_settings_ini
        setup_rcon_yaml
    elif [[ -n ${SERVER_SETTINGS_MODE} ]] && [[ ${SERVER_SETTINGS_MODE} == "rcononly" ]]; then
        ew ">>> SERVER_SETTINGS_MODE is set to '${SERVER_SETTINGS_MODE}', using environment variables to ONLY configure RCON!"
        ew ">>> ALL SETTINGS excluding setup of rcon.yaml has to be done manually by the user!"
        setup_rcon_yaml
    else
        ew ">>> SERVER_SETTINGS_MODE is set to '${SERVER_SETTINGS_MODE}', NOT using environment variables to configure the server!"
        ew ">>> ALL SETTINGS including setup of rcon.yaml has to be done manually by the user!"
    fi
}
