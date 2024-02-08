# shellcheck disable=SC2148
# Function to start supercronic and load crons from cronlist
function setup_crons() {
    echo "" > cronlist    
    if [[ -n ${BACKUP_ENABLED} ]] && [[ ${BACKUP_ENABLED} == "true" ]]; then
        echo "${BACKUP_CRON_EXPRESSION} backupmanager --create" >> cronlist
    fi

    /usr/local/bin/supercronic -passthrough-logs cronlist &

    es ">>> Supercronic started"
}
