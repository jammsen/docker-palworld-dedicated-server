#!/bin/bash
# shellcheck disable=SC1091

set -e

APP_USER=steam
APP_GROUP=steam
APP_HOME=/home/$APP_USER

source /includes/colors.sh
source /includes/permissions.sh

if [[ "${PUID}" -eq 0 ]] || [[ "${PGID}" -eq 0 ]]; then
    ee ">>> Running Palworld as root is not supported, please fix your PUID and PGID!"
    exit 1
elif [[ "$(id -u steam)" -ne "${PUID}" ]] || [[ "$(id -g steam)" -ne "${PGID}" ]]; then
    ew "> Current $APP_USER user PUID is '$(id -u steam)' and PGID is '$(id -g steam)'"
    ew "> Setting new $APP_USER user PUID to '${PUID}' and PGID to '${PGID}'"
    groupmod -g "${PGID}" "$APP_GROUP" && usermod -u "${PUID}" -g "${PGID}" "$APP_USER"
else
    ew "> Current $APP_USER user PUID is '$(id -u steam)' and PGID is '$(id -g steam)'"
    ew "> PUID and PGID matching what is requested for user $APP_USER"
fi

change_ownership $APP_USER $APP_GROUP "$APP_HOME"
change_ownership $APP_USER $APP_GROUP "$GAME_ROOT"
change_ownership $APP_USER $APP_GROUP /entrypoint.sh
change_ownership $APP_USER $APP_GROUP /PalWorldSettings.ini.template
change_ownership $APP_USER $APP_GROUP /scripts
change_ownership $APP_USER $APP_GROUP /includes

ew_nn "> id steam: "
e "$(id steam)"

if [ "$(id -u)" -eq 0 ]; then
    ei "> Running Palworld as $APP_USER:$APP_GROUP (via gosu)"
    exec gosu $APP_USER:$APP_GROUP "$@"
else
    ei "> Running Palworld as $(id -un):$(id -gn) (current user)"
    exec "$@"
fi
