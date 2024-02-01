#!/bin/bash

# shellcheck disable=SC1091
source /includes/colors.sh

# Default values if the environment variables exist

BACKUP_DIR=${BACKUP_PATH} # Dir where the backup files are stored
# RESTORE_FILE_PATH=${TRIGGER_RESTORE_PATH} # Dir where the restore trigger file with the backup file name is stored
# BACKUP_FILE=${TRIGGER_RESTORE_FILE} # Path of the backup file trigger
SAVE_DIR=${GAME_SAVE_PATH} # Dir where the game save files are stored
BACKUPS_TO_KEEP=${BACKUP_RETENTION_AMOUNT} # Number of backup files to keep


# Function to print usage information
function print_usage() {
    script_name=$(basename "$0")
    echo "Usage:"
    echo "  ${script_name} [backup_directory] -c|--create"
    # echo "  ${script_name} [backup_directory] -r|--restore [backup_name]"
    echo "  ${script_name} [backup_directory] -l|--list [num_entries]"
    echo "  ${script_name} [backup_directory] -cl|--clean [num_to_keep]"
    echo "  ${script_name} -h|--help"
    echo ""
    echo "Options:"
    echo "  -c, --create                    Create a backup"
    # echo "  -r, --restore [backup_name]     Restore from a backup"
    echo "  -l, --list [num_entries]        List the backup files. If num_entries isn't"
    echo "                                  provided, all backup files will be listed"
    echo "  -cl, --clean [num_to_keep]      Deletes old backups keeping the num_to_keep"
    echo "                                  most recent backups. If num_to_keep isn't"
    echo "                                  provided, keep 30 most recent backups"
    echo "  -h, --help                      Display this help message"
    echo ""
    echo "Arguments:"
    echo "  backup_directory    (optional) The directory where the backup files are stored."
    echo "                                 If not provided, the value of the BACKUP_PATH"
    echo "                                 environment variable will be used if it exists"
    echo "                                 and is not empty."
    # echo "  backup_name         (optional) The name of the backup file to restore from."
    # echo "                                 If not provided, the value of the BACKUP_FILE"
    # echo "                                 environment variable will be used if it exists"
    # echo "                                 and is not empty."
    echo "  num_entries         (optional) The number of backup files to list."
    echo "                                 If not provided, all backup files will be listed"
    echo "  num_to_keep         (optional) The number of the most recent backup files to keep."
    echo "                                 If not provided, the value of the BACKUP_RETENTION_AMOUNT"
    echo "                                 environment variable will be used if it exists and is not empty."
    echo "                                 Defaults to the 5 most recent backups otherwise."
}


# Function to parse input arguments
function parse_arguments() {
    if [ ${#} -lt 1 ]; then
        pp --warning "> Not enough arguments.\n"
        print_usage
        exit 1
    fi

    # Check if the backup directory was given as an argument
    case "$2" in 
        -c|--create|-r|--restore|-l|--list)
            BACKUP_DIR=${1}
            pp --info "> Backup directory provided '${BACKUP_DIR}'.\n"
            # Check if backup directory exists
            if [ ! -d "${BACKUP_DIR}" ]; then
                pp --error "[ERROR] Backup directory $BACKUP_DIR does not exist.\n\n"
                exit 1
            fi
            skip 1 # Skip the backup directory argument
            ;;

        *)
            check_required_directories
            ;;
    esac

    # Check the command
    case "$1" in
        -c|--create)
            if [ ${#} -ne 1 ]; then
                pp --error "Invalid number of arguments for 'create'\n"
                print_usage
                exit 1
            fi
            create_backup
            ;;
        -l|--list)
            if [ ${#} -gt 2 ]; then
                pp --error "Invalid number of arguments for 'list'\n"
                print_usage
                exit 1
            fi
            list_backups "${2:-}"
            ;;
        # -r|--restore)
        #     if [ ${#} -gt 2 ]; then
        #         pp --error "Invalid number of arguments for 'restore'\n"
        #         print_usage
        #         exit 1
        #     fi
        #     restore_backup "${2:-}"
        #     ;;
        -cl|--clean)
            if [ ${#} -gt 2 ]; then
                pp --error "Invalid number of arguments for 'clean'\n"
                print_usage
                exit 1
            fi
            clean_backups "${2:-}"
            ;;
        -h|--help)
            if [ ${#} -ne 1 ]; then
                pp --error "Invalid number of arguments for 'help'\n"
                print_usage
                exit 1
            fi
            print_usage
            ;;
        *)
            pp --error "Illegal option '${1}'\n"
            print_usage
            exit 1
            ;;
    esac
}

function check_required_directories() {
    # Exit if backup dir or game save dir don't exist
    # Check if env vars set as default to local vars exist
    if [ -z "${BACKUP_DIR}" ]; then
        pp --error "> BACKUP_PATH environment variable not set.\n"
        pp --error "> Please provide the backup directory as an argument or set the BACKUP_PATH environment variable.\n"
        pp --error "> Exiting...\n"
        exit 1
    elif [ -z "${SAVE_DIR}" ]; then
        pp --error "> GAME_SAVE_PATH environment variable not set.\n"
        pp --error "> Exiting...\n"
        exit 1
    fi

    # If vars are set, check if the directories exist
    if [ ! -d "${BACKUP_DIR}" ]; then
        pp --error "[ERROR] Backup directory '${BACKUP_DIR}' does not exist.\n"
        exit 1
    elif [ ! -d "${SAVE_DIR}" ]; then
        pp --error "[ERROR] Game save directory '${SAVE_DIR}' does not exist.\n"
        exit 1
    fi
}


### Backup Functions

function create_backup() {

    pp --success ">>> Creating backup...\n\n"


    if [ -z "${GAME_PATH}" ]; then
        pp --error "> RESTORE_FILE_PATH environment variable not set. Exiting...\n"
        exit 1
    fi
    
    DATE=$(date +%Y%m%d_%H%M%S)
    TIME=$(date +%H-%M-%S)

    #Send message to gameserver via RCON if enabled
    rc "broadcast ${TIME}-Backup_in_progress" "> Broadcasting server shutdown via RCON...\n"

    # Create backup dir if it doesn't exist
    mkdir -p "${BACKUP_DIR}"

    #Send message to gameserver via RCON if enabled
    rc 'broadcast Saving world...' "> Sending message to gameserver via RCON..."
    rc 'save'
    rc 'broadcast Done!' "> Broadcast via RCON complete!"


    # Create backup
    tar cfz "${BACKUP_DIR}/saved-${DATE}.tar.gz" -C "${GAME_PATH}" Saved/
    pp --success ">>> Backup created successfully!\n"


}

function list_backups() {
    local num_backup_entries=${1:-""}

    pp --success ">>> Listing backups:\n\n"

    # Check num_backup_entries argument
    # if argument exists and is not a positive integer, print usage message and exit
    if [[ -n "$num_backup_entries" && ! "$num_backup_entries" =~ ^[0-9]+$ ]]; then
        pp --error "[ERROR] Invalid argument. Please provide a positive integer.\n"
        exit 1
    fi

    # Check if backup directory exists
    if [ ! -d "$BACKUP_DIR" ]; then
        pp --error "[ERROR] Backup directory $BACKUP_DIR does not exist.\n"
        exit 1
    fi

    # Check if there are any files in the backup directory
    if [ -z "$(ls -A "$BACKUP_DIR")" ]; then
        pp --info "No backups in the backup directory $BACKUP_DIR.\n"
        exit 0
    fi

    # get file list
    files=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "*.tar.gz" | sort -r)
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

        pp --info "${date} | "
        pp --base "${filename}\n"
    done

    if [ -z "$num_backup_entries" ]; then
        # if num_backup_entries is not set, use all files
        pp --info "\n> Found ${total_file_count} backup file(s)!\n"
    else
        # if num_backup_entries is set, use the first num_backup_entries files
        pp --info "\n> Found ${total_file_count} backup file(s), but listing only ${num_backup_entries} file(s)!\n"
    fi
}

function clean_backups() {
    local num_files_to_keep=${1:-${BACKUPS_TO_KEEP}}

    pp --success ">>> Backup cleaning started..\n\n"

    if [[ -z "$num_files_to_keep" ]]; then
        pp --warning "> Number of backups to keep is empty. Using default value of 30.\n"
        num_files_to_keep=30
    fi

    if ! [[ "$num_files_to_keep" =~ ^[0-9]+$ ]]; then
        pp --error "> [ERROR] Invalid argument '${BACKUPS_TO_KEEP}'. Please provide a positive integer.\n\n"
        print_usage
        exit 1
    fi

    # Check if there are any files in the backup directory
    if [ -z "$(ls -A "${BACKUP_DIR}")" ]; then
        pp --info "> No files in the backup directory ${BACKUP_DIR}. Exiting...\n\n"
        exit 0
    fi

    pp --info "> Keeping latest ${num_files_to_keep} backups.\n"
    
    files_to_delete=$(find "${BACKUP_DIR}" -maxdepth 1 -type f -name "saved-*.tar.gz" \
    | sort -r \
    | tail -n +$(("${num_files_to_keep}"+1)))

    num_files_to_delete=0
    if [ -n "$files_to_delete" ]; then
        num_files_to_delete=$(echo -e "$files_to_delete" | wc -l)
    fi

    if [[ num_files_to_delete -gt 0 ]]; then
        echo "$files_to_delete" | xargs -d '\n' rm -f --
        pp --warning "> Deleted ${num_files_to_delete} file(s).\n"
    else
        pp --info "> No files to delete.\n"
    fi

    pp --success "\n>>> Cleaning finished!\n"
}

# function restore_backup() {
#     local backup_name=${1:-$(tr -d '\n' < "${BACKUP_FILE}")}

#     pp --info ">>> Restoring backup..."

#     # Check if backup file exists
#     if [ ! -f "${BACKUP_DIR}/${backup_name}" ]; then
#         ppl --error "> [ERROR] Backup file '${backup_name}' does not exist.\n\n"
#         exit 1
#     fi

#     pp --info "> Backup '${backup_name}' will be restored to '${SAVE_DIR}'.\n"

#     DATE=$(date +%Y%m%d_%H%M%S)

#     tar -czf "${BACKUP_DIR}/restore-${DATE}.tar.gz" -C /palworld/Pal Saved/
#     pp --info"> Backup of current state saved to '${BACKUP_DIR}/restore-${DATE}.tar.gz'.\n"

#     pp --info "> Removing current saved data.\n"
#     rm -r "${SAVE_DIR}"

#     pp --info "> Restoring backup"
#     tar -xzf "${BACKUP_DIR}/${backup_name}" -C /palworld/Pal
# }


### Backup Manager Initialization

function initializeBackupManager() {

    # Check if the backup directory exists, if not create it
    if [ ! -d "${BACKUP_DIR}" ]; then
        pp --info "> Backup directory ${BACKUP_DIR} doesn't exist. Creating it..."
        mkdir -p "${BACKUP_DIR}"
    fi

    parse_arguments "${@}"
}

# Call the initializeBackupManager function and pass the arguments
initializeBackupManager "${@}"
