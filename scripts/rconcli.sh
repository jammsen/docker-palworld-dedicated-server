#!/bin/bash
# shellcheck disable=SC2148,SC1091
# Sources: https://pubs.opengroup.org/onlinepubs/009604599/utilities/xcu_chap02.html#tag_02_05_02

source /includes/colors.sh

# Function to run RCON commands
# Arguments: <command>
# Example: run_rcon_cli "showplayers"
run_rcon_cli() {
    local cmd=$*
    if [[ -z ${RCON_ENABLED+x} ]] || [[ "$RCON_ENABLED" != "true" ]]; then
        ew ">>> RCON is not enabled. Aborting RCON command ..."
        exit
    fi

    if [[ ! -f "${RCON_CONFIG_FILE}" ]]; then
        er ">>> RCON config file not found. Aborting RCON command ..."
        return
    fi

    # Edge case for broadcast because it doesn't support spaces in the message
    if [[ ${cmd,,} == broadcast* ]]; then
        cmd=${cmd#broadcast }  # Remove 'broadcast ' from the command (also removes the space after 'broadcast')
        output=$(rcon_broadcast -c "${RCON_CONFIG_FILE}" "${cmd}" | tr -d '\0')
    else
        output=$(rcon -c "${RCON_CONFIG_FILE}" "${cmd}" | tr -d '\0')
    fi

    ei_nn "> RCON: "; echo "${output}"
}

run_rcon_cli "$@"
