FROM cm2network/steamcmd

LABEL org.opencontainers.image.authors="Sebastian Schmidt"
LABEL org.opencontainers.image.source="https://github.com/jammsen/docker-palworld-dedicated-server"

ENV TIMEZONE=Europe/Berlin \
    DEBIAN_FRONTEND=noninteractive \
    PUID=0 \
    PGID=0 \
    ALWAYS_UPDATE_ON_START=true \
    MAX_PLAYERS=32 \
    MULTITHREAD_ENABLED=true \
    COMMUNITY_SERVER=true \
    PUBLIC_IP=10.0.0.1 \
    PUBLIC_PORT=8211 \
    SERVER_NAME=jammsen-docker-generated-###RANDOM### \
    SERVER_DESCRIPTION="Palworld-Dedicated-Server running in Docker by jammsen" \
    SERVER_PASSWORD=serverPasswordHere \
    ADMIN_PASSWORD=adminPasswordHere


VOLUME [ "/palworld" ]

EXPOSE 8211/udp

ADD --chmod=777 servermanager.sh /servermanager.sh

CMD ["/servermanager.sh"]
