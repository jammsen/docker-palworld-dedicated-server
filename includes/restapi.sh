# shellcheck disable=SC2148,SC1091

source /includes/colors.sh

# ---------------------------------------------------------------------------
# Primitives — HTTP transport layer
# These functions never call exit. They return non-zero on failure.
# ---------------------------------------------------------------------------

# restapi_get <endpoint>
# Performs a GET request against the REST API. Prints JSON response body to stdout.
# Returns 0 on HTTP 2xx, non-zero on failure.
restapi_get() {
    local endpoint=$1
    local response http_code body

    response=$(curl -s \
        --max-time "${RESTAPI_TIMEOUT:-10}" \
        -u "admin:${ADMIN_PASSWORD}" \
        -H "Accept: application/json" \
        -X GET \
        -w "\n%{http_code}" \
        "http://127.0.0.1:${RESTAPI_PORT}/v1/api/${endpoint}" 2>/dev/null)

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)

    if [[ "$http_code" =~ ^2 ]]; then
        echo "$body"
        return 0
    fi
    ew "> REST API GET /${endpoint} failed (HTTP ${http_code:-000})"
    return 1
}

# restapi_post <endpoint> [json_body]
# Performs a POST request against the REST API.
# Returns 0 on HTTP 2xx, non-zero on failure.
restapi_post() {
    local endpoint=$1
    local json_body=${2:-}
    local http_code
    local curl_args=(-s --max-time "${RESTAPI_TIMEOUT:-10}" -u "admin:${ADMIN_PASSWORD}" -X POST -o /dev/null -w "%{http_code}")

    if [[ -n "$json_body" ]]; then
        curl_args+=(-H "Content-Type: application/json" --data-raw "$json_body")
    else
        curl_args+=(-H "Content-Length: 0")
    fi

    http_code=$(curl "${curl_args[@]}" "http://127.0.0.1:${RESTAPI_PORT}/v1/api/${endpoint}" 2>/dev/null)

    if [[ "$http_code" =~ ^2 ]]; then
        return 0
    fi
    ew "> REST API POST /${endpoint} failed (HTTP ${http_code:-000})"
    return 1
}

# ---------------------------------------------------------------------------
# Core REST API operations
# ---------------------------------------------------------------------------

function restapi_announce() {
    local message=$1
    local safe_message="${message//\"/\\\"}"
    restapi_post "announce" "{\"message\":\"${safe_message}\"}"
}

function restapi_save() {
    restapi_post "save"
}

# restapi_shutdown <waittime> [message]
function restapi_shutdown() {
    local waittime=${1:-10}
    local message=${2:-}
    local safe_message="${message//\"/\\\"}"
    restapi_post "shutdown" "{\"waittime\":${waittime},\"message\":\"${safe_message}\"}"
}

function restapi_get_players() {
    restapi_get "players"
}

# ---------------------------------------------------------------------------
# High-level semantic functions — used by internal scripts
# ---------------------------------------------------------------------------

function get_time() {
    date '+[%H:%M:%S]'
}

# check_is_server_empty — returns 0 if no players online, 1 otherwise
function check_is_server_empty() {
    local response num_players
    response=$(restapi_get "metrics") || return 1
    num_players=$(echo "$response" | jq -r '.currentplayernum // 0')
    if [[ "$num_players" -eq 0 ]]; then
        return 0  # Server empty
    else
        return 1  # Server not empty
    fi
}

function save_and_shutdown_server() {
    restapi_announce "$(get_time) Server shutdown requested. Saving..."
    restapi_save
    restapi_shutdown 10 "$(get_time) Saving done. Server shutting down..."
}

function broadcast_automatic_restart() {
    for ((counter=15; counter>=1; counter--)); do
        restapi_announce "$(get_time)-AUTOMATIC-RESTART-IN-${counter}-MINUTES"
        sleep 60
    done
    restapi_announce "$(get_time) Saving world before restart..."
    restapi_save
    restapi_announce "$(get_time) Saving done"
    restapi_announce "$(get_time) Creating backup..."
    restapi_shutdown 10 "$(get_time) Restarting server..."
}

function broadcast_backup_start() {
    restapi_announce "$(get_time) Saving in 5 seconds..."
    sleep 5
    restapi_announce "$(get_time) Saving world..."
    restapi_save
    restapi_announce "$(get_time) Saving done"
    restapi_announce "$(get_time) Creating backup..."
}

function broadcast_backup_success() {
    restapi_announce "$(get_time) Backup done"
}

function broadcast_backup_failed() {
    restapi_announce "$(get_time) Backup failed"
}

function broadcast_player_join() {
    restapi_announce "$(get_time) $1 joined the server"
}

function broadcast_player_name_change() {
    restapi_announce "$(get_time) $1 renamed to $2"
}

function broadcast_player_leave() {
    restapi_announce "$(get_time) $1 left the server"
}
