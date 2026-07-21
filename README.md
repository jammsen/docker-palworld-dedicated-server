# Docker - Palworld Dedicated Server

[![Build-Status master](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push-prod.yml/badge.svg)](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push-prod.yml)
[![Build-Status develop](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push-develop.yml/badge.svg)](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push-develop.yml)
![Docker Pulls](https://img.shields.io/docker/pulls/jammsen/palworld-dedicated-server)
![Docker Stars](https://img.shields.io/docker/stars/jammsen/palworld-dedicated-server)
![Image Size](https://img.shields.io/docker/image-size/jammsen/palworld-dedicated-server/latest)
[![Discord](https://img.shields.io/discord/532141442731212810?logo=discord&label=Discord&link=https%3A%2F%2Fdiscord.gg%2F7tacb9Q6tj)](https://discord.gg/7tacb9Q6tj)

This Docker image includes a Palworld Dedicated Server based on Linux and Docker.



> [!TIP]
> Do you want to chat with the community?
>
> **[Join us on Discord](https://discord.gg/7tacb9Q6tj)**

___

> [!WARNING]
> **Heads-up — RCON has been removed.** This image no longer uses RCON for any container tooling. All server management (player detection, backups, restarts, CLI) now runs via the Palworld REST API.
> - `RCON_ENABLED` now defaults to `false` — this only controls the game server INI setting, not container functionality.
> - Make sure `RESTAPI_ENABLED=true` is set in your `default.env`.
> - See the [Changelog](#changelog) for the full migration guide and renamed environment variables.

___

> [!CAUTION]
> **Public Service Announcement — Custom Script Feature**
>
> After many community requests, this image now supports running a custom script before the server starts.
> This feature is entirely **opt-in** and is controlled by the `CUSTOM_SCRIPT_ENABLED` environment variable, which defaults to `false`.
>
> **This image will never ship with a custom script of any kind.**
>
> If you come across a Docker image that appears to be this one but includes a bundled custom script, please be careful — it is not this image and I have no affiliation with it.
>
> This feature was added at the request of the community. While I am glad to offer the option, I will not be providing support for it, and I refuse to accept **any liability** for any harm, data loss, corruption, or security issues that may result from its use. Please use it at your own discretion. — Public Service Announcement.

## Table of Contents

- [Docker - Palworld Dedicated Server](#docker---palworld-dedicated-server)
  - [Table of Contents](#table-of-contents)
  - [How to ask for support for this Docker image](#how-to-ask-for-support-for-this-docker-image)
  - [Requirements](#requirements)
  - [Minimum system requirements](#minimum-system-requirements)
  - [Changelog](#changelog)
  - [Credits / Shoutout / Contributions](#credits--shoutout--contributions)
  - [Getting started](#getting-started)
  - [Environment variables](#environment-variables)
  - [Docker-Compose examples](#docker-compose-examples)
    - [Gameserver with REST API](#gameserver-with-rest-api)
  - [Run REST API commands](#run-rest-api-commands)
    - [Administration commands](#administration-commands)
    - [Diagnostics \& data commands](#diagnostics--data-commands)
  - [Backup Manager](#backup-manager)
  - [Webhook integration](#webhook-integration)
    - [Supported events](#supported-events)
  - [Web operation panel](#web-operation-panel)
  - [Discord live status card](#discord-live-status-card)
    - [Custom event icons](#custom-event-icons)
    - [Moving or recreating the status card](#moving-or-recreating-the-status-card)
  - [Deploy with Helm](#deploy-with-helm)
  - [FAQ](#faq)
    - [Does this image support Xbox Dedicated Servers?](#does-this-image-support-xbox-dedicated-servers)
    - [How can I use the interactive console in Portainer with this image?](#how-can-i-use-the-interactive-console-in-portainer-with-this-image)
    - [How can I look into the config of my Palworld container?](#how-can-i-look-into-the-config-of-my-palworld-container)
    - [I'm seeing S\_API errors in my logs when I start the container?](#im-seeing-s_api-errors-in-my-logs-when-i-start-the-container)
    - [I'm using Apple silicon type of hardware, can I run this?](#im-using-apple-silicon-type-of-hardware-can-i-run-this)
    - [I changed the `BaseCampWorkerMaxNum` setting, why didn't this update the server?](#i-changed-the-basecampworkermaxnum-setting-why-didnt-this-update-the-server)
    - [How does the random part of the default server name work?](#how-does-the-random-part-of-the-default-server-name-work)
  - [Planned features in the future](#planned-features-in-the-future)
  - [Software used](#software-used)

## How to ask for support for this Docker image

If you need support for this Docker image:

- Feel free to create a new issue.
  - You can reference other issues if you're experiencing a similar problem via #issue-number.
- Follow the instructions and answer the questions of people who are willing to help you.
- Once your issue is resolved, please close it and please consider giving this repo and the [Docker-Hub repository](https://hub.docker.com/repository/docker/jammsen/palworld-dedicated-server) a star.
- Please note that any issue that has been inactive for a week will be closed due to inactivity.

Please avoid:

- Reusing or necroing issues. This can lead to spam and may harass participants who didn't agree to be part of your new problem.
- If this happens, we reserve the right to lock the issue or delete the comments, you have been warned!

## Requirements

To run this Docker image, you need a basic understanding of Docker, Docker-Compose, Linux, and Networking (Port-Forwarding/NAT).

## Minimum system requirements

| Resource | 1-8 players                   | 8-12+ players                  |
| -------- | ----------------------------- | ------------------------------ |
| CPU      | 4 CPU-Cores @ High GHz        | 6-8 CPU Cores @ High GHz       |
| RAM      | 8GB RAM Base + 2GB per player | 12GB RAM Base + 2GB per player |
| Storage  | 30GB                          | 30GB+                          |

## Changelog

You can find the [changelog here](CHANGELOG.md)

## Credits / Shoutout / Contributions

This 2 persons helped a lot along to way and made me and this project better! So if you do not like my version of the Docker image or looking for other features, feel free to check out the following 2 images:
- [@thejcpalma](https://github.com/thejcpalma) - [https://github.com/thejcpalma/palworld-dedicated-server-docker](https://github.com/thejcpalma/palworld-dedicated-server-docker) - [https://hub.docker.com/r/thejcpalma/palworld-dedicated-server](https://hub.docker.com/r/thejcpalma/palworld-dedicated-server) - ❤️🫡
- [@thijsvanloef](https://github.com/thijsvanloef) - [https://github.com/thijsvanloef/palworld-server-docker](https://github.com/thijsvanloef/palworld-server-docker) - [https://hub.docker.com/r/thijsvanloef/palworld-server-docker](https://hub.docker.com/r/thijsvanloef/palworld-server-docker) - ❤️🫡

## Getting started

1. Create a `game` sub-directory on your Docker-Node in your game-server-directory 
   - (Examples: `/srv/palworld`, `/opt/palworld` or `/home/username/palworld`)
   - This directory will be used to store the game server files, including configs and savegames
   - In older versions we asked you to setup permissions via CHMOD or CHOWN, this should not be needed anymore!
2. Set up Port-Forwarding or NAT for the ports in the Docker-Compose file
3. Pull the latest version of the image with `docker pull jammsen/palworld-dedicated-server:latest`
4. Download the [compose.yml](compose.yml) and [default.env](default.env)
5. Set up the `compose.yml` and `default.env` to your liking
   - Make sure you setup PUID and PGID according to the user you want to use
     - **PUID and PGID 0 will error out, thats on purpose!**
     - if you use Docker as root, then you can just use 1000 inside the container
   - Refer to the [Environment-Variables](#environment-variables) section for more information
6. Start the container via `docker-compose up -d && docker-compose logs -f`
   - Watch the log, if no errors occur you can close the logs with ctrl+c
7. Now have fun and happy gaming! 🎮😉

## Environment variables

See [this file](docs/ENV_VARS.md) for the documentation

## Docker-Compose examples

### Gameserver with REST API

<!-- compose-start -->
```yaml
services:
  palworld-dedicated-server:
    container_name: palworld-dedicated-server
    image: jammsen/palworld-dedicated-server:latest
    restart: unless-stopped
    logging:
      driver: "local"
      options:
        max-size: "10m"
        max-file: "3"
    ports:
      - target: 8211 # Gamerserver port inside of the container
        published: 8211 # Gamerserver port on your host
        protocol: udp
        mode: host
      - target: 8212 # Gameserver API port inside of the container
        published: 8212 # Gameserver API port on your host
        protocol: tcp
        mode: host
      - target: 25575 # RCON port inside of the container
        published: 25575 # RCON port on your host
        protocol: tcp
        mode: host
      # Uncomment to reach the web panel (PANEL_ENABLED=true) - do NOT expose this port to the internet, use a reverse proxy or VPN/LAN only
      #- target: 8213 # Web panel port inside of the container
      #  published: 8213 # Web panel port on your host
      #  protocol: tcp
      #  mode: host
    env_file:
      - ./default.env
    volumes:
      - ./game:/palworld

```
<!-- compose-end -->

## Run REST API commands

> [!NOTE]
> Please research the REST API commands on the official source: https://docs.palworldgame.com/category/rest-api

You can use `docker exec palworld-dedicated-server restapicli <command>` right on your terminal/shell.

### Administration commands

Day-to-day server and player management — announcements, moderation, quick lookups, saving and shutdown.

```shell
$ docker exec palworld-dedicated-server restapicli announce "Hello players!"
> Announced: Hello players!

$ docker exec palworld-dedicated-server restapicli ban steam_76000000000000123 "You are banned."
> Banned: steam_76000000000000123

$ docker exec palworld-dedicated-server restapicli banlist
> Ban list (2 entries):
steam_76000000000000123
steam_76000000000000456

$ docker exec palworld-dedicated-server restapicli info
> Server info: {"version": "v0.7.3.90464", "servername": "...", ...}

$ docker exec palworld-dedicated-server restapicli kick steam_76000000000000123 "Goodbye!"
> Kicked: steam_76000000000000123

$ docker exec palworld-dedicated-server restapicli players
> Players: {"players": [...]}

$ docker exec palworld-dedicated-server restapicli save
> Saving world...
> World saved.

$ docker exec palworld-dedicated-server restapicli shutdown 60 "Server restarting soon"
> Shutting down server in 60s...
> Shutdown issued.

$ docker exec palworld-dedicated-server restapicli unban steam_76000000000000123
> Unbanned: steam_76000000000000123
```

### Diagnostics & data commands

Read-only raw JSON dumps of server state — from a quick metrics overview up to a full world actor snapshot.

```shell
$ docker exec palworld-dedicated-server restapicli metrics
> Metrics: {"currentplayernum": 1, "serverfps": 120, ...}

$ docker exec palworld-dedicated-server restapicli settings
> Settings: {"Difficulty": "None", "DayTimeSpeedRate": 1.0, ...}

$ docker exec palworld-dedicated-server restapicli gamedata
> Game data: {"Time": "2026-07-13 21:26:54", "FPS": 118.77, "InGameTime": "14:03", "ActorData": [...]}
# Warning: snapshot of ALL world actors - output can be huge, pipe it to jq or a file
# Note: Needs GAMEDATA_API_ENABLED=true, which starts the server with the
# -enable-gamedata-api launch option. See the example output below and the
# official endpoint documentation:
# https://docs.palworldgame.com/api/rest-api/game-data
```

<details>
<summary>Example <code>gamedata</code> output (shortened, needs <code>GAMEDATA_API_ENABLED=true</code>)</summary>

```json
{
  "Time": "2026-07-13 21:26:54",
  "FPS": 118.77287292480469,
  "AverageFPS": 118.79257965087891,
  "InGameTime": "14:03",
  "InGameDays": 4,
  "ActorData": [
    {
      "Type": "Character",
      "InstanceID": "4DCC09FB000000000000000000000000 : 0487098280F5417DB596B73ED985A5BC",
      "UnitType": "Player",
      "NickName": "jammsen123",
      "TrainerInstanceID": "",
      "TrainerNickName": "",
      "TrainerClass": "",
      "userid": "steam_XXXXXXXXXXXXXX123",
      "ip": "1.2.3.4",
      "level": 2,
      "HP": 1,
      "MaxHP": 500,
      "GuildID": "06362322142040BFBBC718C816B49E6D",
      "GuildName": "Unnamed Guild",
      "Class": "BP_Player_Female_C",
      "Action": "",
      "AI_Action": "",
      "LocationX": -357583.59375,
      "LocationY": 268633.40625,
      "LocationZ": 7951.2998046875,
      "RotationX": 0,
      "RotationY": 0,
      "RotationZ": 68.5,
      "Stage": "None",
      "IsActive": "true"
    },
    {
      "Type": "Character",
      "InstanceID": "00000000000000000000000000000000 : 0CCB7376B14641599BB08EA339FED55E",
      "UnitType": "NPC",
      "NickName": "Scouting Party Survivor",
      "level": 22,
      "HP": 1211,
      "MaxHP": 1211,
      "Class": "BP_NPC_Female_Soldier_C",
      "Action": "BP_Action_NPC_GroundSit",
      "AI_Action": "BP_AIAction_NPC_Relax_GroundSit",
      ...
    },
    {
      "Type": "Character",
      "InstanceID": "00000000000000000000000000000000 : 8B1215C3C7D546AB83D4E647BC1AA421",
      "UnitType": "WildPal",
      "NickName": "Lamball",
      "level": 2,
      "HP": 585,
      "MaxHP": 585,
      "Class": "BP_SheepBall_C",
      "AI_Action": "BP_AIAction_WildLife",
      ...
    },
    ...
  ]
}
```

</details>

## Backup Manager

> [!WARNING]
> If `RESTAPI_ENABLED` is set to `false`, the backup manager will not announce backup start/success/failure in-game and will not trigger a world save before creating a backup.
> This means that the backup will be created from the last auto-save of the server.
> This can lead to data-loss and/or savegame corruption.
>
> **Recommendation:** Please make sure that `RESTAPI_ENABLED=true` is set before using the backup manager.

> [!WARNING]
> Please use in the following part always the `--user steam` option or your files will be written as root


Usage: `docker exec --user steam palworld-dedicated-server backup [command] [arguments]`

| Command | Argument           | Required/Optional | Default Value                     | Values           | Description                                                                                                                                                                          |
| ------- | ------------------ | ----------------- | --------------------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| create  | N/A                | N/A               | N/A                               | N/A              | Creates a backup.                                                                                                                                                                    |
| list    | `<number_to_list>` | Optional          | N/A                               | Positive numbers | Lists all backups.<br>If `<number_to_list>` is specified, only the most<br>recent `<number_to_list>` backups are listed.                                                             |
| clean   | `<number_to_keep>` | Optional          | `BACKUP_RETENTION_AMOUNT_TO_KEEP` | Positive numbers | Cleans up backups.<br>If `<number_to_list>` is specified, cleans and keeps<br>the most recent`<number_to_keep>` backups.<br>If not, default to `BACKUP_RETENTION_AMOUNT_TO_KEEP` var |

Examples:

```shell
$ docker exec --user steam palworld-dedicated-server backup create
>>> Backup 'saved-20240203_032855.tar.gz' created successfully
```

```shell
$ docker exec --user steam palworld-dedicated-server backup list
>>> Listing 2 backup file(s)!
2024-02-03 03:28:55 | saved-20240203_032855.tar.gz
2024-02-03 03:28:00 | saved-20240203_032800.tar.gz
```

```shell
$ docker exec --user steam palworld-dedicated-server backup clean 3
>>> 1 backup(s) cleaned, keeping 2 backup(s).
```

```shell
$ docker exec --user steam palworld-dedicated-server backup list 1
>>> Listing 1 out of 2 backup file(s).
2024-02-03 03:30:00 | saved-20240203_033000.tar.gz
```

## Webhook integration

To enable webhook integrations, you need to set the following environment variables in the `default.env`:

```shell
WEBHOOK_ENABLED=true
WEBHOOK_URL="https://your.webhook.url"
```

After enabling the server should send messages in a Discord-Compatible way to your webhook url.

> You can find more details about these variables [here](docs/ENV_VARS.md#webhook-settings).

### Supported events

- Server starting 
  - This even is not server started. Just add like 5 seconds on top and the server is online
- Server stopped
- Server updating
- Server updating and validating

## Web operation panel

The image ships an optional, built-in web panel (no extra container needed) for administrating the gameserver in the browser:

- **Dashboard** - server status, uptime, population, server frame time, server FPS, in-game day, RAM usage, per-CPU-core load and the last-events log (side by side for the full picture at a glance)
- **Players** - online players with level/ping/buildings, kick/ban/unban and the ban list
- **Settings editor** - every `PalWorldSettings.ini` value with validation, grouped and translated (English + 中文); saved changes are stored as overrides on the game volume and **survive container restarts and re-creation**
- **One-click restart** with in-game announce and world save
- Login-protected; sessions survive restarts

Enable it in your `default.env` and uncomment the `8213` port mapping in your compose file:

```shell
PANEL_ENABLED=true
PANEL_PASSWORD=choose-a-strong-password
```

> **Security warning:** The panel speaks plain HTTP - do **NOT** publish port 8213 to the internet. Use it LAN/VPN-only or put a TLS reverse proxy (Caddy, Traefik, nginx) in front. Details and all `PANEL_*` variables: [ENV_VARS.md](docs/ENV_VARS.md#web-panel).

## Discord live status card

Instead of (or in addition to) event webhooks, the image can maintain **one single Discord message** that it keeps editing in place - a live server status card with uptime, population, server frame time, server FPS, RAM, per-core CPU bars, last restart, the online player list (with platform icons) and a **last-events log** (player joins/leaves, server starting/updating/stopping, restarts, backups, settings changes). No Discord bot account needed, a plain channel webhook is enough; the message survives container restarts (its id is stored on the game volume).

> **Dependency:** The player entries in the event log (and on the web dashboard) come from the built-in player detection - they require `PLAYER_DETECTION_ENABLED=true` (the default) and the REST API. Player detection is the single source for player events; with it disabled, the event log only contains server/system events.

```shell
DISCORD_STATUS_ENABLED=true
DISCORD_STATUS_WEBHOOK_URL="https://discord.com/api/webhooks/..."   # falls back to WEBHOOK_URL
DISCORD_STATUS_UPDATE_INTERVAL=30
```

### Custom event icons

The last-events log ships with proper icons out of the box: the **`icons/modern-slate`** set, rendered from the maintainer's Discord server (same caveat as the platform emojis - upload your own for independence). Set any `DISCORD_STATUS_EMOJI_EVENT_*` variable to empty to fall back to unicode emojis (🟢 🔴 ✅ ⛔ ...).

Prefer a different look? The repo ships **24 ready-made icon sets** in the [`icons/`](icons) folder (13 events each, 128x128 PNGs) in four style families - `modern-*`, `cool-*`, `gaming-*` and `pal-*`. To switch to one (or your own icons):

1. **Pick a set** from `icons/` (e.g. `icons/pal-sphere-classic/`).
2. **Upload the 13 PNGs** to the Discord server your webhook lives in: Server Settings → Emoji → Upload Emoji. Name them so you can find them again, e.g. `pal_join`, `pal_leave`, `pal_rename`, `pal_online`, `pal_offline`, `pal_starting`, `pal_installing`, `pal_updating`, `pal_updating_validate`, `pal_stopping`, `pal_restart`, `pal_backup`, `pal_settings` (emoji names allow only letters, digits and underscores).
3. **Get each token**: type the emoji with a leading backslash in any channel (e.g. `\:pal_join:`) and send - Discord prints the raw token like `<:pal_join:1234567890123456789>`. Copy the whole thing.
4. **Paste the tokens** into the matching `DISCORD_STATUS_EMOJI_EVENT_*` variables in your `default.env` (see [ENV_VARS.md](docs/ENV_VARS.md)) and recreate the container (`docker compose up -d`).

Any variable left empty keeps its unicode default, so you can also replace just a few. Invalid tokens are rejected at startup with a warning. The web dashboard keeps the unicode emojis - Discord custom emojis only render inside Discord.

### Moving or recreating the status card

The card heals itself - whenever the stored message cannot be edited anymore, the companion simply posts a fresh card on the next update and remembers the new one:

- **Recreate the card** (e.g. you want it below newer messages): just **delete the message in Discord**. Within one update interval a fresh card appears in the same channel. No restart needed.
- **Move it to another channel**: point the webhook at the target channel (Discord: channel settings → Integrations → Webhooks → select it → change the channel) - or set `DISCORD_STATUS_WEBHOOK_URL` to a webhook of the target channel and recreate the container. The next update posts a fresh card in the new channel. **Delete the old message manually** - it stays behind and will not update anymore.

## Deploy with Helm

A Helm chart to deploy this container can be found at [palworld-helm](https://github.com/caleb-devops/palworld-helm).

## FAQ

### Does this image support Xbox Dedicated Servers?

> Yes just change the value from `ALLOW_CONNECT_PLATFORM` from Steam to Xbox. See here for more documentation: https://tech.palworldgame.com/getting-started/for-xbox-dedicated-server

### How can I use the interactive console in Portainer with this image?

> You can run this `docker exec -ti palworld-dedicated-server bash' or you could navigate to the **"Stacks"** tab in Portainer, select your stack, and click on the container name. Then click on the **"Exec console"** button.

### How can I look into the config of my Palworld container?

> You can run this `docker exec -ti palworld-dedicated-server cat /palworld/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini` and it will show you the config inside the container.

### I'm seeing S_API errors in my logs when I start the container?

> Errors like `[S_API FAIL] Tried to access Steam interface SteamUser021 before SteamAPI_Init succeeded.` are safe to ignore.

### I'm using Apple silicon type of hardware, can I run this?

> You can try to insert in your docker-compose file this parameter `platform: linux/amd64` at the palworld service. This isn't a special fix for Apple silicon, but to run on other than x86 hosts. The support for arm exists only by enforcing x86 emulation, if that isn't to host already. Rosetta is doing the translation/emulation.

### I changed the `BaseCampWorkerMaxNum` setting, why didn't this update the server?

> This is a confirmed bug. Changing `BaseCampWorkerMaxNum` in the `PalWorldSettings.ini` has no effect on the server. There are tools out there to help with this, like this one: <https://github.com/legoduded/palworld-worldoptions>

> [!WARNING]
> Adding `WorldOption.sav` will break `PalWorldSetting.ini`. So any new changes to the settings (either on the file or via ENV VARS), you will have to create a new `WorldOption.sav` and update it every time for those changes to have an effect.

### How does the random part of the default server name work?

> If `SERVER_NAME` contains `###RANDOM###` (the default), it is replaced with a random 6-character token so your server does not collide with every other unconfigured server in the browser list. The token is generated once and persisted in `server-name.token` in your game volume - your server keeps its name across restarts and container re-creation. Delete that file to roll a new token on the next start, or set a real `SERVER_NAME` to opt out entirely.

## Planned features in the future

- Feel free to suggest something. Under `Issues` there is a Feature Request issue-type.

## Software used

- CM2Network SteamCMD - Debian-based (Officially recommended by Valve - https://developer.valvesoftware.com/wiki/SteamCMD#Docker)
- Node.js 22 + Hono - companion service (web panel and Discord status card)
- Supercronic - https://github.com/aptible/supercronic
- jq - https://jqlang.org/
- Palworld Dedicated Server (APP-ID: 2394010 - https://steamdb.info/app/2394010/config/)
