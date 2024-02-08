#!/bin/bash

if [ ${REMOTE_CONTROL:false} != "true" ]; then
  echo "Remote control is not active..."
  exit 0;
fi
source /webhook.sh

serverpid="$(pidof PalServer-Linux-Test)"

if [ -z $serverpid ]; then
  echo "Server not running"
  send_webhook_notification "$WEBHOOK_REMOTE_ACTION" "$WEBHOOK_REMOTE_NOTRUNNING_DESCRIPTION" "$WEBHOOK_INFO_COLOR"

  exit 0;
fi

source /server.sh

send_webhook_notification "$WEBHOOK_REMOTE_ACTION" "$WEBHOOK_REMOTE_STOP_DESCRIPTION" "$WEBHOOK_INFO_COLOR"

term_handler