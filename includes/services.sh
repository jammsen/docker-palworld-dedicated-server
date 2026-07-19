# shellcheck disable=SC2148,SC1091
# Supervised background sidecars - shared helper for any service that should
# restart on crash without ever touching the gameserver process.

source /includes/colors.sh

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
