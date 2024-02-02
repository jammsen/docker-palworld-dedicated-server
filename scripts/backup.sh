#!/bin/bash

# Wrapper for backup_manager usage

# Strip the first two characters from the first argument ('--clean' becomes 'clean', ...)
arg1=${1:2}

# Pass the rest of the arguments to the backup_manager command
shift

backup_manager "${arg1}" "$@"
