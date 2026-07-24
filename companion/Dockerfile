FROM node:22-bookworm-slim@sha256:6c74791e557ce11fc957704f6d4fe134a7bc8d6f5ca4403205b2966bd488f6b3 AS build

WORKDIR /build

COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

COPY . ./
RUN npm run typecheck \
    && npm test \
    && npm run build

FROM node:22-bookworm-slim@sha256:6c74791e557ce11fc957704f6d4fe134a7bc8d6f5ca4403205b2966bd488f6b3

LABEL maintainer="Sebastian Schmidt - https://github.com/jammsen/docker-palworld-companion"
LABEL org.opencontainers.image.authors="Sebastian Schmidt"
LABEL org.opencontainers.image.source="https://github.com/jammsen/docker-palworld-companion"

# Sidecar layout (see CONTRACT.md): the game volume is mounted read-only at
# GAME_ROOT, the companion's own writable volume at COMPANION_DATA_DIR
ENV GAME_ROOT=/palworld \
    COMPANION_DATA_DIR=/data

COPY --from=build /build/dist/companion.mjs /companion/companion.mjs

RUN mkdir -p "${COMPANION_DATA_DIR}" \
    && chown node:node "${COMPANION_DATA_DIR}" \
    && node /companion/companion.mjs --version

USER node

EXPOSE 8213/tcp

VOLUME ["${COMPANION_DATA_DIR}"]

# /api/health is always served, even when the panel is disabled. The port
# fallback mirrors config.ts envPort: invalid PANEL_PORT values fall back to
# 8213, so the probe always targets the port the app actually listens on
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["node", "-e", "const p=Number.parseInt(process.env.PANEL_PORT??'',10);const port=p>=1&&p<=65535?p:8213;fetch(`http://127.0.0.1:${port}/api/health`).then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]

ENTRYPOINT ["node", "/companion/companion.mjs"]
