#!/bin/bash

if [ $# -gt 1 ]; then
    pp --error "Number of args is invalid. Expected positive number or nothing (keeps most recent 30 backups)."
    exit 1
fi

backup_manager --clean "$@"
