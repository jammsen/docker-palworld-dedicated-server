#!/bin/bash

# Change ownership of /palworld to steam user
chown -R steam:steam /palworld
# Run servermanager.sh as steam user
su -c "/servermanager.sh" steam
