# shellcheck disable=SC2148,SC1091

source /includes/colors.sh

# Supervising loop for the Node.js companion service (web panel + Discord status card).
# A companion crash must never affect the gameserver - the loop restarts it with a delay.
companion_loop() {
    sleep "${COMPANION_STARTUP_DELAY}"
    mkdir -p "${GAME_ROOT}/companion"
    while true; do
        node /companion/companion.mjs || ew ">>> Companion service exited with code $? - restarting in 10 seconds"
        sleep 10
    done
}
