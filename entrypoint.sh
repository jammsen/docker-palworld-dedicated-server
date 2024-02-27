#!/bin/bash
# shellcheck disable=SC1091

set -e

APP_USER=steam
APP_GROUP=steam
APP_HOME=/home/$APP_USER

source /includes/colors.sh

if [[ "${PUID}" -eq 0 ]] || [[ "${PGID}" -eq 0 ]]; then
    ee ">>> Running as root is not supported, please fix your PUID and PGID!"
    exit 1
elif [[ "$(id -u steam)" -ne "${PUID}" ]] || [[ "$(id -g steam)" -ne "${PGID}" ]]; then
    ew "> Current $APP_USER user PUID is '$(id -u steam)' and PGID is '$(id -g steam)'"
    ew "> Setting new $APP_USER user PUID to '${PUID}' and PGID to '${PGID}'"
    groupmod -g "${PGID}" "$APP_GROUP" && usermod -u "${PUID}" -g "${PGID}" "$APP_USER"
else 
    ew "> Current $APP_USER user PUID is '$(id -u steam)' and PGID is '$(id -g steam)'"
    ew "> PUID and PGID matching what is requested for user $APP_USER"
fi

chown -R "$APP_USER":"$APP_GROUP" "$APP_HOME"
chown -R "$APP_USER":"$APP_GROUP" "$GAME_ROOT"
chown "$APP_USER":"$APP_GROUP" /entrypoint.sh
chown "$APP_USER":"$APP_GROUP" /PalWorldSettings.ini.template
chown -R "$APP_USER":"$APP_GROUP" /scripts
chown -R "$APP_USER":"$APP_GROUP" /includes

ew_nn "> id steam: " ; e "$(id steam)"

exec gosu $APP_USER:$APP_GROUP "$@"
