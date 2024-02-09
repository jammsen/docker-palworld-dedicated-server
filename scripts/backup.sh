#!/bin/bash
# Wrapper for backup manager
# Add '--' to the beginning of the first argument
arg1="--${1}"

# Remove the first argument from the list of arguments
shift

backupmanager "${arg1}" "$@"
