#!/bin/bash

if [ $# -gt 1 ]; then
    pp --error "Number of args is invalid. Expected positive number or nothing (prints all backups)."
    exit 1
fi

backup_manager --list "$@"
