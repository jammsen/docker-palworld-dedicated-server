# shellcheck disable=SC2148

# Start supercronic and load crons
function setup_crons() {
    echo "" > cronlist    
    if [[ -n ${BACKUP_ENABLED} ]] && [[ ${BACKUP_ENABLED} == "true" ]]; then
        echo "${BACKUP_CRON_EXPRESSION} backup create" >> cronlist
    fi
    /usr/local/bin/supercronic -passthrough-logs cronlist &
    e "> Supercronic started"
}
