# shellcheck disable=SC2148

# All writers are processes inside THIS container, so the lock lives in
# container-local /tmp and never touches the game volume
GAME_EVENTS_LOCK="/tmp/game-events.log.lock"

# Append an event to the gameserver's event log, consumed read-only by the
# companion service (Discord card + web dashboard).
# Line format: <epoch>|<type>[|<detail>[|<detail2>]] - the companion maps
# types to labels/emojis; details carry player names (join/leave/rename).
# Concurrency design: multiple processes append (player detection, backups,
# restarts, server start/stop) but ONLY the servermanager removes lines (see
# game_events_maintenance_loop); the shared lock keeps appends and trims from
# ever interleaving, so no event can be lost or garbled.
# Cheap and always-on: writing costs nothing when no companion is attached.
log_game_event() { # <type> [detail] [detail2]
    local events_file="${GAME_ROOT}/game-events.log"
    # Strip field and line separators from details so names can neither break
    # the format nor inject fake event lines
    local detail1="${2//|/}" detail2="${3//|/}"
    detail1="${detail1//[$'\r\n']/}"
    detail2="${detail2//[$'\r\n']/}"
    local line
    if [[ -n "$detail2" ]]; then
        line="$(date +%s)|$1|${detail1}|${detail2}"
    elif [[ -n "$detail1" ]]; then
        line="$(date +%s)|$1|${detail1}"
    else
        line="$(date +%s)|$1"
    fi
    (
        flock 9
        echo "$line" >> "$events_file"
    ) 9>>"$GAME_EVENTS_LOCK"
}

# Keep the file bounded (>200 lines -> last 100). Called ONLY from the
# servermanager's maintenance loop - the single remover by design.
trim_game_events() {
    local events_file="${GAME_ROOT}/game-events.log"
    [[ -f "$events_file" ]] || return 0
    (
        flock 9
        if [[ $(wc -l < "$events_file") -gt 200 ]]; then
            tail -n 100 "$events_file" > "${events_file}.tmp" && mv "${events_file}.tmp" "$events_file"
        fi
    ) 9>>"$GAME_EVENTS_LOCK"
}

# Background thread of the servermanager - trims occasionally; events are
# rare, so a relaxed interval keeps the file small long before it matters
game_events_maintenance_loop() {
    while true; do
        sleep 300
        trim_game_events
    done
}
