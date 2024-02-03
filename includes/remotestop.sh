#!/bin/bash

if [ ${REMOTE_CONTROL:false} != "true" ]; then
  echo "Remote control is not active..."
  exit 0;
fi

if [ -z "$(pidof PalServer-Linux-Test)" ]; then
  echo "Server not running"
  exit 0;
fi

source /server.sh
source /webhook.sh

trap 'term_handler' SIGTERM

send_webhook_notification "$WEBHOOK_REMOTE_ACTION" "$WEBHOOK_REMOTE_STOP_DESCRIPTION" "$WEBHOOK_INFO_COLOR"

term_handler