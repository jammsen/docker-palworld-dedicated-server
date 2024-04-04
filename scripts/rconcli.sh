#!/bin/bash
# shellcheck disable=SC2148,SC1091
# Sources: https://pubs.opengroup.org/onlinepubs/009604599/utilities/xcu_chap02.html#tag_02_05_02

source /includes/colors.sh

# Function to run RCON commands
# Arguments: <command>
# Example: run_rcon_cli "showplayers"
run_rcon_cli() {
    if [[ -z ${RCON_ENABLED+x} ]] || [[ "$RCON_ENABLED" != "true" ]]; then
        ew ">>> RCON is not enabled. Aborting RCON command ..."
        exit
    fi
    local command=$1
    shift
    if [ $# -ge 1 ]; then
        # In the command value, replace ASCII space characters with
        # unicode non-breaking space characters.
        full_command="$command $(echo "$@" | tr ' ' '\240')"
    else
        full_command=$command
    fi
    output=$(rcon -c "$RCON_CONFIG_FILE" "$full_command" | tr -d '\0')
    ei_nn "> RCON: "; e "${output}"
}

run_rcon_cli "$@"
