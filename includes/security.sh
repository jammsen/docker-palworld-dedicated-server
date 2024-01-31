# Function to check if the default passwords are replaced
function check_for_default_credentials() {
    echo ">>> Checking for existence of default credentials"
    if [[ -n $ADMIN_PASSWORD ]] && [[ $ADMIN_PASSWORD == "adminPasswordHere" ]]; then
        echo ">>> Error: Security thread detected: Please change the default admin password. Aborting server start ..."
        exit 1
    fi
    if [[ -n $SERVER_PASSWORD ]] && [[ $SERVER_PASSWORD == "serverPasswordHere" ]]; then
        echo ">>> Error: Security thread detected: Please change the default server password. Aborting server start ..."
        exit 1
    fi
}
