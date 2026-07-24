# shellcheck disable=SC2148,SC1091

source /includes/colors.sh
source /includes/services.sh

# Node.js companion service (web panel + Discord status card)
companion_loop() {
    sleep "${COMPANION_STARTUP_DELAY}"
    mkdir -p "${GAME_ROOT}/companion"
    _supervise companion 10 node /companion/companion.mjs
}
