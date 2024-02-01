# shellcheck disable=SC2148,SC1091
source /includes/colors.sh

# Function to check if the default passwords are replaced
function check_for_default_credentials() {
    pp --info ">>> Checking for existence of default credentials\n"
    if [[ -n $ADMIN_PASSWORD ]] && [[ $ADMIN_PASSWORD == "adminPasswordHere" ]]; then
        pp --error "> ERROR: Security thread detected: Please change the default admin password. Aborting server start ...\n"
        exit 1
    fi
    if [[ -n $SERVER_PASSWORD ]] && [[ $SERVER_PASSWORD == "serverPasswordHere" ]]; then
        pp --error "> ERROR: Security thread detected: Please change the default server password. Aborting server start ...\n"
        exit 1
    fi
}
