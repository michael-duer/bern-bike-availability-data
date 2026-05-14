import json
import pandas as pd
from fontTools.diff import summarize

# Path to NDJSON file
FILE_PATH = "2026-05-06.ndjson"

# Empty list to store extracted rows
all_rows = []

# Read file line by line
with open(FILE_PATH, "r") as file:

    for line in file:

        # Convert line into Python dictionary
        data = json.loads(line)

        # Extract timestamp
        timestamp = data.get("last_updated")

        # Extract stations list
        stations = data.get("data", {}).get("stations", [])

        # Loop through all stations
        for station in stations:

            station_id = station.get("station_id")
            total_bikes = station.get("num_bikes_available", 0)
            renting = station.get("is_renting")
            returning = station.get("is_returning")
            installed = station.get("is_installed")
            station_time_stamp= station.get("last_reported")

            # Default counts
            ebikes = 0
            mbikes = 0
            hbikes = 0

            # Extract bike type counts
            vehicle_types = station.get("vehicle_types_available", [])

            for vehicle in vehicle_types:

                vehicle_type = vehicle.get("vehicle_type_id")
                count = vehicle.get("count", 0)

                if vehicle_type == "ebike":
                    ebikes = count

                elif vehicle_type == "mbike":
                    mbikes = count

                elif vehicle_type == "hbike":
                    hbikes = count

            # Store extracted row
            all_rows.append({
                "timestamp": timestamp,
                "station_id": station_id,
                "total_bikes": total_bikes,
                "ebikes": ebikes,
                "mbikes": mbikes,
                "hbikes": hbikes,
                "is_renting": renting,
                "is_returning": returning,
                "is_installed": installed,
                "last_reported": station_time_stamp
            })

# Convert to DataFrame
bike_df = pd.DataFrame(all_rows)

# Convert timestamp to readable datetime
bike_df["datetime"] = pd.to_datetime(
    bike_df["timestamp"],
    unit="s"
)
bike_df["station_time"] = pd.to_datetime(
    bike_df["last_reported"],
    unit="s"
)


# Show first rows
print(bike_df.head())
bike_df.describe()
bike_df.columns
bike_df['hbikes'].mean
bike_df['hbikes'].max

# Save cleaned data
bike_df.to_csv("bern_bike_filtered.csv", index=False)

print("\nFiltered file saved as bern_bike_filtered.csv")