#!/bin/bash

# Exit script immediately if a command fails
set -e

# Create outputs directory if it does not exist
mkdir -p outputs

echo "Combining NDJSON files..."

# Combine all NDJSON files while excluding:
# - already combined files
# - hidden macOS metadata files
find data -name "*.ndjson" ! -name "combined.ndjson" ! -name "._*" -exec cat {} + > data/combined.ndjson

echo "Filtering Bern station metadata..."

# Filter Bern stations
jq '.data.stations[]| select(.region_id == "44" and (.name | contains("Bern")))| {station_id,name,region_id,lat,lon}' data/station_information.json > outputs/bern_stations.json

echo "Flattening bike availability data..."

# Flatten bike availability data
#jq '.last_updated as $timestamp| .data.stations[]| {timestamp: $timestamp,last_reported,station_id,total_bikes: .num_bikes_available,ebikes:(.vehicle_types_available[]| select(.vehicle_type_id == "ebike")| .count),mbikes:(.vehicle_types_available[]| select(.vehicle_type_id == "mbike")| .count),hbikes:(.vehicle_types_available[]| select(.vehicle_type_id == "hbike")| .count)}' data/combined.ndjson > outputs/bike_flat.json
# Create raw flattened data
jq '.last_updated as $timestamp| .data.stations[]| {timestamp: $timestamp,last_reported,station_id,total_bikes: .num_bikes_available,ebikes:(.vehicle_types_available[] | select(.vehicle_type_id == "ebike") | .count),mbikes:(.vehicle_types_available[] | select(.vehicle_type_id == "mbike") | .count),hbikes:(.vehicle_types_available[] | select(.vehicle_type_id == "hbike") | .count)}' data/combined.ndjson > outputs/bike_flat_raw.json
# Check duplicates
echo "Checking duplicates..."

jq -r '[.timestamp,.station_id]| @tsv' outputs/bike_flat_raw.json | sort | uniq -c | awk '$1 > 1'> outputs/duplicates_count.txt

# Remove duplicates
jq -s 'unique_by([.timestamp, .station_id])[]' outputs/bike_flat_raw.json > outputs/bike_flat.json

# Report how many where removed
RAW_COUNT=$(wc -l < outputs/bike_flat_raw.json)
DEDUP_COUNT=$(wc -l < outputs/bike_flat.json)

REMOVED=$((RAW_COUNT - DEDUP_COUNT))

echo "Removed $REMOVED duplicate rows."

echo "Creating CSV files..."

# Convert station metadata to CSV
jq -r '[.station_id,.name,.lat,.lon]| @csv' outputs/bern_stations.json > outputs/bern_stations.csv

# Add station CSV header
(echo 'station_id,station_name,lat,lon';cat outputs/bern_stations.csv) > outputs/bern_stations_header.csv

# Convert bike data to CSV with readable timestamps
jq -r '[(.timestamp | strflocaltime("%Y-%m-%d %H:%M:%S")),(.last_reported | strflocaltime("%Y-%m-%d %H:%M:%S")),.station_id,.total_bikes,.ebikes,.mbikes,.hbikes]| @csv' outputs/bike_flat.json > outputs/bike_flat.csv

# Add bike CSV header
(echo 'datetime,last_reported,station_id,total_bikes,ebikes,mbikes,hbikes'; cat outputs/bike_flat.csv) > outputs/bike_flat_header.csv

echo "Converting JSON streams into arrays..."

# Convert JSON streams into arrays
jq -s '.' outputs/bern_stations.json > outputs/bern_stations_array.json
jq -s '.' outputs/bike_flat.json > outputs/bike_flat_array.json

echo "Joining station metadata with bike data..."

# Join station metadata with bike data
jq -n -r --slurpfile stations outputs/bern_stations_array.json --slurpfile bikes outputs/bike_flat_array.json '$bikes[0][] as $bike| ($stations[0][]| select(.station_id == $bike.station_id)) as $station| [($bike.timestamp | strflocaltime("%Y-%m-%d %H:%M:%S")),($bike.last_reported | strflocaltime("%Y-%m-%d %H:%M:%S")),$bike.station_id,$station.name,$station.lat,$station.lon,$bike.total_bikes,$bike.ebikes,$bike.mbikes,$bike.hbikes]| @csv' > outputs/final_bike_table.csv

# Add final CSV header
(echo 'datetime,last_reported,station_id,station_name,lat,lon,total_bikes,ebikes,mbikes,hbikes'; cat outputs/final_bike_table.csv) > outputs/final_bike_table_header.csv

echo "Preview of final output:"
head outputs/final_bike_table_header.csv

echo "Pipeline completed successfully."