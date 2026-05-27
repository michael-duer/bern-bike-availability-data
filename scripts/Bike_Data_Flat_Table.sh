#!/bin/bash

# Exit immediately if a command fails
set -e

# Create outputs directory if it does not exist
mkdir -p outputs

echo "Combining NDJSON files..."

# Combine all NDJSON files while excluding:
# - already combined files
# - hidden macOS metadata files
find data -name "*.ndjson" \
! -name "combined.ndjson" \
! -name "._*" \
-exec cat {} + > data/combined.ndjson

echo "Creating station metadata..."

# Create temporary station metadata table
jq '
.data.stations[]

| select(
    .region_id == "44"
    and
    (.name | contains("Bern"))
  )

| {
    station_id,
    name,
    lat,
    lon,
    capacity
  }

' data/station_information.json \
| jq -s '.' \
> stations_tmp.json

echo "Creating bike observations..."

# Create temporary flattened bike table
jq '

.last_updated as $timestamp

| .data.stations[]

| {

    timestamp: $timestamp,

    last_reported,

    station_id,

    total_bikes: .num_bikes_available,

    ebikes:
    (
        [
            .vehicle_types_available[]
            | select(.vehicle_type_id == "ebike")
            | .count
        ] | add
    ) // 0,

    mbikes:
    (
        [
            .vehicle_types_available[]
            | select(.vehicle_type_id == "mbike")
            | .count
        ] | add
    ) // 0,

    hbikes:
    (
        [
            .vehicle_types_available[]
            | select(.vehicle_type_id == "hbike")
            | .count
        ] | add
    ) // 0

  }

' data/combined.ndjson \
| jq -s 'unique_by([.timestamp, .station_id])' \
> bikes_tmp.json

echo "Creating final bike table..."

(
echo 'datetime,last_reported,station_id,station_name,lat,lon,capacity,total_bikes,ebikes,mbikes,hbikes'

jq -n -r \
--slurpfile stations stations_tmp.json \
--slurpfile bikes bikes_tmp.json '

$bikes[0][] as $bike

| (

    $stations[0][]

    | select(.station_id == $bike.station_id)

  ) as $station

| [

    ($bike.timestamp | strflocaltime("%Y-%m-%d %H:%M:%S")),

    ($bike.last_reported | strflocaltime("%Y-%m-%d %H:%M:%S")),

    $bike.station_id,

    $station.name,

    $station.lat,

    $station.lon,

    $station.capacity,

    $bike.total_bikes,

    $bike.ebikes,

    $bike.mbikes,

    $bike.hbikes

  ]

| @csv
'

) > outputs/final_bike_table.csv

echo "Cleaning temporary files..."

rm -f stations_tmp.json
rm -f bikes_tmp.json

echo "Preview of final output:"

head outputs/final_bike_table.csv

echo "Pipeline completed successfully."