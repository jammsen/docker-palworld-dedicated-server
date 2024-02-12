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
    output=$(rcon -c "$RCON_CONFIG_FILE" "${cmd}")
    ei_nn "> RCON: "; e "${output}"
}

run_rcon_cli "$@"
