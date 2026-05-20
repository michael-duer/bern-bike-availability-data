#!/bin/bash

# Exit script immediately if a command fails
set -e

# Create output directory if it does not exist
mkdir -p data/processed

COMBINED_FILE="data/processed/combined.ndjson"
STATION_METADATA="data/metadata/station_information.json"
FINAL_DATASET="data/processed/bike_availability_bern.csv"

echo "Combining NDJSON files..."

# Combine all NDJSON files while excluding:
# - already combined files
# - hidden macOS metadata files
find data/raw -name "*.ndjson" ! -name "combined.ndjson" ! -name "._*" -exec cat {} + > "$COMBINED_FILE"

echo "Filtering Bern station metadata..."

# Filter Bern stations
jq '.data.stations[]| select(.region_id == "44" and (.name | contains("Bern")))| {station_id,name,region_id,lat,lon}' "$STATION_METADATA" > data/processed/bern_stations.json

echo "Flattening bike availability data..."

# Flatten bike availability data
#jq '.last_updated as $timestamp| .data.stations[]| {timestamp: $timestamp,last_reported,station_id,total_bikes: .num_bikes_available,ebikes:(.vehicle_types_available[]| select(.vehicle_type_id == "ebike")| .count),mbikes:(.vehicle_types_available[]| select(.vehicle_type_id == "mbike")| .count),hbikes:(.vehicle_types_available[]| select(.vehicle_type_id == "hbike")| .count)}' data/processed/combined.ndjson > data/processed/bike_flat.json
# Create raw flattened data
jq '.last_updated as $timestamp| .data.stations[]| {timestamp: $timestamp,last_reported,station_id,total_bikes: .num_bikes_available,ebikes:(.vehicle_types_available[] | select(.vehicle_type_id == "ebike") | .count),mbikes:(.vehicle_types_available[] | select(.vehicle_type_id == "mbike") | .count),hbikes:(.vehicle_types_available[] | select(.vehicle_type_id == "hbike") | .count)}' "$COMBINED_FILE" > data/processed/bike_flat_raw.json
# Check duplicates
echo "Checking duplicates..."

jq -r '[.timestamp,.station_id]| @tsv' data/processed/bike_flat_raw.json | sort | uniq -c | awk '$1 > 1'> data/processed/duplicates_count.txt

# Remove duplicates
jq -s 'unique_by([.timestamp, .station_id])[]' data/processed/bike_flat_raw.json > data/processed/bike_flat.json

# Report how many where removed
RAW_COUNT=$(wc -l < data/processed/bike_flat_raw.json)
DEDUP_COUNT=$(wc -l < data/processed/bike_flat.json)

REMOVED=$((RAW_COUNT - DEDUP_COUNT))

echo "Removed $REMOVED duplicate rows."

echo "Creating CSV files..."

# Convert station metadata to CSV
jq -r '[.station_id,.name,.lat,.lon]| @csv' data/processed/bern_stations.json > data/processed/bern_stations.csv

# Add station CSV header
(echo 'station_id,station_name,lat,lon';cat data/processed/bern_stations.csv) > data/processed/bern_stations_header.csv

# Convert bike data to CSV with readable timestamps
jq -r '[(.timestamp | strflocaltime("%Y-%m-%d %H:%M:%S")),(.last_reported | strflocaltime("%Y-%m-%d %H:%M:%S")),.station_id,.total_bikes,.ebikes,.mbikes,.hbikes]| @csv' data/processed/bike_flat.json > data/processed/bike_flat.csv

# Add bike CSV header
(echo 'datetime,last_reported,station_id,total_bikes,ebikes,mbikes,hbikes'; cat data/processed/bike_flat.csv) > data/processed/bike_flat_header.csv

echo "Converting JSON streams into arrays..."

# Convert JSON streams into arrays
jq -s '.' data/processed/bern_stations.json > data/processed/bern_stations_array.json
jq -s '.' data/processed/bike_flat.json > data/processed/bike_flat_array.json

echo "Joining station metadata with bike data..."

# Join station metadata with bike data
jq -n -r --slurpfile stations data/processed/bern_stations_array.json --slurpfile bikes data/processed/bike_flat_array.json '$bikes[0][] as $bike| ($stations[0][]| select(.station_id == $bike.station_id)) as $station| [($bike.timestamp | strflocaltime("%Y-%m-%d %H:%M:%S")),($bike.last_reported | strflocaltime("%Y-%m-%d %H:%M:%S")),$bike.station_id,$station.name,$station.lat,$station.lon,$bike.total_bikes,$bike.ebikes,$bike.mbikes,$bike.hbikes]| @csv' > data/processed/final_bike_table.csv

# Add final CSV header
(echo 'datetime,last_reported,station_id,station_name,lat,lon,total_bikes,ebikes,mbikes,hbikes'; cat data/processed/final_bike_table.csv) > "$FINAL_DATASET"

echo "Preview of final output:"
head "$FINAL_DATASET"

echo "Pipeline completed successfully."