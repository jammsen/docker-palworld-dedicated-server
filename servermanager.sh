#!/bin/bash

source /server.sh
source /webhook.sh

trap 'term_handler' SIGTERM

if [ ${REMOTE_CONTROL:false} == "true" ]; then
  webhook -hooks /remotehooks.json -verbose &
  killpid=$(pidof webhook)
  send_webhook_notification "$WEBHOOK_REMOTE_ACTION" "$WEBHOOK_REMOTE_READY_DESCRIPTION" "$WEBHOOK_INFO_COLOR"
  wait "$killpid"
else
  start_main &
  killpid="$!"
  wait "$killpid"
  #graeful exit eg. via rcon
  send_stop_notification
fi

exit 0;
