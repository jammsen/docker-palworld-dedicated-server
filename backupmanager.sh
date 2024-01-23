#!/bin/bash

DATE=$(date +%Y%m%d_%H%M%S)

# Create backup dir and change into it
mkdir -p /palworld/backups && cd /palworld/Pal
echo ">>> Creating backup"
tar cfz /palworld/backups/saved-$DATE.tar.gz Saved/
echo ">>> Done"
