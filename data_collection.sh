#!/usr/bin/env bash
set -u # Exit if an undefined or unset variable is used

# Load environment variables
set -a
source .env # Use absolute path with cron jobs
set +a

echo " Start data collection..."

AUTH="?Authorization=${EMAIL_ADDRESS}"
URL="https://sharedmobility.ch/v2/gbfs/velospot/station_status$AUTH"

DATA_FILE="data.ndjson"
ERROR_LOG="collector_errors.log"

MAX_RETRIES=3
RETRY_DELAY=10

response=$(
  curl \
    --silent \
    --show-error \
    --fail \
    --location \
    --retry "$MAX_RETRIES" \
    --retry-delay "$RETRY_DELAY" \
    --retry-all-errors \
    "$URL" 2>> "$ERROR_LOG"
)

curl_exit=$? # Uses exit status of the last command that was executed

# If http request fails, write error in log file
if [ "$curl_exit" -ne 0 ]; then # -ne = not equal
  echo "ERROR: curl failed with exit code $curl_exit" >> "$ERROR_LOG"
  exit 1
fi

# Write an error message in the log file if the request succeeds but the json parsing fails
if ! echo "$response" | jq -e . > /dev/null 2>> "$ERROR_LOG"; then
  echo "ERROR: invalid JSON response" >> "$ERROR_LOG"
  echo "$response" >> "$ERROR_LOG"
  exit 1
fi

# If the response is valid JSON, append it to the data file
echo "$response" | jq -c '.' >> "$DATA_FILE"

echo "Script finished"