# shellcheck disable=SC2148

# Changes the ownership to $APP_USER:$APP_GROUP for the given file / recursively to the given folder
change_ownership() {
    local APP_USER="$1"
    local APP_GROUP="$2"
    local TARGET="$3"

    # Find files or directories not owned by specified user and group
    files_with_incorrect_permissions=$(find "$TARGET" ! -user "$APP_USER" -o ! -group "$APP_GROUP")

    if [ -z "$files_with_incorrect_permissions" ]; then
        ei "> All items in $TARGET are already owned by $APP_USER:$APP_GROUP."
    else
        # Echo the total count of files_with_incorrect_permissions
        count=$(echo "$files_with_incorrect_permissions" | wc -l)
        ei "> Found $count items with improper permissions"

        # Echo the files_with_incorrect_permissions to stdout
        ei "> Files with incorrect permissions:"
        ei "> $files_with_incorrect_permissions"

        # Check if running as root and warn user if not
        if [ "$EUID" -ne 0 ]; then
            ee "> Cannot fix ownership unless container is ran as root. This is a separate setting from the PUID and PGID environmental variables."
            exit 1
        else
            # Change ownership recursively to specified user and group
            ei "> Changing ownership..."
            chown -R "$APP_USER:$APP_GROUP" "$TARGET"
        fi

        echo "> Ownership changed to $APP_USER:$APP_GROUP for all items in $TARGET."
    fi
}
