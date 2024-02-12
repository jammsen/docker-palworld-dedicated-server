# shellcheck disable=SC2148
# Function to generate JSON data for the Discord message
# Webpage for COLOR-Calculation - https://www.spycolor.com/
# IMPORTANT: Don't use Hex-Colors! Go to the page, search for the Hex-Color, 
# after that add the DECIMAL-Representation to the color field or it will break for Discord!
generate_post_data() {
  cat <<EOF
{
  "content": "",
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
  local color="$3"
  
  # Debug Curl
  #curl --ssl-no-revoke -H "Content-Type: application/json" -X POST -d "$(generate_post_data "$title" "$description" "$color")" "$WEBHOOK_URL"
  # Prod Curl
  curl --silent --ssl-no-revoke -H "Content-Type: application/json" -X POST -d "$(generate_post_data "$title" "$description" "$color")" "$WEBHOOK_URL"
}

#Aliases to use in scripts
send_start_notification() {
  send_webhook_notification "$WEBHOOK_START_TITLE" "$WEBHOOK_START_DESCRIPTION" "$WEBHOOK_START_COLOR"
}
send_stop_notification() {
  send_webhook_notification "$WEBHOOK_STOP_TITLE" "$WEBHOOK_STOP_DESCRIPTION" "$WEBHOOK_STOP_COLOR"
}
send_install_notification() {
  send_webhook_notification "$WEBHOOK_INSTALL_TITLE" "$WEBHOOK_INSTALL_DESCRIPTION" "$WEBHOOK_INSTALL_COLOR"
}
send_update_notification() {
  send_webhook_notification "$WEBHOOK_UPDATE_TITLE" "$WEBHOOK_UPDATE_DESCRIPTION" "$WEBHOOK_UPDATE_COLOR"
}
send_update_and_validate_notification() {
  send_webhook_notification "$WEBHOOK_UPDATE_VALIDATE_TITLE" "$WEBHOOK_UPDATE_VALIDATE_DESCRIPTION" "$WEBHOOK_UPDATE_VALIDATE_COLOR"
}
