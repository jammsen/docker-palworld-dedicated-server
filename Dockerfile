FROM --platform=linux/amd64 cm2network/steamcmd:root

LABEL maintainer="Sebastian Schmidt - https://github.com/jammsen/docker-palworld-dedicated-server"
LABEL org.opencontainers.image.authors="Sebastian Schmidt"
LABEL org.opencontainers.image.source="https://github.com/jammsen/docker-palworld-dedicated-server"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    # Path-vars
    GAME_ROOT="/palworld" \
    GAME_PATH="/palworld/Pal" \
    GAME_SAVE_PATH="/palworld/Pal/Saved" \
    GAME_CONFIG_PATH="/palworld/Pal/Saved/Config/LinuxServer" \
    GAME_SETTINGS_FILE="/palworld/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini" \
    GAME_ENGINE_FILE="/palworld/Pal/Saved/Config/LinuxServer/Engine.ini" \
    STEAMCMD_PATH="/home/steam/steamcmd" \
    RCON_CONFIG_FILE="/home/steam/steamcmd/rcon.yaml" \
    BACKUP_PATH="/palworld/backups" \
    # Container-setttings
    PUID=1000 \
    PGID=1000 \
    TZ="Europe/Berlin" \
    # SteamCMD-settings
    ALWAYS_UPDATE_ON_START=true \
    STEAMCMD_VALIDATE_FILES=true \
    # Backup-settings
    BACKUP_ENABLED=true \
    BACKUP_CRON_EXPRESSION="0 * * * *" \
    BACKUP_RETENTION_POLICY=true \
    BACKUP_RETENTION_AMOUNT_TO_KEEP=72 \
    # Webhook-settings
    WEBHOOK_ENABLED=false \
    WEBHOOK_URL= \
    WEBHOOK_START_TITLE="Server is starting" \
    WEBHOOK_START_DESCRIPTION="The gameserver is starting" \
    WEBHOOK_START_COLOR="2328576" \
    WEBHOOK_STOP_TITLE="Server has been stopped" \
    WEBHOOK_STOP_DESCRIPTION="The gameserver has been stopped" \
    WEBHOOK_STOP_COLOR="7413016" \
    WEBHOOK_INFO_TITLE="Info" \
    WEBHOOK_INFO_DESCRIPTION="This is an info from the server" \
    WEBHOOK_INFO_COLOR="2849520" \
    WEBHOOK_UPDATE_TITLE="Updating server" \
    WEBHOOK_UPDATE_DESCRIPTION="Server is being updated" \
    WEBHOOK_UPDATE_COLOR="2849520" \
    WEBHOOK_UPDATE_VALIDATION_TITLE="Updating and validating server" \
    WEBHOOK_UPDATE_VALIDATION_DESCRIPTION="Server is being updated and validated" \
    WEBHOOK_UPDATE_VALIDATION_COLOR="2849520" \
    # Gameserver-start-settings
    MULTITHREAD_ENABLED=true \
    COMMUNITY_SERVER=true \
    # Config-setting - Warning: Every setting below here will be affected!
    SERVER_SETTINGS_MODE=manual \
    # Engine.ini settings
    NETSERVERMAXTICKRATE=120 \
    # PalWorldSettings.ini settings
    DIFFICULTY=None \
    DAYTIME_SPEEDRATE=1.000000 \
    NIGHTTIME_SPEEDRATE=1.000000 \
    EXP_RATE=1.000000 \
    PAL_CAPTURE_RATE=1.000000 \
    PAL_SPAWN_NUM_RATE=1.000000 \
    PAL_DAMAGE_RATE_ATTACK=1.000000 \
    PAL_DAMAGE_RATE_DEFENSE=1.000000 \
    PLAYER_DAMAGE_RATE_ATTACK=1.000000 \
    PLAYER_DAMAGE_RATE_DEFENSE=1.000000 \
    PLAYER_STOMACH_DECREASE_RATE=1.000000 \
    PLAYER_STAMINA_DECREACE_RATE=1.000000 \
    PLAYER_AUTO_HP_REGENE_RATE=1.000000 \
    PLAYER_AUTO_HP_REGENE_RATE_IN_SLEEP=1.000000 \
    PAL_STOMACH_DECREACE_RATE=1.000000 \
    PAL_STAMINA_DECREACE_RATE=1.000000 \
    PAL_AUTO_HP_REGENE_RATE=1.000000 \
    PAL_AUTO_HP_REGENE_RATE_IN_SLEEP=1.000000 \
    BUILD_OBJECT_DAMAGE_RATE=1.000000 \
    BUILD_OBJECT_DETERIORATION_DAMAGE_RATE=1.000000 \
    COLLECTION_DROP_RATE=1.000000 \
    COLLECTION_OBJECT_HP_RATE=1.000000 \
    COLLECTION_OBJECT_RESPAWN_SPEED_RATE=1.000000 \
    ENEMY_DROP_ITEM_RATE=1.000000 \
    DEATH_PENALTY=All \
    ENABLE_PLAYER_TO_PLAYER_DAMAGE=false \
    ENABLE_FRIENDLY_FIRE=false \
    ENABLE_INVADER_ENEMY=true \
    ACTIVE_UNKO=false \
    ENABLE_AIM_ASSIST_PAD=true \
    ENABLE_AIM_ASSIST_KEYBOARD=false \
    DROP_ITEM_MAX_NUM=3000 \
    DROP_ITEM_MAX_NUM_UNKO=100 \
    BASE_CAMP_MAX_NUM=128 \
    BASE_CAMP_WORKER_MAXNUM=15 \
    DROP_ITEM_ALIVE_MAX_HOURS=1.000000 \
    AUTO_RESET_GUILD_NO_ONLINE_PLAYERS=false \
    AUTO_RESET_GUILD_TIME_NO_ONLINE_PLAYERS=72.000000 \
    GUILD_PLAYER_MAX_NUM=20 \
    PAL_EGG_DEFAULT_HATCHING_TIME=72.000000 \
    WORK_SPEED_RATE=1.000000 \
    IS_MULTIPLAY=false \
    IS_PVP=false \
    CAN_PICKUP_OTHER_GUILD_DEATH_PENALTY_DROP=false \
    ENABLE_NON_LOGIN_PENALTY=true \
    ENABLE_FAST_TRAVEL=true \
    IS_START_LOCATION_SELECT_BY_MAP=true \
    EXIST_PLAYER_AFTER_LOGOUT=false \
    ENABLE_DEFENSE_OTHER_GUILD_PLAYER=false \
    COOP_PLAYER_MAX_NUM=4 \
    MAX_PLAYERS=32 \
    SERVER_NAME="jammsen-docker-generated-###RANDOM###" \
    SERVER_DESCRIPTION="Palworld-Dedicated-Server running in Docker by jammsen" \
    ADMIN_PASSWORD=adminPasswordHere \
    SERVER_PASSWORD=serverPasswordHere \
    PUBLIC_PORT=8211 \
    PUBLIC_IP= \
    RCON_ENABLED=false \
    RCON_PORT=25575 \
    REGION= \
    USEAUTH=true \
    BAN_LIST_URL=https://api.palworldgame.com/api/banlist.txt

EXPOSE 8211/udp
EXPOSE 25575/tcp

COPY --chown=steam:steam --chmod=755 scripts/ /scripts
COPY --chown=steam:steam --chmod=755 includes/ /includes
COPY --chown=steam:steam --chmod=755 configs/rcon.yaml /home/steam/steamcmd/rcon.yaml
COPY --chown=steam:steam --chmod=755 entrypoint.sh /

RUN ln -s /scripts/backupmanager.sh /usr/local/bin/backup \
    && ln -s /scripts/rconcli.sh /usr/local/bin/rconcli

# Install minimum required packages for dedicated server
RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests procps xdg-user-dirs \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Latest releases available at https://github.com/aptible/supercronic/releases
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=cd48d45c4b10f3f0bfdd3a57d054cd05ac96812b

RUN curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
    && chmod +x "$SUPERCRONIC" \
    && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
    && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

# Latest releases available at https://github.com/gorcon/rcon-cli/releases
ENV RCON_URL=https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-amd64_linux.tar.gz \
    RCON_TGZ=rcon-0.10.3-amd64_linux.tar.gz \
    RCON_TGZ_MD5SUM=8601c70dcab2f90cd842c127f700e398 \
    RCON_BINARY=rcon

RUN curl -fsSLO "$RCON_URL" \
    && echo "${RCON_TGZ_MD5SUM} ${RCON_TGZ}" | md5sum -c - \
    && tar xfz rcon-0.10.3-amd64_linux.tar.gz \
    && chmod +x "rcon-0.10.3-amd64_linux/$RCON_BINARY" \
    && mv "rcon-0.10.3-amd64_linux/$RCON_BINARY" "/usr/local/bin/${RCON_BINARY}" \
    && rm -Rf rcon-0.10.3-amd64_linux rcon-0.10.3-amd64_linux.tar.gz

VOLUME ["${GAME_ROOT}"]

ENTRYPOINT  ["/entrypoint.sh"]
CMD ["/scripts/servermanager.sh"]
