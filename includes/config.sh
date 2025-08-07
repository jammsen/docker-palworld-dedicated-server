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
        mkdir -p "${GAME_CONFIG_PATH}/"
    fi
    # Copy default-config, which comes with SteamCMD to gameserver save location
    ew "> Copying PalWorldSettings.ini.template to ${GAME_SETTINGS_FILE}"
    envsubst < "${PALWORLD_TEMPLATE_FILE}" > "${GAME_SETTINGS_FILE}"
    es ">>> Finished setting up PalWorldSettings.ini"
}

function setup_rcon_yaml () {
    if [[ -n ${RCON_ENABLED+x} ]] && [ "$RCON_ENABLED" == "true" ] ; then
        ei ">>> RCON is enabled - Setting up rcon.yaml ..."
        if [[ -n ${RCON_PORT+x} ]]; then
            envsubst < "$RCON_CONFIG_FILE" | sponge "$RCON_CONFIG_FILE"
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
