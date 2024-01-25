# Docker - Palworld Dedicated Server

[![Build Docker Image](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push.yml/badge.svg)](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push.yml)
![Docker Pulls](https://img.shields.io/docker/pulls/jammsen/palworld-dedicated-server)
![Docker Stars](https://img.shields.io/docker/stars/jammsen/palworld-dedicated-server)
![Image Size](https://img.shields.io/docker/image-size/jammsen/palworld-dedicated-server/latest)

This includes a Palworld Dedicated Server based on Linux and Docker.

___

## Overview

* [Do you need support for this Docker Image](#do-you-need-support-for-this-docker-image)
* [What you need to run this](#what-you-need-to-run-this)
* [Getting started](#getting-started)
* [Environment-Variables](#environment-variables)
  * [Container-Settings](#container-settings)
    * [TZ identifiers](#tz-identifiers)
    * [Cron expression](#cron-expression)  
  * [Gameserver-Settings](#gameserver-settings)
* [Docker-Compose examples](#docker-compose-examples)
  * [Standalone gameserver](#standalone-gameserver)
  * [Gameserver with RCON](#gameserver-with-rcon)
  * [Run RCON commands](#run-rcon-commands)
* [FAQ](#faq)
* [Planned features in the future](#planned-features-in-the-future)
* [Software used](#software-used)

## Do you need support for this Docker Image

- What to do?
  - Feel free to create a NEW issue
    - It is okay to "reference" that you might have the same problem as the person in issue #number
  - Follow the instructions and answer the questions of people who are willing to help you
  - If your issue is done, close it and please consider giving this repo and the [Docker-Hub repository](https://hub.docker.com/repository/docker/jammsen/palworld-dedicated-server) a star
    - I will Inactivity-Close any issue thats not been active for a week
- What NOT to do?
  - Dont re-use issues / Dont necro!
    - You are most likely to chat/spam/harrass thoose participants who didnt agree to be part of your / a new problem and might be totally out of context!
  - If this happens, i reserve the rights to lock the issue or delete the comments, you have been warned!

## What you need to run this

- Basic understanding of Docker, Docker-Compose, Linux and Networking (Port-Forwarding/NAT)

## Getting started

1. Create a `game` sub-directories on your Dockernode in your game-server-directory (Example: `/srv/palworld`) and give it with `chmod 777 game` full permissions or use `chown -R 1000:1000 game/`.
2. Setup Port-Forwarding or NAT for the ports in the Docker-Compose file
3. Pull the latest version of the image with `docker pull jammsen/palworld-dedicated-server:latest` 
4. Setup your own docker-compose.yml just how you like it - Look into the [Docker-Compose examples](#examples) section and the [Environment-Variables](#examples) section for more information 
5. Start the container via `docker-compose up -d && docker-compose logs -f` and watch the log, if no errors occur you can close the logs with ctrl+c 
6. Happy gaming!

## Environment-Variables

**Imporant:** In this section you will find a lot of environment variables to control your container-behavior and gameserver-settings. But because of a lot of control, there comes a lot of settings, so this is split into 2 parts for documentation. First comes **Container-Settings** and second **Gamesserver-Settings**.

### Container-Settings

| Variable               | Description                                                         | Default value                  | Allowed value                         |
| ---------------------- | ------------------------------------------------------------------- | ------------------------------ | ------------------------------------- |
| TZ                     | Timezone used for time stamping server backups                      | Europe/Berlin                  | See [TZ identifiers](#tz-identifiers) |
| ALWAYS_UPDATE_ON_START | Updates the server on startup                                       | true                           | false/true                            |
| MULTITHREAD_ENABLED    | Sets options for "Improved multi-threaded CPU performance"          | true                           | false/true                            |
| COMMUNITY_SERVER       | Set to enabled, the server will appear in the Community-Serverlist. | true                           | false/true                            |
| RCON_ENABLED           | RCON function - Use ADMIN_PASSWORD to login                         | true                           | false/true                            |
| BACKUP_ENABLED         | Backup function, creates backups in your `game` directory           | true                           | false/true                            |
| BACKUP_CRON_EXPRESSION | Needs a Cron-Expression - See [Cron expression](#cron-expression)   | 0 * * * * (meaning every hour) | Cron-Expression                       |

#### TZ identifiers

This setting affects logging output and the backup function. [TZ identifiers](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#Time_Zone_abbreviations) are format of defining a timezone near you. 

#### Cron expression

This setting affects the backup function. In a Cron-Expression you define an interval for jobs to run. This image uses Supercronic for crons, see https://github.com/aptible/supercronic#crontab-format or https://crontab-generator.org

### Gameserver-Settings

This is a list of all the settings currently adjustable via Docker environment variables, based on the **order** and **contents of the DefaultPalWorldSettings.ini**

Information-sources and credits to the following websites:
* [Palworld Tech Guide](https://tech.palworldgame.com/optimize-game-balance) for the gameserver documentation
* [PalworldSettingGenerator](https://dysoncheng.github.io/PalWorldSettingGenerator/setting.html) for variable descriptions

**Imporant:** Please note that all of this is subject to change. **The game is still in early access.**

| Variable                                  | Game setting                         | Description                                                                                                                                                       | Default Value                                          | Allowed Value |
| ----------------------------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ | ------------- |
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
| PUBLIC_IP                                 | public ip                            | Public IP                                                                                                                                                         |                                                        | String        |
| RCON_ENABLED                              | RCONEnabled                          | Enable RCON                                                                                                                                                       | false                                                  | Boolean       |
| RCON_PORT                                 | RCONPort                             | Port number for RCON                                                                                                                                              | 25575                                                  | Integer       |
| REGION                                    | Region                               | Area                                                                                                                                                              |                                                        | String        |
| USEAUTH                                   | bUseAuth                             | Use authentication                                                                                                                                                | true                                                   | Boolean       |
| BAN_LIST_URL                              | BanListURL                           | Which ban list to use                                                                                                                                             | https://api.palworldgame.com/api/banlist.txt           | String        |

## Docker-Compose examples

### Standalone gameserver

```yml
version: '3.9'
services:
  palworld-dedicated-server:
    #build: .
    container_name: palworld-dedicated-server
    image: jammsen/palworld-dedicated-server:latest
    restart: always
    network_mode: bridge
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
      - MAX_PLAYERS=32
      - MULTITHREAD_ENABLED=true
      - COMMUNITY_SERVER=true
      - RCON_ENABLED=true
      - RCON_PORT=25575
      - PUBLIC_IP=10.0.0.5
      - PUBLIC_PORT=8211
      - SERVER_NAME=jammsen-docker-generated-###RANDOM###
      - SERVER_DESCRIPTION=Palworld-Dedicated-Server running in Docker by jammsen
      - SERVER_PASSWORD=serverPasswordHere
      - ADMIN_PASSWORD=adminPasswordHere
      - BACKUP_ENABLED=true
      - BACKUP_CRON_EXPRESSION=0 * * * *
      - TZ=UTC
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
    restart: always
    network_mode: bridge
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
      - MAX_PLAYERS=32
      - MULTITHREAD_ENABLED=true
      - COMMUNITY_SERVER=true
      - RCON_ENABLED=true
      - RCON_PORT=25575
      - PUBLIC_IP=10.0.0.5
      - PUBLIC_PORT=8211
      - SERVER_NAME=jammsen-docker-generated-###RANDOM###
      - SERVER_DESCRIPTION=Palworld-Dedicated-Server running in Docker by jammsen
      - SERVER_PASSWORD=serverPasswordHere
      - ADMIN_PASSWORD=adminPasswordHere
      - BACKUP_ENABLED=true
      - BACKUP_CRON_EXPRESSION=0 * * * *
      - TZ=UTC
    volumes:
      - ./game:/palworld
  
  rcon:
    image: outdead/rcon:latest
    entrypoint: ['/rcon', '-a', '10.0.0.5:25575', '-p', 'adminPasswordHere']
    profiles: ['rcon'] 
```

*Note: The profiles defintion, prevents the container from starting with the server, this is on purpose, because of Docker-Compose's ability to run container over the CLI, after the start*

#### Run RCON commands

In your shell, you can now run commands against the gameserver via Docker-Compose and RCON
```shell
$ docker compose run --rm rcon ShowPlayers
name,playeruid,steamid
$ docker compose run --rm rcon info
Welcome to Pal Server[v0.1.2.0] jammsen-docker-generated-20384
$ docker compose run --rm rcon save
Complete Save
```
**Imporant:**
- Keep the `--rm` in the command line, or you will have many exited containers in your list. 
- All RCON-Commands can be research here: https://tech.palworldgame.com/server-commands

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
