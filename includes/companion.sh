# shellcheck disable=SC2148,SC1091

source /includes/colors.sh
source /includes/services.sh

# Node.js companion service (web panel + Discord status card)
companion_loop() {
    sleep "${COMPANION_STARTUP_DELAY}"
    mkdir -p "${GAME_ROOT}/companion"
    _supervise companion 10 node /companion/companion.mjs
}

# Append an event for the companion event log (Discord card + web dashboard).
# Line format: <epoch>|<type>[|<detail>[|<detail2>]] - the companion maps
# types to labels/emojis; details carry player names (join/leave/rename).
# Cheap and always-on: writing costs nothing when the companion is disabled.
log_companion_event() { # <type> [detail] [detail2]
    local events_file="${GAME_ROOT}/companion/events.log"
    # Strip the field separator from details so names cannot break the format
    local detail1="${2//|/}" detail2="${3//|/}"
    mkdir -p "${GAME_ROOT}/companion"
    if [[ -n "$detail2" ]]; then
        echo "$(date +%s)|$1|${detail1}|${detail2}" >> "$events_file"
    elif [[ -n "$detail1" ]]; then
        echo "$(date +%s)|$1|${detail1}" >> "$events_file"
    else
        echo "$(date +%s)|$1" >> "$events_file"
    fi
    # Trim occasionally so the file cannot grow unboundedly (events are rare;
    # the tiny read/trim race with the companion is acceptable)
    if [[ $(wc -l < "$events_file") -gt 200 ]]; then
        tail -n 100 "$events_file" > "${events_file}.tmp" && mv "${events_file}.tmp" "$events_file"
    fi
}
