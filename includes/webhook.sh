# Function to generate JSON data for the Discord message
# Webpage for COLOR-Calculation - https://www.spycolor.com/
# IMPORTANT: Dont use Hex-Colors! Go to the page search for the Hex-Color.
# After that add the DECIMAL-Represenetation to the color field or it will break!
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

# Function to send a notification to a webhook
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