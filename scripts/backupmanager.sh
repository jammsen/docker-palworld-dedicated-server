#!/bin/bash
# shellcheck disable=SC1091,SC2012

source /includes/colors.sh

# Default values if the environment variables exist
LOCAL_BACKUP_PATH=${BACKUP_PATH} # Dir where the backup files are stored
LOCAL_GAME_SAVE_PATH=${GAME_SAVE_PATH} # Dir where the game save files are stored
LOCAL_BACKUP_RETENTION_AMOUNT_TO_KEEP=${BACKUP_RETENTION_AMOUNT_TO_KEEP} # Number of backup files to keep


function print_usage() {
    script_name=$(basename "$0")
    echo "Usage:"
    echo "  ${script_name} --create"
    echo "  ${script_name} --list [number_of_entries]"
    echo "  ${script_name} --clean [number_to_keep]"
    echo "  ${script_name} --help"
    echo ""
    echo "Options:"
    echo "  --create                        Create a backup"
    echo "  --list [number_of_entries]      List the backup files. If number_of_entries isn't"
    echo "                                  provided, all backup files will be listed"
    echo "  --clean [number_to_keep]        Deletes old backups keeping the number_to_keep"
    echo "                                  most recent backups. If number_to_keep isn't"
    echo "                                  provided, keep 30 most recent backups"
    echo "  --help                          Display this help message"
    echo ""
    echo "Arguments:"
    echo "  number_of_entries (optional)    The number of backup files to list."
    echo "                                  If not provided, all backup files will be listed"
    echo "  number_to_keep (optional)       The number of the most recent backup files to keep."
    echo "                                  If not provided, the value of the BACKUP_RETENTION_AMOUNT_TO_KEEP"
    echo "                                  environment variable will be used if it exists and is not empty."
    echo "                                  Defaults to the 5 most recent backups otherwise."
}

function parse_arguments() {
    if [ ${#} -lt 1 ]; then
        ew "> Not enough arguments.\n"
        print_usage
        exit 1
    fi

    # Check the command
    case "$1" in
        --create)
            if [ ${#} -ne 1 ]; then
                ee "Invalid number of arguments for 'create'\n"
                print_usage
                exit 1
            fi
            create_backup
            ;;
        --list)
            if [ ${#} -gt 2 ]; then
                ee "Invalid number of arguments for 'list'\n"
                print_usage
                exit 1
            fi
            list_backups "${2:-}"
            ;;
        --clean)
            if [ ${#} -gt 2 ]; then
                ee "Invalid number of arguments for 'clean'\n"
                print_usage
                exit 1
            fi

            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                ew "> Invalid argument '${2}'. Please provide a positive integer.\n"
                ew "> Defaulting to ${LOCAL_BACKUP_RETENTION_AMOUNT_TO_KEEP}.\n"
            fi

            clean_backups "${reger}"eg
            ;;
        --help)
            if [ ${#} -ne 1 ]; then
                ee "Invalid number of arguments for 'help'\n"
                print_usage
                exit 1
            fi
            print_usage
            ;;
        *)
            ee "Illegal option '${1}'\n"
            print_usage
            exit 1
            ;;
    esac
}

function check_required_directories() {
    # Exit if backup dir or game save dir don't exist
    # Check if env vars set as default to local vars exist
    if [ -z "${LOCAL_BACKUP_PATH}" ]; then
        ee "> BACKUP_PATH environment variable not set.\n"
        ee "> Please provide the backup directory as an argument or set the BACKUP_PATH environment variable.\n"
        ee "> Exiting...\n"
        exit 1
    elif [ -z "${LOCAL_GAME_SAVE_PATH}" ]; then
        ee "> GAME_SAVE_PATH environment variable not set.\n"
        ee "> Exiting...\n"
        exit 1
    fi

    # If vars are set, check if the directories exist
    mkdir -p "${LOCAL_BACKUP_PATH}"
    if [ ! -d "${LOCAL_GAME_SAVE_PATH}" ]; then
            ee "> Game save directory '${LOCAL_GAME_SAVE_PATH}' does not exist yet.\n"
            exit 1
    fi
}


### Backup Functions

function create_backup() {

    if [[ -n $BACKUP_RETENTION_POLICY ]] && [[ $BACKUP_RETENTION_POLICY == "true" ]]; then
        clean_backups   
    fi

    es ">>> Creating backup...\n\n"


    if [ -z "${GAME_PATH}" ]; then
        ee "> RESTORE_FILE_PATH environment variable not set. Exiting...\n"
        exit 1
    fi
    
    DATE=$(date +%Y%m%d_%H%M%S)
    TIME=$(date +%H-%M-%S)


    rcon 'broadcast $TIME-Saving-in-5-seconds'
    sleep 5

    # Create backup dir if it doesn't exist
    mkdir -p "${LOCAL_BACKUP_PATH}"

    #Send message to gameserver via RCON if enabled
    rcon 'broadcast Saving world...'
    rcon 'save'
    sleep 1
    rcon 'broadcast Saving-done'
    rcon 'broadcast Creating-backup'
    sleep 1
    # Create backup
    tar cfz "${LOCAL_BACKUP_PATH}/saved-${DATE}.tar.gz" -C "${GAME_PATH}" Saved/
    rcon 'broadcast Backup-done'
    es ">>> Backup created successfully!\n"
}

function list_backups() {
    local num_backup_entries=${1:-""}

    es ">>> Listing backups:\n"

    # Check num_backup_entries argument
    # if argument exists and is not a positive integer, print usage message and exit
    if [[ -n "$num_backup_entries" && ! "$num_backup_entries" =~ ^[0-9]+$ ]]; then
        ee "[ERROR] Invalid argument. Please provide a positive integer.\n"
        exit 1
    fi

    # Check if backup directory exists
    if [ ! -d "$LOCAL_BACKUP_PATH" ]; then
        ee "[ERROR] Backup directory $LOCAL_BACKUP_PATH does not exist.\n"
        exit 1
    fi

    # Check if there are any files in the backup directory
    if [ -z "$(ls -A "$LOCAL_BACKUP_PATH")" ]; then
        ei "No backups in the backup directory $LOCAL_BACKUP_PATH.\n"
        exit 0
    fi

    # get file list
    files=$(find "$LOCAL_BACKUP_PATH" -maxdepth 1 -type f -name "*.tar.gz" | sort -r)
    total_file_count=$(echo "$files" | wc -l)

    if [ -z "$num_backup_entries" ]; then
        # if num_backup_entries is not set, use all files
        file_list=$files
    else
        # if num_backup_entries is set, use the first num_backup_entries files
        file_list=$(echo "$files" | head -n "$num_backup_entries")
    fi

    # print file list (currently using date from file name but can use creation date from 'stat')
    for file in $file_list; do
        filename=$(basename "$file")
        # get date from creation date
        #creation_date=$(stat -c %w "$file")

        # Reformat the date string
        #date=$(date -d "$creation_date" +'%Y-%m-%d %H:%M:%S')

        # get date from filename
        date_str=${filename#saved-}    # Remove 'saved- or restore-' prefix
        date_str=${date_str%.tar.gz}   # Remove '.tar.gz' suffix

        # Reformat the date string
        date=$(date -d "${date_str:0:8} ${date_str:9:2}:${date_str:11:2}:${date_str:13:2}" +'%Y-%m-%d %H:%M:%S')

        ei "${date} | "
        e "${filename}\n"
    done

    if [ -z "$num_backup_entries" ]; then
        # if num_backup_entries is not set, use all files
        ei "\n> Found ${total_file_count} backup file(s)!\n"
    else
        # if num_backup_entries is set, use the first num_backup_entries files
        ei "\n> Found ${total_file_count} backup file(s), but listing only ${num_backup_entries} file(s)!\n"
    fi
}

function clean_backups() {
    local num_files_to_keep=${1:-${LOCAL_BACKUP_RETENTION_AMOUNT_TO_KEEP}}

    es ">>> Backup cleaning started..\n\n"

    if [[ -z "$num_files_to_keep" ]]; then
        ew "> Number of backups to keep is empty. Using default value of 30.\n"
    fi

    if ! [[ "$num_files_to_keep" =~ ^[0-9]+$ ]]; then
        ee "> [ERROR] Invalid argument '${num_files_to_keep}'. Please provide a positive integer.\n\n"
        print_usage
        exit 1
    fi

    # Check if there are any files in the backup directory
    if [ -z "$(ls -A "${LOCAL_BACKUP_PATH}")" ]; then
        ei "> No files in the backup directory ${LOCAL_BACKUP_PATH}. Exiting...\n\n"
        exit 0
    fi

    ei "> Keeping latest ${num_files_to_keep} backups.\n"
    
    files_to_delete=$(ls -1t saved-*.tar.gz | tail -n +$($num_files_to_keep + 1))

    num_files_to_delete=0
    if [ -n "$files_to_delete" ]; then
        num_files_to_delete=$(echo -e "$files_to_delete" | wc -l)
    fi

    if [[ num_files_to_delete -gt 0 ]]; then
        echo "$files_to_delete" | xargs -d '\n' rm -f --
        ew "> Deleted ${num_files_to_delete} file(s).\n"
    else
        ei "> No files to delete.\n"
    fi

    es "\n>>> Cleaning finished!\n"
}


### Backup Manager Initialization

function initializeBackupManager() {

    parse_arguments "${@}"
    # Check if the backup directory exists, if not create it
    if [ ! -d "${LOCAL_BACKUP_PATH}" ]; then
        es "> Backup directory ${LOCAL_BACKUP_PATH} doesn't exist. Creating it..."
        mkdir -p "${LOCAL_BACKUP_PATH}"
    fi
}

# Call the initializeBackupManager function and pass the arguments
initializeBackupManager "${@}"
