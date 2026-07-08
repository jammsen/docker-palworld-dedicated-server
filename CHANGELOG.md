# Changelog

[Back to main](README.md#changelog)

## 2026-07-04

- Added SteamCMD self-healing via `run_steamcmd` helper in `includes/server.sh` - by @jammsen
  - All SteamCMD calls (fresh install, update, update+validate) now retry up to 3 times on failure
  - On each failure SteamCMD's self-update state (`steamcmd/package`) is cleared, fixing the misleading "Steamcmd needs to be online to update" crash-loop caused by corrupt update state persisting in the container's writable layer across `restart: always`
  - After 3 failed attempts the container exits with a clear error message and lets the Docker restart policy retry with pre-cleaned state

## 2026-06-19

> [!WARNING]
> **Breaking change!** This release removes RCON support entirely and replaces it with the Palworld REST API.
> - Update your `default.env`: rename `RCON_PLAYER_DETECTION_ENABLED` → `PLAYER_DETECTION_ENABLED`, `RCON_PLAYER_DETECTION_DEBUG` → `PLAYER_DETECTION_DEBUG`, `RCON_PLAYER_DETECTION_STARTUP_DELAY` → `PLAYER_DETECTION_STARTUP_DELAY`, `RCON_PLAYER_DETECTION_CHECK_INTERVAL` → `PLAYER_DETECTION_CHECK_INTERVAL`. Add `RESTAPI_TIMEOUT=10`.
> - Update your `compose.yml`: remove the `25575/tcp` RCON port mapping if present.
> - Ensure `RESTAPI_ENABLED=true` and `RESTAPI_PORT=8212` are set.

- Replaced deprecated RCON/gorcon tooling with the Palworld REST API - by @jammsen (closes #308)
  - Removed `gorcon` Go binary and multi-stage Docker build stage
  - Removed `includes/rcon.sh`, `scripts/rconcli.sh`, `configs/rcon.yaml`
  - Added `includes/restapi.sh`: transport-layer library (`restapi_get`, `restapi_post`) and all semantic broadcast/save/shutdown helpers
  - Added `scripts/restapicli.sh`: user-facing CLI, symlinked to `/usr/local/bin/restapicli`; commands: `info`, `players`, `metrics`, `save`, `announce`, `kick`, `ban`, `unban`, `banlist`, `shutdown`
  - Rewrote `includes/playerdetection.sh`: player state stored as compact JSON objects, all field extraction via `jq`, Unicode player names fully supported
  - Added `jq` as runtime dependency for JSON parsing
  - Renamed `RCON_PLAYER_*` environment variables to `PLAYER_DETECTION_*`
  - Added `RESTAPI_TIMEOUT` environment variable
  - Removed RCON port (`25575/tcp`) from Docker `EXPOSE` and compose examples
  - Changed `RCON_ENABLED` default to `false` in Dockerfile and `default.env` — RCON is deprecated by Pocketpair; the setting only affects the game server INI, not container tooling
  - Fixed player name sanitization: strips only ASCII control characters, backslash and double-quote, preserving Chinese/Japanese/Unicode characters
  - Added player moderation commands to `restapicli`: `kick`, `ban`, `unban` (via REST API), `banlist` (reads local ban file from disk — no REST API needed)
  - Fixed typos in `backupmanager.sh` output strings (`out of backup N file(s)` → `out of N backup file(s)`, `backups(s)` → `backup(s)`)
  - Fixed `-user` → `--user` in README backup manager examples
  - Updated `docs/ENV_VARS.md`, `README.md`, and `default.env` accordingly

## 2026-05-23

- gosu from 1.17 to 1.19 and supercronic from 0.2.34 to 0.2.45 - by @jammsen (#312)
- Updated docker-image pinning and github-actions versions by @jammsen (#312)
- Refactored from docker-compose.yml to new standard compose.yml including gitignore by @jammsen (#312)
- Implemented finally a version of auto-updating the compose.yml @jahusa02 (#188)
- Added the function to run a custom script, that the user can place at /palworld/custom-script - Off by default, completely opt-in and added a very explicit PSA in the README.md for it by @jammsen for @Jadiction (#273)

## 2025-09-06

- Made envsubst integration complete and useful, added strtolower checks, removed obsolete moreutils package from PR,  removed trailing spaces, added more error-fallbacks in config.sh around the envsubst integration - by @jammsen (idea by @codebam) (#311)

## 2025-07-18

- Updated supercronic to release v0.2.34 @GlitchApotamus (#304)

## 2025-07-17

- Added new config-settings for v0.6.0 @GlitchApotamus  (#301)
- Added different mechanics for ci/cd pipeline unit-tests and timeouts for PRs

## 2025-03-22

- Added complete coverage of new v0.4.0 and v0.5.0 variable changes @jammsen (#294)
- Added counter for all settings in the log, we are now at 87 gameserver settings, this makes logging and searching easier, also debugging in issues

## 2025-03-20

- Adding first part of new v0.5.0 changes @jammsen (#294)

## 2025-01-29

- Added unit-tests (Thanks to @thijsvanloef for the base) @jammsen (#291)

## 2025-01-14

- Fixed Player detection loop bug @jammsen (#287)

## 2025-01-11

- Fixed startup script failure if missing appmanifest @holysoles (#288)

## 2024-12-23

- Added new configs for Palworld: Feybreak @jammsen (#283)

## 2024-09-20

- Added process-based Healthcheck @jammsen (#275)

## 2024-08-15

- Added support for variable SUPPLY_DROP_SPAN @KyleDiao (#279)

## 2024-08-12

- Added support to turn off backup-announcements, to have less spammy chat ingame, but errors will always be announced @Jadiction @jammsen (#272)

## 2024-06-24

- Added support for new variables @jammsen (#276)

## 2024-06-24

- Add support-documentation for Xbox-Dedicated-Servers @jammsen (#269)

## 2024-04-28

- Log-Rotation by @Gornoka (#261)
- Throw error when not run as root by @StaleLoafOfBread (#246)
- Minimise user write access to container service file @Callum027 (#241)

## 2024-04-09

- Exclude save backup directory in backup @Dashboy1998  (#259)

## 2024-04-06

- Disabled recursive Backups by default @Callum027 (#257)

## 2024-04-04

- Fixed rcon-spaces by @Callum027 (#251)
- Added new config options from new default-settings-file
- Bugfix - Change pidof selector to current name "PalServer-Linux-Shipping" by @thijsvanloef 

## 2024-03-04

- Fixed typo
- Removed 0.1.5.0 -rcon workaround
- Cleanup code
- No default.env update needed, just update image, down and up and your good

## 2024-02-27

- Added clearer descriptions in the ENV_VARS documentation by @m1xzg
- Added new mechanic to comply with changes for update 0.1.5.0 by @jammsen and @Callum027 (#236)
  - Introduced new template file for PalWorldSettings.ini
  - Added new option for ShowPlayerList
  - Updated option for Community-Mode servers

## 2024-02-25

- Added new mechanic for customization of webhook content-titles (#223)

## 2024-02-24

- Added new mechanic for auto-restart, where the player count will be checked, 15 minutes grace-period (for dungeons, boss-fights, etc.) will only used if a player is online, if not the restart will be initiated (#230)
  - Renamed/extended webhook messages accordingly

## 2024-02-23

- Added new SERVER_SETTINGS_MODE called "rcononly" this will only setup up RCON, everything else is still manually to set (#221)
- Added RESTART_DEBUG_OVERRIDE for local testing
- Fixed expansion-bug from #224 & #225 by @Dashboy1998
- Refactoring of code-duplication in webhook.sh
- Extended fixing for edge-cases of playernames from #226, #227 & #228 by @Dashboy1998
  - Default mechanic checks more steamid oriented, not comparing playernames directly
  - Added mechanic for playername changes and temporary characters which are still in char-creation screen
  - Also cut down on text in the announces on RCON, because messages can only be 40 chars long
  - Stripped all special-chars from playername, using TR class [:alnum:] meaning only a-zA-z0-9 are valid

## 2024-02-22

- Added RCON-Based player detection, for join and leave messages on console, rcon-broadcast and webhooks (#216)
  - Important change: RCON is now on by default, was false in the Dockerfile before, not considered a breaking change

## 2024-02-21

- Fixed major CVEs and added re-compiled gosu-amd64 binary to the repository (#214 #215)

## 2024-02-19

- Added 15 seconds delay after save before backup (#209)
- Changed standard RESTART_CRON_EXPRESSION to only once a day at 6pm
  - Cause less illnesses on Pals that way

## 2024-02-13

- Added the option to enable webhook curl debugging for weird error edge-cases

## 2024-02-13
- **Breaking changes:** 
  - Changed the default BACKUP_RETENTION_POLICY to true and changed BACKUP_RETENTION_AMOUNT_TO_KEEP to 72, meaning 3 days worth of backup are kept in the default configuration
  - Added the ability to change the PUID and PGID via environment variables (#117)
    - This includes a user-process-jail mechanic including entrypoint-script, which makes sure that the gameserver is always working with the right permissions as only user steam and not root by accident or bug 
- Mayor refactoring of the code-base to enable more feature requests based around automatic restarts and such. This includes:
  - Adding new backupmanager
  - Adding color-based echos and feedback-signals by color
  - New structure and comments of Dockerfile environment variables
  - New structure and comments of default.env template
  - Added shell linting
  - Fixed cron duplication (#169)
  - Changed structure of the project and where files like documentation, includes, scripts and config-templates are to find
  - Fixed typos in various documents
  - Added multicore-bugfix, now multi-core-enhancment should be working (#190)
  - Removed sensitive information from the servermanger logs (#194)
  - Changed to always copy DefaultPalWorldSettings.ini at start mechanic (#195)
  - Updated outdated Pocketpair documentation links
  - Added automatic-restart-cron functionality (#50 #71 #139)
  - Extended webhook usage (#120)
- Requirements - What you need to do:
  - **Read the readme, a lot has changed, there is a new part about the backupmanager and how to interact now with rconcli**
  - Update to latest image
  - Download new docker-compose.yml and new default.env
    - Merge your settings and make sure that backup-settings, PGID and PUID are right

## 2024-02-03

- Added changes to shutdown-webhook notifications (#120)
- Added rcon.sh again for having alias function calls that do not bloat the servermanager
- Refactored how webhook messages function are called and added alias functions
- Added a changelog, from various request resources

[Back to main](README.md#changelog)
