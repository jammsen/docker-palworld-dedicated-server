#!/bin/bash

# Wrapper for backup_manager

# Add '--' to the beginning of the first argument
arg1="--${1}"

# Remove the first argument from the list of arguments
shift

backup_manager "${arg1}" "$@"
