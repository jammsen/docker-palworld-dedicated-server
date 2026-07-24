# Companion ↔ Gameserver Contract

The companion runs as a **sidecar container** next to the Palworld dedicated
gameserver container. This document is the complete interface between the two.
Everything not listed here is private to one side and may change freely.

The design rule is **one writable surface per container**: each container owns
exactly one directory the other side mounts read-only, so file locks or write
races between the two can never happen.

## Volumes

| Mount | Gameserver | Companion | Contents read across the boundary |
| --- | --- | --- | --- |
| Game volume | read-write (owner) | **read-only** at `GAME_ROOT` | `game-events.log`, `Pal/Saved/Config/LinuxServer/PalWorldSettings.ini`, `Pal/Saved/SaveGames/banlist.txt` |
| Companion data volume | **read-only** at `COMPANION_DATA_DIR` | read-write (owner) at `COMPANION_DATA_DIR` | `settings-overrides.env` |

The companion data volume additionally holds `state.json` and
`companion-events.log`, which the gameserver never reads.

## Event logs

Two logs, merged by the companion at display time - the file split is the
provenance (game vs. panel events):

- `<game volume>/game-events.log` - written **only** by the gameserver
  (`includes/gameevents.sh`): player joins/leaves/renames, starting,
  installing, updating, updating-validate, stopping, restart, backup.
- `<companion data volume>/companion-events.log` - written **only** by the
  companion: panel restarts, settings saves, REST API online/offline
  transitions.

Line format for both files:

```
<epoch-seconds>|<type>[|<detail>[|<detail2>]]
```

- `detail`/`detail2` carry player names (join/leave/rename); writers strip the
  `|` separator from details so names cannot break the format.
- **The writer owns trimming**: a file exceeding 200 lines is trimmed to its
  last 100 by its writer. Readers must tolerate the file being replaced
  (trim uses write-to-tmp + rename).
- Readers ignore unknown types, so either side may introduce new event types
  without breaking the other.

## Settings overrides

The panel persists settings changes to
`<companion data volume>/settings-overrides.env` (plain `KEY=value` lines).
The gameserver applies them at boot with the highest precedence:

```
template default  <  container environment (default.env)  <  panel override
```

The gameserver validates every line against its settings allow-list and never
sources the file, so it cannot execute code. An absent mount or file simply
means "no overrides". Writable only in `SERVER_SETTINGS_MODE=auto`; the panel
renders read-only in `manual` mode.

## Network

The companion reaches the gameserver's REST API at
`http://${RESTAPI_HOST}:${RESTAPI_PORT}/v1/api/` with HTTP Basic auth
`admin:${ADMIN_PASSWORD}`. In a compose setup `RESTAPI_HOST` is the gameserver
service name; everything the panel and the Discord card show live (players,
metrics, moderation, restart) goes through this API - there is no other
runtime channel between the containers.

## Environment variables

Consumed by the **companion** container:

| Variable | Purpose |
| --- | --- |
| `GAME_ROOT` | Mount point of the read-only game volume (default `/palworld`) |
| `COMPANION_DATA_DIR` | Companion-owned writable directory (default `${GAME_ROOT}/companion`) |
| `RESTAPI_HOST` / `RESTAPI_PORT` / `RESTAPI_TIMEOUT` | Where and how to reach the gameserver REST API |
| `RESTAPI_ENABLED` | Must be `true` on **both** containers - without it the companion has no live game data |
| `ADMIN_PASSWORD` | Shared secret: REST API password, set identically on both containers |
| `SERVER_SETTINGS_MODE` | Mirrors the gameserver's mode so the settings editor knows whether it may write |
| `PANEL_*`, `DISCORD_STATUS_*`, `COMPANION_DEBUG` | Companion features - see ENV_VARS |

Consumed by the **gameserver** container for this contract:

| Variable | Purpose |
| --- | --- |
| `COMPANION_DATA_DIR` | Read-only mount point of the companion data volume (default `${GAME_ROOT}/companion` for the bundled/back-compat layout) |

## Lifecycle & health

- The companion always serves `GET /api/health` (unauthenticated, JSON) on
  `PANEL_PORT`, even when the panel is disabled - use it as the container
  `HEALTHCHECK`.
- The companion tolerates the gameserver being down/unreachable at any time
  (it reports the server offline and keeps polling); ordering via
  `depends_on` is a nicety, not a requirement.
- Supervision is Docker's job (`restart: unless-stopped`) - the companion has
  no in-container supervisor.
