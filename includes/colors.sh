# shellcheck disable=SC2148
# https://colors.sh/

# Pretty print messages with colors 
function pp() {
    # Set color constants
    BASE="\e[0m"        # Base color
    SUCCESS="\e[0;32m"  # Green color for success
    ERROR="\e[0;31m"    # Red color for error
    INFO="\e[0;34m"     # Blue color for info
    WARNING="\e[0;33m"  # Yellow color for warning
    CLEAN="\e[0m"       # Clean color

    # Check if the required arguments are provided
    if [ $# -ne 2 ]; then
        echo "Usage: $0 [--success|--error|--info|--warning] <message>"
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
        color="$BASE"
    else
        echo -ne "$arg1"
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
    
