#!/bin/bash
# shellcheck disable=SC1091

set -e

source /includes/colors.sh


if [[ "${PUID}" -eq 0 ]] || [[ "${PGID}" -eq 0 ]]; then
    ew ">>> Running as root is not supported, please fix your PUID and PGID!"
    exit 1
elif [[ "$(id -u steam)" -ne "${PUID}" ]] || [[ "$(id -g steam)" -ne "${PGID}" ]]; then
    ei "> Current steam user UID is '$(id -u steam)' and GID is '$(id -g steam)'"
    ei "> Setting new steam user UID to '${PUID}' and GID to '${PGID}'"
    groupmod -g "${PGID}" steam && usermod -u "${PUID}" -g "${PGID}" steam
fi

mkdir -p /palworld/backups
chown -R steam:steam /palworld /home/steam/

su steam -c "$@"
