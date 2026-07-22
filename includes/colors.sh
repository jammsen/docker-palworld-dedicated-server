# shellcheck disable=SC2148
# Idea from https://colors.sh/
# ANSI Color Codes - https://www.shellhacks.com/bash-colors/
# Ansi Default Color Codes https://hyperskill.org/learn/step/18193#terminal-support
# Use ANSI whenever possible. Makes logs compatible with almost all systems.

# Aliases for colorful echos with newlines
# The newline is part of the same single write as the message (see
# colorful_echos) so concurrent threads cannot interleave mid-line.
function e() {
    colorful_echos --newline --base "${@}"
}

function ee() {
    colorful_echos --newline --error "${@}"
}

function ei() {
    colorful_echos --newline --info "${@}"
}

function es() {
    colorful_echos --newline --success "${@}"
}

function ew() {
    colorful_echos --newline --warning "${@}"
}

function eo() {
    colorful_echos --newline --overwritten "${@}"
}

# Aliases for colorful echos without newlines
function e_nn() { 
    colorful_echos --base "${@}"
}

function ee_nn() { 
    colorful_echos --error "${@}"
}

function ei_nn() { 
    colorful_echos --info "${@}"
}

function es_nn() { 
    colorful_echos --success "${@}"
}

function ew_nn() {
    colorful_echos --warning "${@}"
}

function eo_nn() {
    colorful_echos --overwritten "${@}"
}

# This creates a wrapper for echo to add colors
function colorful_echos() {
    # --newline: append the line break inside the SAME write as the message.
    # Multiple threads (servermanager, start_main, player detection, companion)
    # share stdout - a separate `echo ""` call for the newline lets another
    # thread's output merge into the middle of a line.
    local trailing_newline=""
    if [ "$1" == "--newline" ]; then
        trailing_newline="\n"
        shift
    fi
    # Set color constants
    BASE="\e[97m"              # Clean color
    CLEAN="\e[0m"              # Clean color
    ERROR="\e[91m"       # Red color for error
    INFO="\e[38;5;68m"    # Light blue (256-color) for info
    SUCCESS="\e[92m"      # Green color for success
    WARNING="\e[93m"      # Yellow color for warning
    OVERWRITTEN="\e[38;5;208m" # Warm orange (256-color) for overwritten values

    if [ $# -gt 2 ]; then
        echo "Usage: $0 [--newline] [--success|--error|--info|--warning|--overwritten|--base] <message>"
        exit 1
    fi

    # Parse arguments
    arg1=$1
    message=$2

    # Set color based on argument
    if [ "$arg1" == "--success" ]; then
        color="$SUCCESS"
    elif [ "$arg1" == "--error" ]; then
        color="$ERROR"
    elif [ "$arg1" == "--info" ]; then
        color="$INFO"
    elif [ "$arg1" == "--warning" ]; then
        color="$WARNING"
    elif [ "$arg1" == "--overwritten" ]; then
        color="$OVERWRITTEN"
    elif [ "$arg1" == "--base" ]; then
        color="$BASE"
    else
        echo -ne "${message}${trailing_newline}"
        return 0
    fi

    # print newlines in the beggining of the message
    while [ "${message:0:2}" = "\\n" ]; do
        # Print a newline
        echo ""
        # Remove the first two characters from the message
        message="${message:2}"
    done

    # Print message with the specified color - one single write per line, so
    # parallel writers can only reorder whole lines, never merge into one
    echo -ne "${color}${message}${CLEAN}${trailing_newline}"
}
