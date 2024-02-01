# shellcheck disable=SC2148
# Function to start supercronic and load crons from cronlist
function setup_crons() {
    touch cronlist
    if [[ -n ${BACKUP_ENABLED} ]] && [[ ${BACKUP_ENABLED} == "true" ]]; then
        echo "${BACKUP_CRON_EXPRESSION} backup_manager --create > /dev/null 2>&1" >> cronlist
    fi
    if [[ -n ${BACKUP_RETENTION_POLICY} ]] && [[ ${BACKUP_RETENTION_POLICY} == "true" ]]; then
        echo "${BACKUP_CRON_EXPRESSION} backup_manager --clean > /dev/null 2>&1" >> cronlist
    fi

    (sleep 150 && /usr/local/bin/supercronic cronlist) &
}
