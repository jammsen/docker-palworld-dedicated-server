# shellcheck disable=SC2148

# Append an event to the gameserver's event log, consumed read-only by the
# companion service (Discord card + web dashboard).
# Line format: <epoch>|<type>[|<detail>[|<detail2>]] - the companion maps
# types to labels/emojis; details carry player names (join/leave/rename).
# The gameserver is the only writer of this file; the companion mounts it
# read-only, so trimming happens here on the writer side.
# Cheap and always-on: writing costs nothing when no companion is attached.
log_game_event() { # <type> [detail] [detail2]
    local events_file="${GAME_ROOT}/game-events.log"
    # Strip field and line separators from details so names can neither break
    # the format nor inject fake event lines
    local detail1="${2//|/}" detail2="${3//|/}"
    detail1="${detail1//[$'\r\n']/}"
    detail2="${detail2//[$'\r\n']/}"
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
