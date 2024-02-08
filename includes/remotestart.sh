#!/bin/bash

if [ ${REMOTE_CONTROL:false} != "true"  ]; then
  echo "Remote control is not active..."
  exit 0;
fi

source /webhook.sh

if [ ! -z "$(pidof PalServer-Linux-Test)" ]; then
  echo "Server already running"
  send_webhook_notification "$WEBHOOK_REMOTE_ACTION" "$WEBHOOK_REMOTE_ISRUNNING_DESCRIPTION" "$WEBHOOK_INFO_COLOR"
  exit 0;
fi

source /server.sh

trap 'term_handler false' SIGTERM

send_webhook_notification "$WEBHOOK_REMOTE_ACTION" "$WEBHOOK_REMOTE_START_DESCRIPTION" "$WEBHOOK_INFO_COLOR"

start_main

while true; do
  if [ -z "$(pidof PalServer-Linux-Test)" ]; then
    #server exited without termhandler e.g. rcon -> send notification
    send_stop_notification
    exit 0
  fi

  sleep 5
done