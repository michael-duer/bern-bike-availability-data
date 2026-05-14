import pandas as pd
import matplotlib.pyplot as plt

# Read filtered CSV
df = pd.read_csv("bern_bike_filtered.csv")

# Convert datetime column
df["datetime"] = pd.to_datetime(df["datetime"])
df["station_time"] = pd.to_datetime(df["station_time"])

stations=len(pd.unique(df['station_id']))

# filter stations in bern

bike_df_clean = bike_df.drop_duplicates()#
bike_df.shape
bike_df[]
bike_df_clean.shape
df = bike_df_clean.copy()
df.head()
df.describe()
df.columns
station_summary["calculated_total"] = (
    station_summary["ebikes"] +
    station_summary["mbikes"]
)
station_summary[
    ["total_bikes", "calculated_total"]
].head()

station_260 = bike_df[
    bike_df["station_id"] == '260'
]
station_1222 = bike_df[
    bike_df["station_id"] == '1222'
]
station_1222 = bike_df[
    bike_df["station_id"] == '1678'
]


station_260.head()
station_1222.head()

station_260[
    station_260["timestamp"] == 1778021704
]

station_260_clean = station_260.drop_duplicates(subset="timestamp")
station_1222_clean = station_1222.drop_duplicates(subset="station_time")
station_260_clean = station_260_clean.sort_values("datetime")
station_1222_clean = station_1222_clean.sort_values("station_time")

plt.figure(figsize=(14,6))

plt.plot(
    station_260_clean["datetime"],
    station_260_clean["total_bikes"],
    marker="o",
    label="Total Bikes"
)

plt.plot(
    station_260_clean["datetime"],
    station_260_clean["ebikes"],
    marker="o",
    label="E-Bikes"
)

plt.plot(
    station_260_clean["datetime"],
    station_260_clean["mbikes"],
    marker="o",
    label="Normal Bikes"
)

plt.xlabel("Time")

plt.ylabel("Available Bikes")

plt.title(
    "Temporal Bike Availability Pattern - Station 260"
)

plt.legend()

plt.grid(True)

plt.tight_layout()

plt.figure(figsize=(14,6))

plt.plot(
    station_260_clean["datetime"],
    station_260_clean["total_bikes"],
    marker="o",
    label="Total Bikes"
)

plt.plot(
    station_260_clean["datetime"],
    station_260_clean["ebikes"],
    marker="o",
    label="E-Bikes"
)

plt.plot(
    station_260_clean["datetime"],
    station_260_clean["mbikes"],
    marker="o",
    label="Normal Bikes"
)

plt.xlabel("Time")

plt.ylabel("Available Bikes")

plt.title(
    "Temporal Bike Availability Pattern - Station 260"
)

plt.legend()

plt.grid(True)

plt.tight_layout()

plt.show()


## Plot for station 1222
plt.figure(figsize=(14,6))

plt.plot(
    station_1222_clean["station_time"],
    station_1222_clean["total_bikes"],
    marker="o",
    label="Total Bikes"
)

plt.plot(
    station_1222_clean["station_time"],
    station_1222_clean["ebikes"],
    marker="o",
    label="E-Bikes"
)

plt.plot(
    station_1222_clean["station_time"],
    station_1222_clean["mbikes"],
    marker="o",
    label="Normal Bikes"
)

plt.xlabel("Time")

plt.ylabel("Available Bikes")

plt.title(
    "Temporal Bike Availability Pattern - Station 1222"
)

plt.legend()

plt.grid(True)

plt.tight_layout()
plt.show()

# Group by datetime
time_summary = df.groupby("datetime")[[
    "total_bikes",
    "ebikes",
    "mbikes"
]].sum()

# Create figure
plt.figure(figsize=(12,6))

# Plot total bikes
plt.plot(
    time_summary.index,
    time_summary["total_bikes"],
    label="Total Bikes"
)

# Plot e-bikes
plt.plot(
    time_summary.index,
    time_summary["ebikes"],
    label="E-Bikes"
)

# Plot normal bikes
plt.plot(
    time_summary.index,
    time_summary["mbikes"],
    label="Normal Bikes"
)

# Labels
plt.xlabel("Time")
plt.ylabel("Number of Bikes")

# Title
plt.title("Bern Bike Availability Over Time")

# Legend
plt.legend()

# Layout
plt.tight_layout()

# Show plot
plt.show()

### Stations based aggregation
station_summary = bike_df.groupby("station_id")[[
    "total_bikes",
    "ebikes",
    "mbikes"
]].mean()


station_summary = station_summary.sort_values(
    by="total_bikes",
    ascending=False
)

busiest_station = station_summary.idxmax()

top20 = station_summary.head(20)

plt.figure(figsize=(14,6))

plt.bar(
    top20.index.astype(str),
    top20["total_bikes"]
)

plt.xlabel("Station ID")

plt.ylabel("Average Bikes Available")

plt.title("Top 20 Stations by Average Bike Availability")

plt.xticks(rotation=90)

plt.grid(True)

plt.show()

