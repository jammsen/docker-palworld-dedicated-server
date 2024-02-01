#!/bin/bash

# shellcheck disable=SC1091
source /includes/colors.sh


if [[ "${PUID}" -eq 0 ]] || [[ "${PGID}" -eq 0 ]]; then
    pp --warning "[WARNING] Running as root is not supported, please fix your PUID and PGID!\n"
    exit 1
elif [[ "$(id -u steam)" -ne "${PUID}" ]] || [[ "$(id -g steam)" -ne "${PGID}" ]]; then
    pp --info "Old steam user UID was '$(id -u steam)' and GID was '$(id -g steam)'\n"
    pp --info "Setting steam user UID to '${PUID}' and GID to '${PGID}'\n"
    usermod -o -u "${PUID}" steam
    groupmod -o -g "${PGID}" steam
fi

mkdir -p /palworld/backups
chown -R steam:steam /palworld /home/steam/

su steam -c /scripts/servermanager.sh
