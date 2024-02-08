#!/bin/bash
# shellcheck disable=SC2148,SC1091

source /includes/colors.sh

# Function to run RCON commands
# Arguments: <command>
# Example: run_rcon_cli "showplayers"

run_rcon_cli() {
    local cmd=$1

    if [[ -z ${RCON_ENABLED+x} ]] || [[ "$RCON_ENABLED" != "true" ]]; then
        ee ">>> RCON is not enabled. Aborting RCON command ..."
        exit
    fi

    output=$(rconcli -c /configs/rcon.yaml "${cmd}")
    ei "> RCON: ${output}"
}

run_rcon_cli "$@"
