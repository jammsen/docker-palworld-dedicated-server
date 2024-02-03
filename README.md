# Docker - Palworld Dedicated Server

[![Build-Status master](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push-prod.yml/badge.svg)](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push-prod.yml)
[![Build-Status develop](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push-develop.yml/badge.svg)](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push-develop.yml)
![Docker Pulls](https://img.shields.io/docker/pulls/jammsen/palworld-dedicated-server)
![Docker Stars](https://img.shields.io/docker/stars/jammsen/palworld-dedicated-server)
![Image Size](https://img.shields.io/docker/image-size/jammsen/palworld-dedicated-server/latest)
[![Discord](https://img.shields.io/discord/532141442731212810?logo=discord&label=Discord&link=https%3A%2F%2Fdiscord.gg%2F7tacb9Q6tj)](https://discord.gg/7tacb9Q6tj)

> [!TIP]
> Do you want to chat with the community?
>
> **[Join us on Discord](https://discord.gg/7tacb9Q6tj)**

This Docker image includes a Palworld Dedicated Server based on Linux and Docker.

___

## Table of Contents

- [Docker - Palworld Dedicated Server](#docker---palworld-dedicated-server)
  - [Table of Contents](#table-of-contents)
  - [How to ask for support for this Docker image](#how-to-ask-for-support-for-this-docker-image)
  - [Requirements](#requirements)
  - [Minimum system requirements](#minimum-system-requirements)
  - [Getting started](#getting-started)
  - [Environment variables](#environment-variables)
  - [Docker-Compose examples](#docker-compose-examples)
    - [Gameserver with RCON-CLI-Tool](#gameserver-with-rcon-cli-tool)
  - [Run RCON commands](#run-rcon-commands)
  - [Backup Manager](#backup-manager)
  - [Webhook integration](#webhook-integration)
    - [Supported events](#supported-events)
  - [Deploy with Helm](#deploy-with-helm)
  - [FAQ](#faq)
    - [How can I use the interactive console in Portainer with this image?](#how-can-i-use-the-interactive-console-in-portainer-with-this-image)
    - [How can I look into the config of my Palworld container?](#how-can-i-look-into-the-config-of-my-palworld-container)
    - [I'm seeing S\_API errors in my logs when I start the container?](#im-seeing-s_api-errors-in-my-logs-when-i-start-the-container)
    - [I'm using Apple silicon type of hardware, can I run this?](#im-using-apple-silicon-type-of-hardware-can-i-run-this)
    - [I changed the `BaseCampWorkerMaxNum` setting, why didn't this update the server?](#i-changed-the-basecampworkermaxnum-setting-why-didnt-this-update-the-server)
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

## Getting started

1. Create a `game` sub-directory on your Docker-Node in your game-server-directory (Example: `/srv/palworld`).
   - This directory will be used to store the game server files, including configs and savegames.
2. Set up Port-Forwarding or NAT for the ports in the Docker-Compose file.
3. Pull the latest version of the image with:

    ```shell
    docker pull jammsen/palworld-dedicated-server:latest
    ```

4. Download the [docker-compose.yml](docker-compose.yml) and [default.env](default.env).
5. Set up the `docker-compose.yml` and `default.env` to your liking.
   - Refer to the [Environment-Variables](#environment-variables) section for more information.
6. Start the container with:

    ```shell
    docker-compose up -d && docker-compose logs -f
    ```

   - Watch the log. If no errors occur, you can close the logs with `ctrl+c`.
7. Now have fun and happy gaming! 🎮😉

## Environment variables

See [this file](/docs/ENV_VARS.md.md) for the documentation

## Docker-Compose examples

### Gameserver with RCON-CLI-Tool

See [example docker-compose.yml](docker-compose.yml).

## Run RCON commands

Open a shell into your container via `docker exec -ti palworld-dedicated-server bash`, then you can run commands against the gameserver via the command `rconcli`

```shell
$:~/steamcmd$ rconcli showplayers
name,playeruid,steamid
$:~/steamcmd$ rconcli info
Welcome to Pal Server[v0.1.3.0] jammsen-docker-generated-20384
$:~/steamcmd$ rconcli save
Complete Save
```

You can also use `docker exec palworld-dedicated-server rconcli <command>` right on your terminal/shell.

```shell
$ docker exec palworld-dedicated-server rconcli showplayers
name,playeruid,steamid

$ docker exec palworld-dedicated-server rconcli info
Welcome to Pal Server[v0.1.3.0] jammsen-docker-generated-20384

$ docker exec palworld-dedicated-server rconcli save
Complete Save
```

> **Important:** Please research the RCON-Commands on the official source: https://tech.palworldgame.com/server-commands

## Backup Manager

Usage: `docker exec palworld-dedicated-server backup [command] [arguments]`

| Command | Argument           | Required/Optional | Default Value                     | Values           | Description                                                                                                                                                                          |
| ------- | ------------------ | ----------------- | --------------------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| create  | N/A                | N/A               | N/A                               | N/A              | Creates a backup.                                                                                                                                                                    |
| list    | `<number_to_list>` | Optional          | N/A                               | Positive numbers | Lists all backups.<br>If `<number_to_list>` is specified, only the most<br>recent `<number_to_list>` backups are listed.                                                             |
| clean   | `<number_to_keep>` | Optional          | `BACKUP_RETENTION_AMOUNT_TO_KEEP` | Positive numbers | Cleans up backups.<br>If `<number_to_list>` is specified, cleans and keeps<br>the most recent`<number_to_keep>` backups.<br>If not, default to `BACKUP_RETENTION_AMOUNT_TO_KEEP` var |

Examples:

```shell
$ docker exec palworld-dedicated-server backup
>> Backup 'saved-20240203_032855.tar.gz' created successfully.
```

```shell
$ docker exec palworld-dedicated-server backup list
>> Listing 2 backup file(s)!
2024-02-03 03:28:55 | saved-20240203_032855.tar.gz
2024-02-03 03:28:00 | saved-20240203_032800.tar.gz
```

```shell
$ docker exec palworld-dedicated-server backup_clean 3
>> 1 backup(s) cleaned, keeping 2 backups(s).
```

```shell
$ docker exec palworld-dedicated-server backup_list   
>> Listing 1 out of backup 2 file(s).
2024-02-03 03:30:00 | saved-20240203_033000.tar.gz
```

> [!WARNING]
> If RCON is disabled, the backup manager won't do saves via RCON before creating a backup.
> This means that the backup will be created from the last auto-save of the server.
> This can lead to data-loss and/or savegame corruption.
>
> **Recommendation:** Please make sure that RCON is enabled before using the backup manager.

## Webhook integration

To enable webhook integration, you need to set the following environment variables in the `default.env`:

```shell
WEBHOOK_ENABLED=true
WEBHOOK_URL="https://your.webhook.url"
```

After that the server should send messages in a Discord-Compatible way to your webhook.

### Supported events

- Server starting
- Server stopped

## Deploy with Helm

A Helm chart to deploy this container can be found at [palworld-helm](https://github.com/caleb-devops/palworld-helm).

## FAQ

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
> Adding `WorldOption.sav` will break `PalWorldSetting.ini`. So any new changes to the settings (either on the file or via ENV VARS), you will have to create a new `WorldOption.sav` and update it everytime for those changes to have effect.

## Planned features in the future

- Feel free to suggest something

## Software used

- CM2Network SteamCMD - Debian-based (Officially recommended by Valve - https://developer.valvesoftware.com/wiki/SteamCMD#Docker)
- Supercronic - https://github.com/aptible/supercronic
- rcon-cli - https://github.com/gorcon/rcon-cli
- Palworld Dedicated Server (APP-ID: 2394010 - https://steamdb.info/app/2394010/config/)
