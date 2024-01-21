FROM cm2network/steamcmd

LABEL org.opencontainers.image.authors="Sebastian Schmidt"
LABEL org.opencontainers.image.source="https://github.com/jammsen/docker-palworld-dedicated-server"

ENV TIMEZONE=UTC \
    DEBIAN_FRONTEND=noninteractive \
    PUID=0 \
    PGID=0 \
    ALWAYS_UPDATE_ON_START=false \
    GAME_PORT=8211 \
    MAX_PLAYERS=16 \
    MULTITHREAD_ENABLED=true \
    COMMUNITY_SERVER=true \
    PUBLIC_IP=10.0.0.1 \
    PUBLIC_PORT=8211 \
    SERVER_NAME="Default server name" \
    SERVER_DESC="Default server description" \
    SERVER_PASSWORD=NONE \
    ADMIN_PASSWORD=admin

VOLUME [ "/palworld" ]

EXPOSE 8211/udp

ADD --chmod=777 servermanager.sh /servermanager.sh

CMD ["/servermanager.sh"]
