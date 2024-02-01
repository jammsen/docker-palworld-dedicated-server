#!/bin/bash

if [ $# -gt 0 ]; then
    pp --error "No argumments expected."
    exit 1
fi

backup_manager --create
