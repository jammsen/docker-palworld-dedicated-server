FROM cm2network/steamcmd

LABEL org.opencontainers.image.authors="Sebastian Schmidt"
LABEL org.opencontainers.image.source="https://github.com/jammsen/docker-palworld-dedicated-server"

ENV TIMEZONE=Europe/Berlin \
    DEBIAN_FRONTEND=noninteractive \
    PUID=0 \
    PGID=0 \
    ALWAYS_UPDATE_ON_START=false \
    GAME_PORT=8211 \
    MAX_PLAYERS=16 \
    SERVER_NAME="jammsen-docker-generated" \
    SERVER_PASSWORD="test" \
    MULTITHREAD_ENABLED=true \
    COMMUNITY_SERVER=true \
    PUBLIC_IP=10.0.0.5 \
    PUBLIC_PORT=8211

VOLUME ["/palworld"}

EXPOSE 8211/tcp 8211/udp

ADD servermanager.sh /servermanager.sh

CMD ["/servermanager.sh"]
