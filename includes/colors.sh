# shellcheck disable=SC2148
# Idea from https://colors.sh/

# Aliases

function e() { 
    colorful_echos --base "${@}"
}

function ee() { 
    colorful_echos --error "${@}"
}

function ei() { 
    colorful_echos --info "${@}"
}

function es() { 
    colorful_echos --success "${@}"
}

function ew() { 
    colorful_echos --warning "${@}"
}

# This creates a wrapper for echo to add colors
function colorful_echos() {
    # Set color constants
    CLEAN="\e[0m"              # Clean color
    ERROR="\e[38;5;196m"       # Red color for error
    INFO="\e[38;5;14m"         # Blue color for info
    SUCCESS="\e[38;5;10m"      # Green color for success
    WARNING="\e[38;5;11m"      # Yellow color for warning

    if [ $# -gt 2 ]; then
        echo "Usage: $0 [--success|--error|--info|--warning|--base] <message>"
        exit 1
    fi

    # Parse the arguments
    arg1=$1
    message=$2

    # Set the color based on the argument
    if [ "$arg1" == "--success" ]; then
        color="$SUCCESS"
    elif [ "$arg1" == "--error" ]; then
        color="$ERROR"
    elif [ "$arg1" == "--info" ]; then
        color="$INFO"
    elif [ "$arg1" == "--warning" ]; then
        color="$WARNING"
    elif [ "$arg1" == "--base" ]; then
        echo -ne "$message"
        return 0
    fi

    # print the newlines in the beggining of the message
    while [ "${message:0:2}" = "\\n" ]; do
        # Print a newline
        echo ""
        # Remove the first two characters from the message
        message="${message:2}"
    done

    # Print the message with the specified color
    echo -ne "${color}${message}${CLEAN}"
}
    