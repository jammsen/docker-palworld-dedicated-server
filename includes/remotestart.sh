#!/bin/bash

if [ ${REMOTE_CONTROL:false} != "true"  ]; then
  echo "Remote control is not active..."
  exit 0;
fi

if [ ! -z "$(pidof PalServer-Linux-Test)" ]; then
  echo "Server already running"
  exit 0;
fi

source /server.sh
source /webhook

trap 'term_handler' SIGTERM

send_webhook_notification "$WEBHOOK_REMOTE_ACTION" "$WEBHOOK_REMOTE_START_DESCRIPTION" "$WEBHOOK_INFO_COLOR"

start_main

while true; do
  if [ -z "$(pidof PalServer-Linux-Test)" ]; then
    term_handler
  fi

  sleep 5
done