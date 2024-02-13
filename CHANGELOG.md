# Changelog

[Back to main](README.md#changelog)

## 2024-02-13
* **Breaking changes:** 
  * Changed the default BACKUP_RETENTION_POLICY to true and changed BACKUP_RETENTION_AMOUNT_TO_KEEP to 72, meaning 3 days worth of backup are kept in the default configuration
  * Added the ability to change the PUID and PGID via environment variables (#117)
    * This includes a user-process-jail mechanic including entrypoint-script, which makes sure that the gameserver is always working with the right permissions as only user steam and not root by accident or bug 
* Mayor refactoring of the code-base to enable more feature requests based around automatic restarts and such. This includes:
  * Adding new backupmanager
  * Adding color-based echos and feedback-signals by color
  * New structure and comments of Dockerfile environment variables
  * New structure and comments of default.env template
  * Added shell linting
  * Fixed cron duplication (#169)
  * Changed structure of the project and where files like documentation, includes, scripts and config-templates are to find
  * Fixed typos in various documents
  * Added multicore-bugfix, now multi-core-enhancment should be working (#190)
  * Removed sensitive information from the servermanger logs (#194)
  * Changed to always copy DefaultPalWorldSettings.ini at start mechanic (#195)
  * Updated outdated Pocketpair documentation links
  * Added automatic-restart-cron functionality (#50 #71 #139)
  * Extended webhook usage (#120)
* Requirements - What you need to do:
  * **Read the readme, a lot has changed, there is a new part about the backupmanager and how to interact now with rconcli**
  * Update to latest image
  * Download new docker-compose.yml and new default.env
    * Merge your settings and make sure that backup-settings, PGID and PUID are right

## 2024-02-03

* Added changes to shutdown-webhook notifications (#120)
* Added rcon.sh again for having alias function calls that do not bloat the servermanager
* Refactored how webhook messages function are called and added alias functions
* Added a changelog, from various request resources

[Back to main](README.md#changelog)
