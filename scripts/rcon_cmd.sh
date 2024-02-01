#!/bin/bash

# shellcheck disable=SC1091
source /includes/rcon.sh

if [[ -z ${RCON_ENABLED+x} ]] || [[ "$RCON_ENABLED" != "true" ]]; then
    exit
fi

run_rcon "$@"
