## Docker - Palworld Dedicated Server

[![Build Docker Image](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push.yml/badge.svg)](https://github.com/jammsen/docker-palworld-dedicated-server/actions/workflows/docker-build-and-push.yml)
![Docker Pulls](https://img.shields.io/docker/pulls/jammsen/palworld-dedicated-server)
![Docker Stars](https://img.shields.io/docker/stars/jammsen/palworld-dedicated-server)
![Image Size](https://img.shields.io/docker/image-size/jammsen/palworld-dedicated-server/latest)

This includes a Palworld Dedicated Server based on Linux and Docker.

## Do you need support for this Docker Image

- What to do?
  - Feel free to create a NEW issue
    - It is okay to "reference" that you might have the same problem as the person in issue #number
  - Follow the instructions and answer the questions of people who are willing to help you
  - If your issue is done, close it
    - I will Inactivity-Close any issue thats not been active for a week
- What NOT to do?
  - Dont re-use issues / Necro!
    - You are most likely to chat/spam/harrass thoose participants who didnt agree to be part of your / a new problem and might be totally out of context!
  - If this happens, i reserve the rights to lock the issue or delete the comments, you have been warned!

## What you need to run this

- Basic understanding of Docker, Docker-Compose, Linux and Networking (Port-Forwarding/NAT)

## Getting started

1. Create `game` sub-directories on your Dockernode in your game-server-directory (`/srv/palworld`) and give it with `chmod 777 game` full permissions or use `chown -R 1000:1000 game/`.
2. Setup Port-Forwarding or NAT for the ports in the Docker-Compose file
3. (Build if needed )Start via `docker-compose up -d` - See docker-compose.yml and next section for more infos
4. After first start, stop the server, setup your config at `game/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini` and start it again

## Environment-Variables
| Variable               | Describe                                                                                          | Default Value | Allowed Value |
| ---------------------- | ------------------------------------------------------------------------------------------------- | ------------- | ------------- |
| ALWAYS_UPDATE_ON_START | Updates the server on startup                                                                     | true          | false/true    |
| GAME_PORT              | Game port of the server                                                                           | 8211          | 1024-65535    |
| MAX_PLAYERS            | Maximum amout of players                                                                          | 32            | 1-32          |
| MULTITHREAD_ENABLED    | Sets options for "Improved multi-threaded CPU performance"                                        | true          | false/true    |
| COMMUNITY_SERVER       | Sets the server to a "Community-Server", will appear in the list. Needs PUBLIC_IP and PUBLIC_PORT | false         | false/true    |
| PUBLIC_IP              | Public ip, auto-detect if not specified, see COMMUNITY_SERVER                                     | false         | ip address    |
| PUBLIC_PORT            | Public port, auto-detect if not specified, see COMMUNITY_SERVER                                   | false         | 1024-65535    |

Look at https://tech.palworldgame.com/optimize-game-balance for more information and config-settings in `game/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini`

## Planned features in the future

- Feel free to suggest something

## Software used

- CM2Network SteamCMD (Officially recommended by Valve - https://developer.valvesoftware.com/wiki/SteamCMD#Docker) 
- Palworld Dedicated Server (APP-ID: 2394010 - https://steamdb.info/app/2394010/config/)
