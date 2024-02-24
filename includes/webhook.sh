# shellcheck disable=SC2148
# Function to generate JSON data for the Discord message
# Webpage for COLOR-Calculation - https://www.spycolor.com/
# IMPORTANT: Don't use Hex-Colors! Go to the page, search for the Hex-Color, 
# after that add the DECIMAL-Representation to the color field or it will break for Discord!
generate_post_data() {
  cat <<EOF
{
  "content": "Status update",
  "embeds": [{
    "title": "$1",
    "description": "$2",
    "color": "$3"
  }]
}
EOF
}

send_webhook_notification() {
  local title="$1"
  local description="$2"
  local linecolor="$3"

  if [[ -n $WEBHOOK_DEBUG_ENABLED ]] && [[ $WEBHOOK_DEBUG_ENABLED == "true" ]]; then
    # Debug Curl
    curl --ssl-no-revoke -H "Content-Type: application/json" -X POST -d "$(generate_post_data "$title" "$description" "$linecolor")" "$WEBHOOK_URL"
  else
    # Prod Curl
    curl --silent --ssl-no-revoke -H "Content-Type: application/json" -X POST -d "$(generate_post_data "$title" "$description" "$linecolor")" "$WEBHOOK_URL"
  fi
}

#Aliases to use in scripts
send_install_notification() {
  send_webhook_notification "$WEBHOOK_INSTALL_TITLE" "$WEBHOOK_INSTALL_DESCRIPTION" "$WEBHOOK_INSTALL_COLOR"
}
send_restart_planned_notification() {
  send_webhook_notification "$WEBHOOK_RESTART_TITLE" "$WEBHOOK_RESTART_DELAYED_DESCRIPTION" "$WEBHOOK_RESTART_COLOR"
}
send_restart_now_notification() {
  send_webhook_notification "$WEBHOOK_RESTART_TITLE" "$WEBHOOK_RESTART_NOW_DESCRIPTION" "$WEBHOOK_RESTART_COLOR"
}
send_start_notification() {
  send_webhook_notification "$WEBHOOK_START_TITLE" "$WEBHOOK_START_DESCRIPTION" "$WEBHOOK_START_COLOR"
}
send_stop_notification() {
  send_webhook_notification "$WEBHOOK_STOP_TITLE" "$WEBHOOK_STOP_DESCRIPTION" "$WEBHOOK_STOP_COLOR"
}
send_update_notification() {
  send_webhook_notification "$WEBHOOK_UPDATE_TITLE" "$WEBHOOK_UPDATE_DESCRIPTION" "$WEBHOOK_UPDATE_COLOR"
}
send_info_notification() {
  send_webhook_notification "$WEBHOOK_INFO_TITLE" "$1" "$WEBHOOK_INFO_COLOR"
}
