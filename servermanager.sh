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

    if [[ ! -z ${DIFFICULTY+x} ]]; then
        echo "Setting Difficulty to $DIFFICULTY"
        sed -i "s/Difficulty=[a-zA-Z]*/Difficulty=$DIFFICULTY/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${DAYTIME_SPEEDRATE+x} ]]; then
        echo "Setting DayTimeSpeedRate to $DAYTIME_SPEEDRATE"
        sed -i "s/DayTimeSpeedRate=[+-]?([0-9]*[.])?[0-9]+/DayTimeSpeedRate=$DAYTIME_SPEEDRATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${NIGHTTIME_SPEEDRATE+x} ]]; then
        echo "Setting NightTimeSpeedRate to $NIGHTTIME_SPEEDRATE"
        sed -i "s/NightTimeSpeedRate=[+-]?([0-9]*[.])?[0-9]+/NightTimeSpeedRate=$NIGHTTIME_SPEEDRATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${EXP_RATE+x} ]]; then
        echo "Setting ExpRate to $EXP_RATE"
        sed -i "s/ExpRate=[+-]?([0-9]*[.])?[0-9]+/ExpRate=$EXP_RATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PAL_CAPTURE_RATE+x} ]]; then
        echo "Setting PalCaptureRate to $PAL_CAPTURE_RATE"
        sed -i "s/PalCaptureRate=[+-]?([0-9]*[.])?[0-9]+/PalCaptureRate=$PAL_CAPTURE_RATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PAL_SPAWN_NUM_RATE+x} ]]; then
        echo "Setting PalSpawnNumRate to $PAL_SPAWN_NUM_RATE"
        sed -i "s/PalSpawnNumRate=[+-]?([0-9]*[.])?[0-9]+/PalSpawnNumRate=$PAL_SPAWN_NUM_RATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PAL_DAMAGE_RATE_ATTACK+x} ]]; then
        echo "Setting PalDamageRateAttack to $PAL_DAMAGE_RATE_ATTACK"
        sed -i "s/PalDamageRateAttack=[+-]?([0-9]*[.])?[0-9]+/PalDamageRateAttack=$PAL_DAMAGE_RATE_ATTACK/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PAL_DAMAGE_RATE_DEFENSE+x} ]]; then
        echo "Setting PalDamageRateDefense to $PAL_DAMAGE_RATE_DEFENSE"
        sed -i "s/PalDamageRateDefense=[+-]?([0-9]*[.])?[0-9]+/PalDamageRateDefense=$PAL_DAMAGE_RATE_DEFENSE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PLAYER_DAMAGE_RATE_ATTACK+x} ]]; then
        echo "Setting PlayerDamageRateAttack to $PLAYER_DAMAGE_RATE_ATTACK"
        sed -i "s/PlayerDamageRateAttack=[+-]?([0-9]*[.])?[0-9]+/PlayerDamageRateAttack=$PLAYER_DAMAGE_RATE_ATTACK/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PLAYER_DAMAGE_RATE_DEFENSE+x} ]]; then
        echo "Setting PlayerDamageRateDefense to $PLAYER_DAMAGE_RATE_DEFENSE"
        sed -i "s/PlayerDamageRateDefense=[+-]?([0-9]*[.])?[0-9]+/PlayerDamageRateDefense=$PLAYER_DAMAGE_RATE_DEFENSE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${Player_Stomach_Decreace_Rate+x} ]]; then
        echo "Setting PlayerStomachDecreaceRate to $Player_Stomach_Decreace_Rate"
        sed -i "s/PlayerStomachDecreaceRate=[+-]?([0-9]*[.])?[0-9]+/PlayerStomachDecreaceRate=$Player_Stomach_Decreace_Rate/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PLAYER_STAMINA_DECREACE_RATE+x} ]]; then
        echo "Setting PlayerStaminaDecreaceRate to $PLAYER_STAMINA_DECREACE_RATE"
        sed -i "s/PlayerStaminaDecreaceRate=[+-]?([0-9]*[.])?[0-9]+/PlayerStaminaDecreaceRate=$PLAYER_STAMINA_DECREACE_RATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PLAYER_AUTO_HP_REGENE_RATE+x} ]]; then
        echo "Setting PlayerAutoHPRegeneRate to $PLAYER_AUTO_HP_REGENE_RATE"
        sed -i "s/PlayerAutoHPRegeneRate=[+-]?([0-9]*[.])?[0-9]+/PlayerAutoHPRegeneRate=$PLAYER_AUTO_HP_REGENE_RATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PLAYER_AUTO_HP_REGENE_RATE_IN_SLEEP+x} ]]; then
        echo "Setting PlayerAutoHpRegeneRateInSleep to $PLAYER_AUTO_HP_REGENE_RATE_IN_SLEEP"
        sed -i "s/PlayerAutoHpRegeneRateInSleep=[+-]?([0-9]*[.])?[0-9]+/PlayerAutoHpRegeneRateInSleep=$PLAYER_AUTO_HP_REGENE_RATE_IN_SLEEP/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PAL_STOMACH_DECREACE_RATE+x} ]]; then
        echo "Setting PalStomachDecreaceRate to $PAL_STOMACH_DECREACE_RATE"
        sed -i "s/PalStomachDecreaceRate=[+-]?([0-9]*[.])?[0-9]+/PalStomachDecreaceRate=$PAL_STOMACH_DECREACE_RATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PAL_STAMINA_DECREACE_RATE+x} ]]; then
        echo "Setting PalStaminaDecreaceRate to $X"
        sed -i "s/PalStaminaDecreaceRate=[+-]?([0-9]*[.])?[0-9]+/PalStaminaDecreaceRate=$PAL_STAMINA_DECREACE_RATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PAL_AUTO_HP_REGENE_RATE+x} ]]; then
        echo "Setting PalAutoHPRegeneRate to $PAL_AUTO_HP_REGENE_RATE"
        sed -i "s/PalAutoHPRegeneRate=[+-]?([0-9]*[.])?[0-9]+/PalAutoHPRegeneRate=$PAL_AUTO_HP_REGENE_RATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PAL_AUTO_HP_REGENE_RATE_IN_SLEEP+x} ]]; then
        echo "Setting PalAutoHpRegeneRateInSleep to $PAL_AUTO_HP_REGENE_RATE_IN_SLEEP"
        sed -i "s/PalAutoHpRegeneRateInSleep=[+-]?([0-9]*[.])?[0-9]+/PalAutoHpRegeneRateInSleep=$PAL_AUTO_HP_REGENE_RATE_IN_SLEEP/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${BUILD_OBJECT_DAMAGE_RATE+x} ]]; then
        echo "Setting BuildObjectDamageRate to $BUILD_OBJECT_DAMAGE_RATE"
        sed -i "s/BuildObjectDamageRate=[+-]?([0-9]*[.])?[0-9]+/BuildObjectDamageRate=$BUILD_OBJECT_DAMAGE_RATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${BUILD_OBJECT_DETERIORATION_DAMAGE_RATE+x} ]]; then
        echo "Setting PalAutoHpRegeneRateInSleep to $BUILD_OBJECT_DETERIORATION_DAMAGE_RATE"
        sed -i "s/PalAutoHpRegeneRateInSleep=[+-]?([0-9]*[.])?[0-9]+/PalAutoHpRegeneRateInSleep=$BUILD_OBJECT_DETERIORATION_DAMAGE_RATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${COLLECTION_DROP_RATE+x} ]]; then
        echo "Setting CollectionDropRate to $COLLECTION_DROP_RATE"
        sed -i "s/CollectionDropRate=[+-]?([0-9]*[.])?[0-9]+/CollectionDropRate=$COLLECTION_DROP_RATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${COLLECTION_OBJECT_HP_RATE+x} ]]; then
        echo "Setting CollectionObjectHpRate to $COLLECTION_OBJECT_HP_RATE"
        sed -i "s/CollectionObjectHpRate=[+-]?([0-9]*[.])?[0-9]+/CollectionObjectHpRate=$COLLECTION_OBJECT_HP_RATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${COLLECTION_OBJECT_RESPAWN_SPEED_RATE+x} ]]; then
        echo "Setting CollectionObjectRespawnSpeedRate to $COLLECTION_OBJECT_RESPAWN_SPEED_RATE"
        sed -i "s/CollectionObjectRespawnSpeedRate=[+-]?([0-9]*[.])?[0-9]+/CollectionObjectRespawnSpeedRate=$COLLECTION_OBJECT_RESPAWN_SPEED_RATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${ENEMY_DROP_ITEM_RATE+x} ]]; then
        echo "Setting EnemyDropItemRate to $ENEMY_DROP_ITEM_RATE"
        sed -i "s/EnemyDropItemRate=[+-]?([0-9]*[.])?[0-9]+/EnemyDropItemRate=$ENEMY_DROP_ITEM_RATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${DEATH_PENALTY+x} ]]; then
        echo "Setting DeathPenalty to $DEATH_PENALTY"
        sed -i "s/DeathPenalty=[a-zA-Z]*/DeathPenalty=$DEATH_PENALTY/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${ENABLE_PLAYER_TO_PLAYER_DAMAGE+x} ]]; then
        echo "Setting bEnablePlayerToPlayerDamage to $ENABLE_PLAYER_TO_PLAYER_DAMAGE"
        sed -i "s/bEnablePlayerToPlayerDamage=[a-zA-Z]*/bEnablePlayerToPlayerDamage=$ENABLE_PLAYER_TO_PLAYER_DAMAGE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${ENABLE_FRIENDLY_FIRE+x} ]]; then
        echo "Setting bEnableFriendlyFire to $ENABLE_FRIENDLY_FIRE"
        sed -i "s/bEnableFriendlyFire=[a-zA-Z]*/bEnableFriendlyFire=$ENABLE_FRIENDLY_FIRE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${ENABLE_INVADER_ENEMY+x} ]]; then
        echo "Setting bEnableInvaderEnemy to $ENABLE_INVADER_ENEMY"
        sed -i "s/bEnableInvaderEnemy=[a-zA-Z]*/bEnableInvaderEnemy=$ENABLE_INVADER_ENEMY/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${ACTIVE_UNKO+x} ]]; then
        echo "Setting bActiveUNKO to $ACTIVE_UNKO"
        sed -i "s/bActiveUNKO=[a-zA-Z]*/bActiveUNKO=$ACTIVE_UNKO/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${ENABLE_AIM_ASSIST_PAD+x} ]]; then
        echo "Setting bEnableAimAssistPad to $ENABLE_AIM_ASSIST_PAD"
        sed -i "s/bEnableAimAssistPad=[a-zA-Z]*/bEnableAimAssistPad=$ENABLE_AIM_ASSIST_PAD/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${ENABLE_AIM_ASSIST_KEYBOARD+x} ]]; then
        echo "Setting bEnableAimAssistKeyboard to $ENABLE_AIM_ASSIST_KEYBOARD"
        sed -i "s/bEnableAimAssistKeyboard=[a-zA-Z]*/bEnableAimAssistKeyboard=$ENABLE_AIM_ASSIST_KEYBOARD/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${DROP_ITEM_MAX_NUM+x} ]]; then
        echo "Setting DropItemMaxNum to $DROP_ITEM_MAX_NUM"
        sed -i "s/DropItemMaxNum=[0-9]*/DropItemMaxNum=$DROP_ITEM_MAX_NUM/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${DROP_ITEM_MAX_NUM_UNKO+x} ]]; then
        echo "Setting DropItemMaxNum_UNKO to $DROP_ITEM_MAX_NUM_UNKO"
        sed -i "s/DropItemMaxNum_UNKO=[0-9]*/DropItemMaxNum_UNKO=$DROP_ITEM_MAX_NUM_UNKO/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${BASE_CAMP_MAX_NUM+x} ]]; then
        echo "Setting BaseCampMaxNum to $BASE_CAMP_MAX_NUM"
        sed -i "s/BaseCampMaxNum=[0-9]*/BaseCampMaxNum=$BASE_CAMP_MAX_NUM/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${BASE_CAMP_WORKER_MAXNUM+x} ]]; then
        echo "Setting BaseCampWorkerMaxNum to $BASE_CAMP_WORKER_MAXNUM"
        sed -i "s/BaseCampWorkerMaxNum=[0-9]*/BaseCampWorkerMaxNum=$BASE_CAMP_WORKER_MAXNUM/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${DROP_ITEM_ALIVE_MAX_HOURS+x} ]]; then
        echo "Setting DropItemAliveMaxHours to $DROP_ITEM_ALIVE_MAX_HOURS"
        sed -i "s/DropItemAliveMaxHours=[+-]?([0-9]*[.])?[0-9]+/DropItemAliveMaxHours=$DROP_ITEM_ALIVE_MAX_HOURS/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${AUTO_RESET_GUILD_NO_ONLINE_PLAYERS+x} ]]; then
        echo "Setting bAutoResetGuildNoOnlinePlayers to $AUTO_RESET_GUILD_NO_ONLINE_PLAYERS"
        sed -i "s/bAutoResetGuildNoOnlinePlayers=[a-zA-Z]*/bAutoResetGuildNoOnlinePlayers=$AUTO_RESET_GUILD_NO_ONLINE_PLAYERS/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${AUTO_RESET_GUILD_TIME_NO_ONLINE_PLAYERS+x} ]]; then
        echo "Setting AutoResetGuildTimeNoOnlinePlayers to $AUTO_RESET_GUILD_TIME_NO_ONLINE_PLAYERS"
        sed -i "s/AutoResetGuildTimeNoOnlinePlayers=[+-]?([0-9]*[.])?[0-9]+/AutoResetGuildTimeNoOnlinePlayers=$AUTO_RESET_GUILD_TIME_NO_ONLINE_PLAYERS/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${GUILD_PLAYER_MAX_NUM+x} ]]; then
        echo "Setting GuildPlayerMaxNum to $GUILD_PLAYER_MAX_NUM"
        sed -i "s/GuildPlayerMaxNum=[0-9]*/GuildPlayerMaxNum=$GUILD_PLAYER_MAX_NUM/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PAL_EGG_DEFAULT_HATCHING_TIME+x} ]]; then
        echo "Setting PalEggDefaultHatchingTime to $PAL_EGG_DEFAULT_HATCHING_TIME"
        sed -i "s/PalEggDefaultHatchingTime=[+-]?([0-9]*[.])?[0-9]+/PalEggDefaultHatchingTime=$PAL_EGG_DEFAULT_HATCHING_TIME/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${WORK_SPEED_RATE+x} ]]; then
        echo "Setting WorkSpeedRate to $WORK_SPEED_RATE"
        sed -i "s/WorkSpeedRate=[+-]?([0-9]*[.])?[0-9]+/WorkSpeedRate=$WORK_SPEED_RATE/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${IS_MULTIPLAY+x} ]]; then
        echo "Setting bIsMultiplay to $IS_MULTIPLAY"
        sed -i "s/bIsMultiplay=[a-zA-Z]*/bIsMultiplay=$IS_MULTIPLAY/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${IS_PVP+x} ]]; then
        echo "Setting bIsPvP to $IS_PVP"
        sed -i "s/bIsPvP=[a-zA-Z]*/bIsPvP=$IS_PVP/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${CAN_PICKUP_OTHER_GUILD_DEATH_PENALTY_DROP+x} ]]; then
        echo "Setting bCanPickupOtherGuildDeathPenaltyDrop to $CAN_PICKUP_OTHER_GUILD_DEATH_PENALTY_DROP"
        sed -i "s/bCanPickupOtherGuildDeathPenaltyDrop=[a-zA-Z]*/bCanPickupOtherGuildDeathPenaltyDrop=$CAN_PICKUP_OTHER_GUILD_DEATH_PENALTY_DROP/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${ENABLE_NON_LOGIN_PENALTY+x} ]]; then
        echo "Setting bEnableNonLoginPenalty to $ENABLE_NON_LOGIN_PENALTY"
        sed -i "s/bEnableNonLoginPenalty=[a-zA-Z]*/bEnableNonLoginPenalty=$ENABLE_NON_LOGIN_PENALTY/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${ENABLE_FAST_TRAVEL+x} ]]; then
        echo "Setting bEnableFastTravel to $ENABLE_FAST_TRAVEL"
        sed -i "s/bEnableFastTravel=[a-zA-Z]*/bEnableFastTravel=$ENABLE_FAST_TRAVEL/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${IS_START_LOCATION_SELECT_BY_MAP+x} ]]; then
        echo "Setting bIsStartLocationSelectByMap to $IS_START_LOCATION_SELECT_BY_MAP"
        sed -i "s/bIsStartLocationSelectByMap=[a-zA-Z]*/bIsStartLocationSelectByMap=$IS_START_LOCATION_SELECT_BY_MAP/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${EXIST_PLAYER_AFTER_LOGOUT+x} ]]; then
        echo "Setting bExistPlayerAfterLogout to $EXIST_PLAYER_AFTER_LOGOUT"
        sed -i "s/bExistPlayerAfterLogout=[a-zA-Z]*/bExistPlayerAfterLogout=$EXIST_PLAYER_AFTER_LOGOUT/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${ENABLE_DEFENSE_OTHER_GUILD_PLAYER+x} ]]; then
        echo "Setting bEnableDefenseOtherGuildPlayer to $ENABLE_DEFENSE_OTHER_GUILD_PLAYER"
        sed -i "s/bEnableDefenseOtherGuildPlayer=[a-zA-Z]*/bEnableDefenseOtherGuildPlayer=$ENABLE_DEFENSE_OTHER_GUILD_PLAYER/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${COOP_PLAYER_MAX_NUM+x} ]]; then
        echo "Setting CoopPlayerMaxNum to $COOP_PLAYER_MAX_NUM"
        sed -i "s/CoopPlayerMaxNum=[+-]?([0-9]*[.])?[0-9]+/CoopPlayerMaxNum=$COOP_PLAYER_MAX_NUM/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${MAX_PLAYERS+x} ]]; then
        echo "Setting max-players to $MAX_PLAYERS"
        sed -i "s/ServerPlayerMaxNum=[0-9]*/ServerPlayerMaxNum=$MAX_PLAYERS/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
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
    if [[ ! -z ${ADMIN_PASSWORD+x} ]]; then
        echo "Setting server admin password to $ADMIN_PASSWORD"
        sed -i "s/AdminPassword=\"[^\"]*\"/AdminPassword=\"$ADMIN_PASSWORD\"/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${SERVER_PASSWORD+x} ]]; then
        echo "Setting server password to $SERVER_PASSWORD"
        sed -i "s/ServerPassword=\"[^\"]*\"/ServerPassword=\"$SERVER_PASSWORD\"/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${TS_SERVER_PASSWORD+x} ]]; then
        echo "Setting tSServerPassword to $TS_SERVER_PASSWORD"
        sed -i "s/tSServerPassword=\"[^\"]*\"/tSServerPassword=\"$TS_SERVER_PASSWORD\"/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${GX_SERVER_PASSWORD+x} ]]; then
        echo "Setting GXServerPassword to $GX_SERVER_PASSWORD"
        sed -i "s/GXServerPassword=\"[^\"]*\"/GXServerPassword=\"$GX_SERVER_PASSWORD\"/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PUBLIC_PORT+x} ]]; then
        echo "Setting public port to $PUBLIC_PORT"
        sed -i "s/PublicPort=[0-9]*/PublicPort=$PUBLIC_PORT/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${PUBLIC_IP+x} ]]; then
        echo "Setting public ip to $PUBLIC_IP"
        sed -i "s/PublicIP=\"[^\"]*\"/PublicIP=\"$PUBLIC_IP\"/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${RCON_ENABLED+x} ]]; then
        echo "Setting rcon-enabled to $RCON_ENABLED"
        sed -i "s/RCONEnabled=[a-zA-Z]*/RCONEnabled=$RCON_ENABLED/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${RCON_PORT+x} ]]; then
        echo "Setting RCONPort to $RCON_PORT"
        sed -i "s/RCONPort=[0-9]*/RCONPort=$RCON_PORT/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${REGION+x} ]]; then
        echo "Setting Region to $REGION"
        sed -i "s/Region=[a-zA-Z]*/Region=$REGION/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${USEAUTH+x} ]]; then
        echo "Setting bUseAuth to $USEAUTH"
        sed -i "s/bUseAuth=[a-zA-Z]*/bUseAuth=$USEAUTH/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
    fi
    if [[ ! -z ${BAN_LIST_URL+x} ]]; then
        echo "Setting BanListURL to $BAN_LIST_URL"
        sed -i "s/BanListURL=https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)/BanListURL=$BAN_LIST_URL/" ${GAME_PATH}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini
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
    if [[ -n $BACKUP_ENABLED ]] && [[ $BACKUP_ENABLED == "true" ]]; then
        # Preparing the cronlist file
        echo "$BACKUP_CRON_EXPRESSION /backupmanager.sh" >> cronlist
        # Making sure supercronic is enabled and the cronfile is loaded
        /usr/local/bin/supercronic cronlist &
    fi
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
