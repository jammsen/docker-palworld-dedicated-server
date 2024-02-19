#!/bin/bash
# shellcheck disable=SC1091,SC2012,SC2004

source /includes/colors.sh
source /includes/rcon.sh

# Default values if the environment variables exist
LOCAL_BACKUP_PATH=${BACKUP_PATH} # Directory where the backup files are stored
LOCAL_GAME_PATH=${GAME_PATH} # Directory where the game save files are stored
LOCAL_GAME_SAVE_PATH=${GAME_SAVE_PATH} # Directory where the game save files are stored
LOCAL_BACKUP_RETENTION_POLICY=${BACKUP_RETENTION_POLICY} # Number of backup files to keep
LOCAL_BACKUP_RETENTION_AMOUNT_TO_KEEP=${BACKUP_RETENTION_AMOUNT_TO_KEEP} # Number of backup files to keep

function print_usage() {
    script_name=$(basename "$0")
    echo "Usage:"
    echo "  ${script_name} create"
    echo "  ${script_name} list [number_of_entries]"
    echo "  ${script_name} clean [number_to_keep]"
    echo "  ${script_name} help"
    echo ""
    echo "Options:"
    echo "  create                        Create a backup"
    echo "  list [number_to_list]         List the backup files. If number_to_list isn't"
    echo "                                  provided, all backup files will be listed"
    echo "  clean [number_to_keep]        Deletes old backups keeping the number_to_keep"
    echo "                                  most recent backups. If number_to_keep isn't"
    echo "                                  provided, keep 30 most recent backups"
    echo "  help                          Display this help message"
    echo ""
    echo "Arguments:"
    echo "  number_to_list (optional)       The number of backup files to list."
    echo "                                  If not provided, all backup files will be listed"
    echo "  number_to_keep (optional)       The number of the most recent backup files to keep."
    echo "                                  If not provided, the value of the BACKUP_RETENTION_AMOUNT_TO_KEEP"
    echo "                                  environment variable will be used if it exists."
    echo "                                  Defaults to the 30 most recent backups otherwise."
}

function parse_arguments() {
    if [ ${#} -lt 1 ]; then
        ew "> Not enough arguments"
        print_usage
        exit 1
    fi

    # Evaluate the command
    case "$1" in
        create)
            if [ ${#} -ne 1 ]; then
                ee ">>> Invalid number of arguments for 'create'"
                print_usage
                exit 1
            fi
            create_backup
            ;;
        list)
            if [ ${#} -gt 2 ]; then
                ee ">>> Invalid number of arguments for 'list'"
                print_usage
                exit 1
            fi

            local number_to_list=${2:-""}

            if [[ -n "${number_to_list}" ]] && [[ ! "${number_to_list}" =~ ^[0-9]+$ ]]; then
                ew ">>> Invalid argument '${number_to_list}'. Please provide a positive integer"
                exit 1
            fi

            list_backups "${number_to_list}"
            ;;
        clean)
            if [ ${#} -gt 2 ]; then
                ee ">>> Invalid number of arguments for 'clean'"
                print_usage
                exit 1
            fi

            local num_backup_entries=${2:-${LOCAL_BACKUP_RETENTION_AMOUNT_TO_KEEP}}

            if ! [[ "${num_backup_entries}" =~ ^[0-9]+$ ]]; then
                ew ">>> Invalid argument '${num_backup_entries}'. Please provide a positive integer"
                exit 1
            fi

            clean_backups "${num_backup_entries}"
            ;;
        help)
            if [ ${#} -ne 1 ]; then
                ee ">>> Invalid number of arguments for 'help'"
                print_usage
                exit 1
            fi
            print_usage
            ;;
        *)
            ee ">>> Illegal option '${1}'"
            print_usage
            exit 1
            ;;
    esac
}

function check_required_directories() {
    if [ -z "${LOCAL_BACKUP_PATH}" ]; then
        ee ">>> BACKUP_PATH environment variable not set. Exitting..."
        exit 1
    fi
    if [ -z "${LOCAL_GAME_PATH}" ]; then
        ee ">>> GAME_PATH environment variable not set Exiting..."
        exit 1
    fi
    if [ -z "${LOCAL_GAME_SAVE_PATH}" ]; then
        ee ">>> GAME_SAVE_PATH environment variable not set Exiting..."
        exit 1
    fi

    mkdir -p "${LOCAL_BACKUP_PATH}"

    if [ ! -d "${LOCAL_GAME_SAVE_PATH}" ]; then
            ee ">>> Game save directory '${LOCAL_GAME_SAVE_PATH}' doesn't exist yet"
            exit 1
    fi
}

function create_backup() {
    check_required_directories

    date=$(date +%Y%m%d_%H%M%S)
    time=$(date +%H-%M-%S)
    backup_file_name="saved-${date}.tar.gz"

    mkdir -p "${LOCAL_BACKUP_PATH}"

    rconcli "broadcast ${time}-Saving-in-5-seconds"
    sleep 5
    rconcli 'broadcast Saving-world...'
    rconcli 'save'
    rconcli 'broadcast Saving-done'
    sleep 15
    rconcli 'broadcast Creating-backup'

    if ! tar cfz "${LOCAL_BACKUP_PATH}/${backup_file_name}" -C "${LOCAL_GAME_PATH}/" "Saved" ; then
        broadcast_backup_failed
        ee ">>> Backup failed"
    else
        broadcast_backup_success
        es ">>> Backup '${backup_file_name}' created successfully"
    fi 

    if [[ -n ${LOCAL_BACKUP_RETENTION_POLICY} ]] && [[ ${LOCAL_BACKUP_RETENTION_POLICY} == "true" ]] && [[ ${LOCAL_BACKUP_RETENTION_AMOUNT_TO_KEEP} =~ ^[0-9]+$ ]]; then
        ls -1t "${LOCAL_BACKUP_PATH}"/saved-*.tar.gz | tail -n +"$(($LOCAL_BACKUP_RETENTION_AMOUNT_TO_KEEP + 1))" | xargs -d '\n' rm -f --
    fi
}

function list_backups() {
    local num_backup_entries=${1}

    if [ ! -d "${LOCAL_BACKUP_PATH}" ]; then
        ee ">>> Backup directory ${LOCAL_BACKUP_PATH} does not exist"
        exit 1
    fi

    if [ -z "$(ls -A "${LOCAL_BACKUP_PATH}")" ]; then
        ew ">>> No backups in the backup directory ${LOCAL_BACKUP_PATH}"
        exit 0
    fi

    files=$(ls -1t "${LOCAL_BACKUP_PATH}"/saved-*.tar.gz)
    total_file_count=$(echo "${files}" | wc -l)

    if [ -z "${num_backup_entries}" ]; then
        file_list=${files}
        es ">>> Listing ${total_file_count} backup file(s)!"
    else
        file_list=$(echo "${files}" | head -n "${num_backup_entries}")
        es ">>> Listing ${num_backup_entries} out of backup ${total_file_count} file(s)"
    fi

    for file in $file_list; do
        filename=$(basename "${file}")

        # get date from filename
        date_str=${filename#saved-}    # Remove 'saved-' prefix
        date_str=${date_str%.tar.gz}   # Remove '.tar.gz' suffix

        # Reformat the date string
        date=$(date -d "${date_str:0:8} ${date_str:9:2}:${date_str:11:2}:${date_str:13:2}" +'%Y-%m-%d %H:%M:%S')

        ei_nn "${date} | " && e "${filename}"
    done
}

function clean_backups() {
    local num_files_to_keep=${1}

    if [[ -z "$num_files_to_keep" ]]; then
        ew ">>> Number of backups to keep is empty. Using default value of ${LOCAL_BACKUP_RETENTION_AMOUNT_TO_KEEP}"
    fi

    if ! [[ "$num_files_to_keep" =~ ^[0-9]+$ ]]; then
        ee ">>> Invalid argument '${num_files_to_keep}'. Please provide a positive integer"
        exit 1
    fi

    if [ -z "$(ls -A "${LOCAL_BACKUP_PATH}")" ]; then
        ei "> No files in the backup directory ${LOCAL_BACKUP_PATH}. Exiting..."
        exit 0
    fi
    
    files=$(ls -1t "${LOCAL_BACKUP_PATH}"/saved-*.tar.gz)
    files_to_delete=$(echo "${files}" | tail -n +"$(($num_files_to_keep + 1))")
    num_files=$(echo -n "${files}" | grep -c '^')
    num_files_to_delete=$(echo -ne "${files_to_delete}" | grep -c '^')

    if [[ ${num_files_to_delete} -gt 0 ]]; then
        echo "$files_to_delete" | xargs -d '\n' rm -f --
        if [[ ${num_files} -lt ${num_files_to_keep} ]]; then
            num_files_to_keep="${num_files}"
        fi
        es ">>> ${num_files_to_delete} backup(s) cleaned, keeping ${num_files_to_keep} backups(s)"
    else
        ei "> No backups to clean"
    fi
}

function initializeBackupManager() {
    parse_arguments "${@}"
    if [ ! -d "${LOCAL_BACKUP_PATH}" ]; then
        es "> Backup directory ${LOCAL_BACKUP_PATH} doesn't exist. Creating it..."
        mkdir -p "${LOCAL_BACKUP_PATH}"
    fi
}

initializeBackupManager "${@}"
