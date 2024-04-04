# Changelog

[Back to main](README.md#changelog)

## 2024-04-04

- Fixed rcon-spaces from @Callum027 (#251)
- Added new config options from new default-settings-file


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
