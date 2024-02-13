# shellcheck disable=SC2148

# Start supercronic and load crons
function setup_crons() {
    echo "" > cronlist    
    ei ">>> Adding crons to Supercronic"
    if [[ -n ${BACKUP_ENABLED} ]] && [[ ${BACKUP_ENABLED} == "true" ]]; then
        echo "${BACKUP_CRON_EXPRESSION} backup create" >> cronlist
        e "> Added backup cron"
    fi
    if [[ -n ${RESTART_ENABLED} ]] && [[ ${RESTART_ENABLED} == "true" ]]; then
        echo "${RESTART_CRON_EXPRESSION} restart" >> cronlist
        e "> Added restart cron"
    fi
    /usr/local/bin/supercronic -passthrough-logs cronlist &
    es ">>> Supercronic started"
}
