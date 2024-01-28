# Docker - Palworld Dedicated Server

[![Build-Status master](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push-prod.yml/badge.svg)](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push-prod.yml)
[![Build-Status develop](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push-develop.yml/badge.svg)](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push-develop.yml)
![Docker Pulls](https://img.shields.io/docker/pulls/jammsen/palworld-dedicated-server)
![Docker Stars](https://img.shields.io/docker/stars/jammsen/palworld-dedicated-server)
![Image Size](https://img.shields.io/docker/image-size/jammsen/palworld-dedicated-server/latest)

This Docker image includes a Palworld Dedicated Server based on Linux and Docker.

___

## Table of Contents

- [Docker - Palworld Dedicated Server](#docker---palworld-dedicated-server)
  - [Table of Contents](#table-of-contents)
  - [How to ask for support for this Docker image](#how-to-ask-for-support-for-this-docker-image)
  - [Requirements](#requirements)
  - [Getting started](#getting-started)
  - [Environment-Variables](#environment-variables)
    - [Container-Settings](#container-settings)
      - [TZ identifiers](#tz-identifiers)
      - [Cron expression](#cron-expression)
    - [Gameserver-Settings](#gameserver-settings)
  - [Docker-Compose examples](#docker-compose-examples)
    - [Gameserver Standalone](#gameserver-standalone)
    - [Gameserver with RCON](#gameserver-with-rcon)
      - [What do the parameters in the entrypoint for RCON mean](#what-do-the-parameters-in-the-entrypoint-for-rcon-mean)
      - [Run RCON commands](#run-rcon-commands)
    - [Gameserver with Portainer](#gameserver-with-portainer)
  - [FAQ](#faq)
    - [How can i look into the config of my Palworld container?](#how-can-i-look-into-the-config-of-my-palworld-container)
    - [Im seeing S\_API errors in my logs when i start the container](#im-seeing-s_api-errors-in-my-logs-when-i-start-the-container)
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

## Getting Started

1. Create a `game` sub-directory on your Docker node in your game-server-directory (Example: `/srv/palworld`). Give it full permissions with `chmod 777 game` or use `chown -R 1000:1000 game/`.
2. Set up Port-Forwarding or NAT for the ports in the Docker-Compose file.
3. Pull the latest version of the image with `docker pull jammsen/palworld-dedicated-server:latest`.
4. Set up your own docker-compose.yml as per your requirements. Refer to the [Docker-Compose examples](#examples) section and the [Environment-Variables](#examples) section for more information.
5. Start the container via `docker-compose up -d && docker-compose logs -f`. Watch the log, if no errors occur you can close the logs with ctrl+c.
6. Happy gaming!

## Environment Variables

**Important:** In this section you will find a lot of environment variables to control your container-behavior and gameserver-settings. Due to the extensive control options, the settings are split into two parts for documentation: **Container-Settings** and **Gameserver-Settings**.

## Container-Settings

These settings control the behavior of the Docker container:

| Variable               | Description                                                         | Default value                  | Allowed value                         |
| ---------------------- | ------------------------------------------------------------------- | ------------------------------ | ------------------------------------- |
| TZ                     | Timezone used for time stamping server backups                      | Europe/Berlin                  | See [TZ identifiers](#tz-identifiers) |
| ALWAYS_UPDATE_ON_START | Updates the server on startup                                       | true                           | false/true                            |
| MULTITHREAD_ENABLED    | Sets options for "Improved multi-threaded CPU performance"          | true                           | false/true                            |
| COMMUNITY_SERVER       | Set to enabled, the server will appear in the Community-Serverlist. | true                           | false/true                            |
| BACKUP_ENABLED         | Backup function, creates backups in your `game` directory           | true                           | false/true                            |
| BACKUP_CRON_EXPRESSION | Needs a Cron-Expression - See [Cron expression](#cron-expression)   | 0 * * * * (meaning every hour) | Cron-Expression                       |
| SKIP_SERVER_SETUP      | keep PalWorldSettings.ini unchanged                                 | false                          | false/true                            |

### TZ identifiers

The `TZ` setting affects logging output and the backup function. [TZ identifiers](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#Time_Zone_abbreviations) are a format for defining a timezone near you.

### Cron expression

The `BACKUP_CRON_EXPRESSION` setting affects the backup function. In a Cron-Expression, you define an interval for when to run jobs. This image uses Supercronic for crons, see https://github.com/aptible/supercronic#crontab-format or https://crontab-generator.org

##  Gameserver-Settings

This section lists all the settings currently adjustable via Docker environment variables, based on the **order** and **contents of the DefaultPalWorldSettings.ini**.

Information sources and credits to the following websites:
* [Palworld Tech Guide](https://tech.palworldgame.com/optimize-game-balance) for the game server documentation
* [PalworldSettingGenerator](https://dysoncheng.github.io/PalWorldSettingGenerator/setting.html) for variable descriptions

**Important:** Please note that all of this is subject to change. **The game is still in early access.**

| Variable                                  | Game setting                         | Description                                                                                                                                                       | Default Value                                          | Allowed Value |
| ----------------------------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ | ------------- |
| NETSERVERMAXTICKRATE                      | NetServerMaxTickRate                 | Changes the TickRate of the server, be very careful with this setting!                                                                                            | 120                                                    | 30-120        |
| DIFFICULTY                                | Difficulty                           | Choose one of the following:<br>`None`<br>`Normal`<br>`Difficult`                                                                                                 | None                                                   | Enum          |
| DAYTIME_SPEEDRATE                         | DayTimeSpeedRate                     | Day time speed - Smaller number means shorter days                                                                                                                | 1.000000                                               | Float         |
| NIGHTTIME_SPEEDRATE                       | NightTimeSpeedRate                   | Night time speed - Smaller number means shorter nights                                                                                                            | 1.000000                                               | Float         |
| EXP_RATE                                  | ExpRate                              | EXP rate                                                                                                                                                          | 1.000000                                               | Float         |
| PAL_CAPTURE_RATE                          | PalCaptureRate                       | Pal capture rate                                                                                                                                                  | 1.000000                                               | Float         |
| PAL_SPAWN_NUM_RATE                        | PalSpawnNumRate                      | Pal appearance rate                                                                                                                                               | 1.000000                                               | Float         |
| PAL_DAMAGE_RATE_ATTACK                    | PalDamageRateAttack                  | Damage from pals multipiler                                                                                                                                       | 1.000000                                               | Float         |
| PAL_DAMAGE_RATE_DEFENSE                   | PalDamageRateDefense                 | Damage to pals multipiler                                                                                                                                         | 1.000000                                               | Float         |
| PLAYER_DAMAGE_RATE_ATTACK                 | PlayerDamageRateAttack               | Damage from player multipiler                                                                                                                                     | 1.000000                                               | Float         |
| PLAYER_DAMAGE_RATE_DEFENSE                | PlayerDamageRateDefense              | Damage to  player multipiler                                                                                                                                      | 1.000000                                               | Float         |
| PLAYER_STOMACH_DECREASE_RATE              | PlayerStomachDecreaceRate            | Player hunger depletion rate                                                                                                                                      | 1.000000                                               | Float         |
| PLAYER_STAMINA_DECREACE_RATE              | PlayerStaminaDecreaceRate            | Player stamina reduction rate                                                                                                                                     | 1.000000                                               | Float         |
| PLAYER_AUTO_HP_REGENE_RATE                | PlayerAutoHPRegeneRate               | Player auto HP regeneration rate                                                                                                                                  | 1.000000                                               | Float         |
| PLAYER_AUTO_HP_REGENE_RATE_IN_SLEEP       | PlayerAutoHpRegeneRateInSleep        | Player sleep HP regeneration rate                                                                                                                                 | 1.000000                                               | Float         |
| PAL_STOMACH_DECREACE_RATE                 | PalStomachDecreaceRate               | Pal hunger depletion rate                                                                                                                                         | 1.000000                                               | Float         |
| PAL_STAMINA_DECREACE_RATE                 | PalStaminaDecreaceRate               | Pal stamina reduction rate                                                                                                                                        | 1.000000                                               | Float         |
| PAL_AUTO_HP_REGENE_RATE                   | PalAutoHPRegeneRate                  | Pal auto HP regeneration rate                                                                                                                                     | 1.000000                                               | Float         |
| PAL_AUTO_HP_REGENE_RATE_IN_SLEEP          | PalAutoHpRegeneRateInSleep           | Pal sleep health regeneration rate (in Palbox)                                                                                                                    | 1.000000                                               | Float         |
| BUILD_OBJECT_DAMAGE_RATE                  | BuildObjectDamageRate                | Damage to structure multipiler                                                                                                                                    | 1.000000                                               | Float         |
| BUILD_OBJECT_DETERIORATION_DAMAGE_RATE    | PalAutoHpRegeneRateInSleep           | Structure determination rate                                                                                                                                      | 1.000000                                               | Float         |
| COLLECTION_DROP_RATE                      | CollectionDropRate                   | Getherable items multipiler                                                                                                                                       | 1.000000                                               | Float         |
| COLLECTION_OBJECT_HP_RATE                 | CollectionObjectHpRate               | Getherable objects HP multipiler                                                                                                                                  | 1.000000                                               | Float         |
| COLLECTION_OBJECT_RESPAWN_SPEED_RATE      | CollectionObjectRespawnSpeedRate     | Getherable objects respawn interval                                                                                                                               | 1.000000                                               | Float         |
| ENEMY_DROP_ITEM_RATE                      | EnemyDropItemRate                    | Dropped Items Multipiler                                                                                                                                          | 1.000000                                               | Float         |
| DEATH_PENALTY                             | DeathPenalty                         | `None` : No lost<br> `Item` : Lost item without equipment<br>`ItemAndEquipment` : Lost item and equipment<br>`All`: Lost All item,   equipment, pal(in inventory) | All                                                    | Enum          |
| ENABLE_PLAYER_TO_PLAYER_DAMAGE            | bEnablePlayerToPlayerDamage          | Allows players to cause damage to players                                                                                                                         | false                                                  | Boolean       |
| ENABLE_FRIENDLY_FIRE                      | bEnableFriendlyFire                  | Allow friendly fire                                                                                                                                               | false                                                  | Boolean       |
| ENABLE_INVADER_ENEMY                      | bEnableInvaderEnemy                  | Enable invaders                                                                                                                                                   | true                                                   | Boolean       |
| ACTIVE_UNKO                               | bActiveUNKO                          | Enable UNKO                                                                                                                                                       | false                                                  | Boolean       |
| ENABLE_AIM_ASSIST_PAD                     | bEnableAimAssistPad                  | Enable controller aim assist                                                                                                                                      | true                                                   | Boolean       |
| ENABLE_AIM_ASSIST_KEYBOARD                | bEnableAimAssistKeyboard             | Enable Keyboard aim assist                                                                                                                                        | false                                                  | Boolean       |
| DROP_ITEM_MAX_NUM                         | DropItemMaxNum                       | Maximum number of drops in the world                                                                                                                              | 3000                                                   | Integer       |
| DROP_ITEM_MAX_NUM_UNKO                    | DropItemMaxNum                       | Maximum number of UNKO drops in the world                                                                                                                         | 100                                                    | Integer       |
| BASE_CAMP_MAX_NUM                         | BaseCampMaxNum                       | Maximum number of base camps                                                                                                                                      | 128                                                    | Integer       |
| BASE_CAMP_WORKER_MAXNUM                   | BaseCampWorkerMaxNum                 | Maximum number of workers                                                                                                                                         | 15                                                     | Integer       |
| DROP_ITEM_ALIVE_MAX_HOURS                 | DropItemAliveMaxHours                | Time it takes for items to despawn in hours                                                                                                                       | 1.000000                                               | Float         |
| AUTO_RESET_GUILD_NO_ONLINE_PLAYERS        | bAutoResetGuildNoOnlinePlayers       | Automatically reset guild when no players are online                                                                                                              | false                                                  | Bool          |
| AUTO_RESET_GUILD_TIME_NO_ONLINE_PLAYERS   | AutoResetGuildTimeNoOnlinePlayers    | Time to automatically reset guild when no players are online                                                                                                      | 72.000000                                              | Float         |
| GUILD_PLAYER_MAX_NUM                      | GuildPlayerMaxNum                    | Max player of Guild                                                                                                                                               | 20                                                     | Integer       |
| PAL_EGG_DEFAULT_HATCHING_TIME             | PalEggDefaultHatchingTime            | Time(h) to incubate massive egg                                                                                                                                   | 72.000000                                              | Float         |
| WORK_SPEED_RATE                           | WorkSpeedRate                        | Work speed muliplier                                                                                                                                              | 1.000000                                               | Float         |
| IS_MULTIPLAY                              | bIsMultiplay                         | Enable multiplayer                                                                                                                                                | false                                                  | Boolean       |
| IS_PVP                                    | bIsPvP                               | Enable PVP                                                                                                                                                        | false                                                  | Boolean       |
| CAN_PICKUP_OTHER_GUILD_DEATH_PENALTY_DROP | bCanPickupOtherGuildDeathPenaltyDrop | Allow players from other guilds to pick up death penalty items                                                                                                    | false                                                  | Boolean       |
| ENABLE_NON_LOGIN_PENALTY                  | bEnableNonLoginPenalty               | Enable non-login penalty                                                                                                                                          | true                                                   | Boolean       |
| ENABLE_FAST_TRAVEL                        | bEnableFastTravel                    | Enable fast travel                                                                                                                                                | true                                                   | Boolean       |
| IS_START_LOCATION_SELECT_BY_MAP           | bIsStartLocationSelectByMap          | Enable selecting of start location                                                                                                                                | true                                                   | Boolean       |
| EXIST_PLAYER_AFTER_LOGOUT                 | bExistPlayerAfterLogout              | Toggle for deleting players when they log off                                                                                                                     | false                                                  | Boolean       |
| ENABLE_DEFENSE_OTHER_GUILD_PLAYER         | bEnableDefenseOtherGuildPlayer       | Allows defense against other guild players                                                                                                                        | false                                                  | Boolean       |
| COOP_PLAYER_MAX_NUM                       | CoopPlayerMaxNum                     | Maximum number of players in a guild                                                                                                                              | 4                                                      | Integer       |
| MAX_PLAYERS                               | ServerPlayerMaxNum                   | Maximum number of people who can join the server                                                                                                                  | 32                                                     | Integer       |
| SERVER_NAME                               | ServerName                           | Server name                                                                                                                                                       | jammsen-docker-generated-###RANDOM###                  | Integer       |
| SERVER_DESCRIPTION                        | ServerDescription                    | Server description                                                                                                                                                | Palworld-Dedicated-Server running in Docker by jammsen | String        |
| ADMIN_PASSWORD                            | server admin password                | AdminPassword                                                                                                                                                     | adminPasswordHere                                      | String        |
| SERVER_PASSWORD                           | AdminPassword                        | Set the server password.                                                                                                                                          | serverPasswordHere                                     | String        |
| PUBLIC_PORT                               | public port                          | Public port number                                                                                                                                                | 8211                                                   | Integer       |
| PUBLIC_IP                                 | public ip or FQDN                            | Public IP or FQDN                                                                                                                                                         |                                                        | String        |
| RCON_ENABLED                              | RCONEnabled                          | Enable RCON - Use ADMIN_PASSWORD to login                                                                                                                         | false                                                  | Boolean       |
| RCON_PORT                                 | RCONPort                             | Port number for RCON                                                                                                                                              | 25575                                                  | Integer       |
| REGION                                    | Region                               | Area                                                                                                                                                              |                                                        | String        |
| USEAUTH                                   | bUseAuth                             | Use authentication                                                                                                                                                | true                                                   | Boolean       |
| BAN_LIST_URL                              | BanListURL                           | Which ban list to use                                                                                                                                             | https://api.palworldgame.com/api/banlist.txt           | String        |

## Docker-Compose examples

### Gameserver standalone

```yml
version: '3.9'
services:
  palworld-dedicated-server:
    #build: .
    container_name: palworld-dedicated-server
    image: jammsen/palworld-dedicated-server:latest
    restart: unless-stopped
    ports:
      - target: 8211 # Gamerserver port inside of the container
        published: 8211 # Gamerserver port on your host
        protocol: udp
        mode: host
      - target: 25575 # RCON port inside of the container
        published: 25575 # RCON port on your host
        protocol: tcp
        mode: host
    environment:
      - TZ=Europe/Berlin # Change this for logging and backup, see "Environment-Variables" 
      - ALWAYS_UPDATE_ON_START=true
      - MULTITHREAD_ENABLED=true
      - COMMUNITY_SERVER=true
      - BACKUP_ENABLED=true
      - BACKUP_CRON_EXPRESSION=0 * * * *
      - NETSERVERMAXTICKRATE=120
      - DIFFICULTY=None
      - DAYTIME_SPEEDRATE=1.000000
      - NIGHTTIME_SPEEDRATE=1.000000
      - EXP_RATE=1.000000
      - PAL_CAPTURE_RATE=1.000000
      - PAL_SPAWN_NUM_RATE=1.000000
      - PAL_DAMAGE_RATE_ATTACK=1.000000
      - PAL_DAMAGE_RATE_DEFENSE=1.000000
      - PLAYER_DAMAGE_RATE_ATTACK=1.000000
      - PLAYER_DAMAGE_RATE_DEFENSE=1.000000
      - PLAYER_STOMACH_DECREASE_RATE=1.000000
      - PLAYER_STAMINA_DECREACE_RATE=1.000000
      - PLAYER_AUTO_HP_REGENE_RATE=1.000000
      - PLAYER_AUTO_HP_REGENE_RATE_IN_SLEEP=1.000000
      - PAL_STOMACH_DECREACE_RATE=1.000000
      - PAL_STAMINA_DECREACE_RATE=1.000000
      - PAL_AUTO_HP_REGENE_RATE=1.000000
      - PAL_AUTO_HP_REGENE_RATE_IN_SLEEP=1.000000
      - BUILD_OBJECT_DAMAGE_RATE=1.000000
      - BUILD_OBJECT_DETERIORATION_DAMAGE_RATE=1.000000
      - COLLECTION_DROP_RATE=1.000000
      - COLLECTION_OBJECT_HP_RATE=1.000000
      - COLLECTION_OBJECT_RESPAWN_SPEED_RATE=1.000000
      - ENEMY_DROP_ITEM_RATE=1.000000
      - DEATH_PENALTY=All
      - ENABLE_PLAYER_TO_PLAYER_DAMAGE=false
      - ENABLE_FRIENDLY_FIRE=false
      - ENABLE_INVADER_ENEMY=true
      - ACTIVE_UNKO=false
      - ENABLE_AIM_ASSIST_PAD=true
      - ENABLE_AIM_ASSIST_KEYBOARD=false
      - DROP_ITEM_MAX_NUM=3000
      - DROP_ITEM_MAX_NUM_UNKO=100
      - BASE_CAMP_MAX_NUM=128
      - BASE_CAMP_WORKER_MAXNUM=15
      - DROP_ITEM_ALIVE_MAX_HOURS=1.000000 
      - AUTO_RESET_GUILD_NO_ONLINE_PLAYERS=false
      - AUTO_RESET_GUILD_TIME_NO_ONLINE_PLAYERS=72.000000
      - GUILD_PLAYER_MAX_NUM=20
      - PAL_EGG_DEFAULT_HATCHING_TIME=72.000000
      - WORK_SPEED_RATE=1.000000 
      - IS_MULTIPLAY=false
      - IS_PVP=false
      - CAN_PICKUP_OTHER_GUILD_DEATH_PENALTY_DROP=false
      - ENABLE_NON_LOGIN_PENALTY=true
      - ENABLE_FAST_TRAVEL=true
      - IS_START_LOCATION_SELECT_BY_MAP=true
      - EXIST_PLAYER_AFTER_LOGOUT=false
      - ENABLE_DEFENSE_OTHER_GUILD_PLAYER=false
      - COOP_PLAYER_MAX_NUM=4
      - MAX_PLAYERS=32
      - SERVER_NAME=jammsen-docker-generated-###RANDOM###
      - SERVER_DESCRIPTION=Palworld-Dedicated-Server running in Docker by jammsen
      - ADMIN_PASSWORD=adminPasswordHere
      - SERVER_PASSWORD=serverPasswordHere
      - PUBLIC_PORT=8211
      - PUBLIC_IP=
      - RCON_ENABLED=false
      - RCON_PORT=25575
      - REGION=
      - USEAUTH=true
      - BAN_LIST_URL=https://api.palworldgame.com/api/banlist.txt
    volumes:
      - ./game:/palworld
```

### Gameserver with RCON

```yml
version: '3.9'
services:
  palworld-dedicated-server:
    #build: .
    container_name: palworld-dedicated-server
    image: jammsen/palworld-dedicated-server:latest
    restart: unless-stopped
    ports:
      - target: 8211 # Gamerserver port inside of the container
        published: 8211 # Gamerserver port on your host
        protocol: udp
        mode: host
      - target: 25575 # RCON port inside of the container
        published: 25575 # RCON port on your host
        protocol: tcp
        mode: host
    environment:
      - TZ=Europe/Berlin # Change this for logging and backup, see "Environment-Variables" 
      - ALWAYS_UPDATE_ON_START=true
      - MULTITHREAD_ENABLED=true
      - COMMUNITY_SERVER=true
      - BACKUP_ENABLED=true
      - BACKUP_CRON_EXPRESSION=0 * * * *
      - NETSERVERMAXTICKRATE=120
      - DIFFICULTY=None
      - DAYTIME_SPEEDRATE=1.000000
      - NIGHTTIME_SPEEDRATE=1.000000
      - EXP_RATE=1.000000
      - PAL_CAPTURE_RATE=1.000000
      - PAL_SPAWN_NUM_RATE=1.000000
      - PAL_DAMAGE_RATE_ATTACK=1.000000
      - PAL_DAMAGE_RATE_DEFENSE=1.000000
      - PLAYER_DAMAGE_RATE_ATTACK=1.000000
      - PLAYER_DAMAGE_RATE_DEFENSE=1.000000
      - PLAYER_STOMACH_DECREASE_RATE=1.000000
      - PLAYER_STAMINA_DECREACE_RATE=1.000000
      - PLAYER_AUTO_HP_REGENE_RATE=1.000000
      - PLAYER_AUTO_HP_REGENE_RATE_IN_SLEEP=1.000000
      - PAL_STOMACH_DECREACE_RATE=1.000000
      - PAL_STAMINA_DECREACE_RATE=1.000000
      - PAL_AUTO_HP_REGENE_RATE=1.000000
      - PAL_AUTO_HP_REGENE_RATE_IN_SLEEP=1.000000
      - BUILD_OBJECT_DAMAGE_RATE=1.000000
      - BUILD_OBJECT_DETERIORATION_DAMAGE_RATE=1.000000
      - COLLECTION_DROP_RATE=1.000000
      - COLLECTION_OBJECT_HP_RATE=1.000000
      - COLLECTION_OBJECT_RESPAWN_SPEED_RATE=1.000000
      - ENEMY_DROP_ITEM_RATE=1.000000
      - DEATH_PENALTY=All
      - ENABLE_PLAYER_TO_PLAYER_DAMAGE=false
      - ENABLE_FRIENDLY_FIRE=false
      - ENABLE_INVADER_ENEMY=true
      - ACTIVE_UNKO=false
      - ENABLE_AIM_ASSIST_PAD=true
      - ENABLE_AIM_ASSIST_KEYBOARD=false
      - DROP_ITEM_MAX_NUM=3000
      - DROP_ITEM_MAX_NUM_UNKO=100
      - BASE_CAMP_MAX_NUM=128
      - BASE_CAMP_WORKER_MAXNUM=15
      - DROP_ITEM_ALIVE_MAX_HOURS=1.000000 
      - AUTO_RESET_GUILD_NO_ONLINE_PLAYERS=false
      - AUTO_RESET_GUILD_TIME_NO_ONLINE_PLAYERS=72.000000
      - GUILD_PLAYER_MAX_NUM=20
      - PAL_EGG_DEFAULT_HATCHING_TIME=72.000000
      - WORK_SPEED_RATE=1.000000 
      - IS_MULTIPLAY=false
      - IS_PVP=false
      - CAN_PICKUP_OTHER_GUILD_DEATH_PENALTY_DROP=false
      - ENABLE_NON_LOGIN_PENALTY=true
      - ENABLE_FAST_TRAVEL=true
      - IS_START_LOCATION_SELECT_BY_MAP=true
      - EXIST_PLAYER_AFTER_LOGOUT=false
      - ENABLE_DEFENSE_OTHER_GUILD_PLAYER=false
      - COOP_PLAYER_MAX_NUM=4
      - MAX_PLAYERS=32
      - SERVER_NAME=jammsen-docker-generated-###RANDOM###
      - SERVER_DESCRIPTION=Palworld-Dedicated-Server running in Docker by jammsen
      - ADMIN_PASSWORD=adminPasswordHere
      - SERVER_PASSWORD=serverPasswordHere
      - PUBLIC_PORT=8211
      - PUBLIC_IP=
      - RCON_ENABLED=false
      - RCON_PORT=25575
      - REGION=
      - USEAUTH=true
      - BAN_LIST_URL=https://api.palworldgame.com/api/banlist.txt
    volumes:
      - ./game:/palworld
  
  rcon:
    image: outdead/rcon:latest
    entrypoint: ["/rcon", "-a", "RCON_ADDRESS:RCON_PORT", "-p", "RCON_PASSWORD"]
    profiles: ['rcon'] 
```

*Note: The profiles defintion, prevents the container from starting with the server, this is on purpose, because of Docker-Compose's ability to run container over the CLI, after the start*

#### What do the parameters in the entrypoint for RCON mean

- "/rcon" is the command to start the RCON client
- "-a" is used to specify the address of the RCON server in the format "IP:PORT"
- "RCON_ADDRESS:RCON_PORT" should be replaced with the actual address and port of the RCON server
- "-p" is used to specify the password for the RCON server
- "RCON_PASSWORD" should be replaced with the actual RCON password

#### Run RCON commands

In your shell, you can now run commands against the gameserver via Docker-Compose and RCON
```shell
$ docker compose run --rm rcon ShowPlayers
name,playeruid,steamid
$ docker compose run --rm rcon info
Welcome to Pal Server[v0.1.3.0] jammsen-docker-generated-20384
$ docker compose run --rm rcon save
Complete Save
```
**Imporant:**
- Keep the `--rm` in the command line, or you will have many exited containers in your list. 
- All RCON-Commands can be research here: https://tech.palworldgame.com/server-commands

### Gameserver with Portainer
For Portainer it is recommended to use the Stacks feature, which allows you to deploy a stack from a docker-compose.yml file. The following configuration will allow you to use the one-click console access feature.

```yaml
version: "3.9"
services:
  palworld-dedicated-server:
    #build: .
    container_name: palworld-dedicated-server
    image: jammsen/palworld-dedicated-server:latest
    restart: unless-stopped
    ports:
      - target: 8211 # Gamerserver port inside of the container
        published: 8211 # Gamerserver port on your host
        protocol: udp
        mode: host
      - target: 25575 # RCON port inside of the container
        published: 25575 # RCON port on your host
        protocol: tcp
        mode: host
    environment:
      - TZ=Europe/Berlin # Change this for logging and backup, see "Environment-Variables" 
      - ALWAYS_UPDATE_ON_START=true
      - MULTITHREAD_ENABLED=true
      - COMMUNITY_SERVER=true
      - BACKUP_ENABLED=true
      - BACKUP_CRON_EXPRESSION=0 * * * *
      - NETSERVERMAXTICKRATE=120
      - DIFFICULTY=None
      - DAYTIME_SPEEDRATE=1.000000
      - NIGHTTIME_SPEEDRATE=1.000000
      - EXP_RATE=1.000000
      - PAL_CAPTURE_RATE=1.000000
      - PAL_SPAWN_NUM_RATE=1.000000
      - PAL_DAMAGE_RATE_ATTACK=1.000000
      - PAL_DAMAGE_RATE_DEFENSE=1.000000
      - PLAYER_DAMAGE_RATE_ATTACK=1.000000
      - PLAYER_DAMAGE_RATE_DEFENSE=1.000000
      - PLAYER_STOMACH_DECREASE_RATE=1.000000
      - PLAYER_STAMINA_DECREACE_RATE=1.000000
      - PLAYER_AUTO_HP_REGENE_RATE=1.000000
      - PLAYER_AUTO_HP_REGENE_RATE_IN_SLEEP=1.000000
      - PAL_STOMACH_DECREACE_RATE=1.000000
      - PAL_STAMINA_DECREACE_RATE=1.000000
      - PAL_AUTO_HP_REGENE_RATE=1.000000
      - PAL_AUTO_HP_REGENE_RATE_IN_SLEEP=1.000000
      - BUILD_OBJECT_DAMAGE_RATE=1.000000
      - BUILD_OBJECT_DETERIORATION_DAMAGE_RATE=1.000000
      - COLLECTION_DROP_RATE=1.000000
      - COLLECTION_OBJECT_HP_RATE=1.000000
      - COLLECTION_OBJECT_RESPAWN_SPEED_RATE=1.000000
      - ENEMY_DROP_ITEM_RATE=1.000000
      - DEATH_PENALTY=All
      - ENABLE_PLAYER_TO_PLAYER_DAMAGE=false
      - ENABLE_FRIENDLY_FIRE=false
      - ENABLE_INVADER_ENEMY=true
      - ACTIVE_UNKO=false
      - ENABLE_AIM_ASSIST_PAD=true
      - ENABLE_AIM_ASSIST_KEYBOARD=false
      - DROP_ITEM_MAX_NUM=3000
      - DROP_ITEM_MAX_NUM_UNKO=100
      - BASE_CAMP_MAX_NUM=128
      - BASE_CAMP_WORKER_MAXNUM=15
      - DROP_ITEM_ALIVE_MAX_HOURS=1.000000 
      - AUTO_RESET_GUILD_NO_ONLINE_PLAYERS=false
      - AUTO_RESET_GUILD_TIME_NO_ONLINE_PLAYERS=72.000000
      - GUILD_PLAYER_MAX_NUM=20
      - PAL_EGG_DEFAULT_HATCHING_TIME=72.000000
      - WORK_SPEED_RATE=1.000000 
      - IS_MULTIPLAY=false
      - IS_PVP=false
      - CAN_PICKUP_OTHER_GUILD_DEATH_PENALTY_DROP=false
      - ENABLE_NON_LOGIN_PENALTY=true
      - ENABLE_FAST_TRAVEL=true
      - IS_START_LOCATION_SELECT_BY_MAP=true
      - EXIST_PLAYER_AFTER_LOGOUT=false
      - ENABLE_DEFENSE_OTHER_GUILD_PLAYER=false
      - COOP_PLAYER_MAX_NUM=4
      - MAX_PLAYERS=32
      - SERVER_NAME=jammsen-docker-generated-###RANDOM###
      - SERVER_DESCRIPTION=Palworld-Dedicated-Server running in Docker by jammsen
      - ADMIN_PASSWORD=adminPasswordHere
      - SERVER_PASSWORD=serverPasswordHere
      - PUBLIC_PORT=8211
      - PUBLIC_IP=
      - RCON_ENABLED=false
      - RCON_PORT=25575
      - REGION=
      - USEAUTH=true
      - BAN_LIST_URL=https://api.palworldgame.com/api/banlist.txt
    volumes:
      - /path/to/your/game/directory:/palworld

  rcon:
    image: outdead/rcon:latest
    container_name: palworld-rcon
    restart: unless-stopped
    entrypoint: ["/rcon", "-a", "RCON_ADDRESS:RCON_PORT", "-p", "RCON_PASSWORD"]
    tty: true
    stdin_open: true
    depends_on:
      - palworld-dedicated-server
```
Questions? See [What do the parameters in the entrypoint for RCON mean](#what-do-the-parameters-in-the-entrypoint-for-rcon-mean)



## FAQ

### How can i look into the config of my Palworld container?
You can run this `docker exec -ti palworld-dedicated-server cat /palworld/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini` and it will show you the config inside the container.

### Im seeing S_API errors in my logs when i start the container
Errors like `[S_API FAIL] Tried to access Steam interface SteamUser021 before SteamAPI_Init succeeded.` are safe to ignore.

## Planned features in the future

- Feel free to suggest something

## Software used

- CM2Network SteamCMD - Debian-based (Officially recommended by Valve - https://developer.valvesoftware.com/wiki/SteamCMD#Docker)
- Supercronic - https://github.com/aptible/supercronic
- Palworld Dedicated Server (APP-ID: 2394010 - https://steamdb.info/app/2394010/config/)
