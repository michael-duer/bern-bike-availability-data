#!/usr/bin/env bash
set -u # Exit if an undefined or unset variable is used

# Load environment variables
set -a
source .env # Use absolute path with cron jobs
set +a

echo " Start data collection..."

AUTH="?Authorization=${EMAIL_ADDRESS}"
URL="https://sharedmobility.ch/v2/gbfs/velospot/station_status$AUTH"

DATA_FILE="data/raw/$(date +%F).ndjson" # Create file for each day (e.g. 2026-05-05.ndjson)
LOG_FILE="logs/station_status_collection.log"

# Create folders if they do not already exist
mkdir -p data/raw logs

MAX_RETRIES=5
RETRY_DELAY=15

response=$(
  curl \
    --silent \
    --show-error \
    --fail \
    --location \
    --retry "$MAX_RETRIES" \
    --retry-delay "$RETRY_DELAY" \
    --retry-all-errors \
    --connect-timeout 20 \
    --max-time 120 \
    "$URL" 2>> "$LOG_FILE"
)

curl_exit=$? # Uses exit status of the last command that was executed

# If http request fails, write error in log file
if [ "$curl_exit" -ne 0 ]; then # -ne = not equal
  echo "$(date -Iseconds) ERROR: curl failed with exit code $curl_exit" >> "$LOG_FILE"
  exit 1
fi

# Write an error message in the log file if the request succeeds but the json parsing fails
if ! echo "$response" | jq -e . > /dev/null 2>> "$LOG_FILE"; then
  echo "$(date -Iseconds) ERROR: invalid JSON response" >> "$LOG_FILE"
  echo "$response" >> "$LOG_FILE"
  exit 1
fi

# If the response is valid JSON, append it to the data file
echo "$response" | jq -c "." >> "$DATA_FILE"
echo "$(date -Iseconds) Ok: appended data to $DATA_FILE" >> "$LOG_FILE"

echo "Script finished"