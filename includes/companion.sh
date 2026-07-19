# shellcheck disable=SC2148,SC1091

source /includes/colors.sh

# Supervised background sidecar — restarts on crash without ever touching the
# gameserver process.
_supervise() { # <name> <restart_delay_s> <cmd...>
    local name="$1" delay="$2"; shift 2
    local rc=0
    while true; do
        # || rc=$? keeps set -e from exiting when the sidecar crashes.
        "$@" || rc=$?
        ew "> [Supervisor] $name exited (exit ${rc}) - restarting in ${delay} s"
        rc=0
        sleep "$delay"
    done
}

# Node.js companion service (web panel + Discord status card)
companion_loop() {
    sleep "${COMPANION_STARTUP_DELAY}"
    mkdir -p "${GAME_ROOT}/companion"
    _supervise companion 10 node /companion/companion.mjs
}
