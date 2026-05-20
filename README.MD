# Bern Bike Availability Data

This project collects and processes real-time Velospot bike availability data for stations in Bern using the [Shared Mobility Open Data API](https://opendata.swiss/de/dataset/standorte-und-verfugbarkeit-von-shared-mobility-angeboten).

The goal is to analyze spatial and temporal patterns in bike availability over one week. Since the API provides station availability snapshots rather than individual trip records, changes in the number of available bikes are used as a proxy for station activity and turnover.

## Project structure

```txt
bern-bike-availability-data/
├── data/
│   ├── metadata/                         # Static/reference data from the API
│   │   ├── providers.json                # List of mobility providers
│   │   ├── regions.json                  # List of available regions
│   │   └── station_information.json      # Station metadata such as name and coordinates
│   ├── raw/                              # Raw station status snapshots collected from the API
│   │   ├── 2026-05-05.ndjson
│   │   ├── 2026-05-06.ndjson
│   │   └── ...
│   └── processed/                        # Final datasets
│       └── bike_availability_bern.csv
├── scripts/
│   ├── fetch_station_status.sh           # Fetches station status data from the API
│   └── prepare_bike_dataset.sh           # Filters, transforms and joins data into the final dataset
├── logs/
│   └── station_status_collection.log     # Log file for successful data collection and errors
├── tableau/                              # Tableau workbook
├── .env.example                          # Template for required environment variables
├── .gitignore
└── README.md
```

## Setup

### 1. Clone repository

```sh
git clone https://github.com/michael-duer/bern-bike-availability-data.git
cd bern-bike-availability-data
```

### 2. Configure environment

Copy the environment template:

```
cp .env.example .env
```

Add your email address to `.env`:

```
EMAIL_ADDRESS=your_email@example.com
```

### 3. Install dependencies

The Bash scripts require `curl` and `jq`.

```sh
# On Linux
sudo apt install curl jq
# On Mac using Homebrew
brew install curl jq
```

For Windows, the recommended setup is Windows Subsystem for Linux (WSL). After installing WSL, use the Linux commands above.

### 4. Make scripts executable

If the scripts are not executable after cloning the repository, run:

```sh
chmod +x scripts/fetch_station_status.sh
chmod +x scripts/prepare_bike_dataset.sh
```

<details>
<summary>Raspberry Pi Setup (Optional)</summary>

To collect data continuously, the data collection script can be scheduled on a Raspberry Pi using cron.

### 1. Prepare the Raspberry Pi

- Flash Raspberry Pi OS
- Enable SSH
- Connect the Pi to your network

### 2. Connect via SSH

```sh
ssh <username>@<ip address>
```

### 3. Install updates and dependencies

```sh
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl jq
```

### 4. Clone and set up the project

```sh
git clone https://github.com/michael-duer/bern-bike-availability-data.git
cd bern-bike-availability-data

cp .env.example .env
# edit .env and add your email

chmod +x scripts/fetch_station_status.sh
chmod +x scripts/prepare_bike_dataset.sh
```

### 5. Test the script

Before setting up cron, verify that the script runs successfully:

```sh
./scripts/fetch_station_status.sh
```

### 6. Prepare script for cron

Cron runs in a minimal environment and may not handle relative paths reliably. For cron usage, use absolute paths for `.env`, data files, and logs inside scripts/fetch_station_status.sh.

```sh
source /home/<username>/bern-bike-availability-data/.env # Line 6
DATA_FILE="/home/<username>/bern-bike-availability-data/data/raw/$(date +%F).ndjson" # Line 14
LOG_FILE="/home/<username>/bern-bike-availability-data/logs/station_status_collection.log" # Line 15
```

### 7. Schedule automatic execution

Open the crontab:

```sh
crontab -e
```

Add the following line to run the script every 5 minutes:

```sh
*/5 * * * * /home/<username>/bern-bike-availability-data/scripts/fetch_station_status.sh
```

### 8. Verify data collection

After a few minutes, check whether new rows are being added:

```sh
wc -l data/raw/*.ndjson
```

Check the log file for successful requests or errors:

```sh
tail -f logs/station_status_collection.log
```

### 9. Copy data to another machine

Copy collected raw data files from the Raspberry Pi to your local machine:

```sh
scp <username>@<ip address>:/home/<username>/bern-bike-availability-data/data/raw/*.ndjson ./data/raw/
```

</details>

## Usage

### Collect station status data

Run the data collection script:

```sh
./scripts/fetch_station_status.sh
```

The script appends one API snapshot to the daily NDJSON file in `data/raw/`.

### Prepare the dataset

After collecting the data, run:

```sh
./scripts/prepare_bike_dataset.sh
```

This script combines the raw NDJSON files, filters stations in Bern, flattens the station status data, removes duplicates, joins station metadata, and creates the final CSV dataset.

The final dataset is stored in:

```sh
data/processed/bike_availability_bern.csv
```

## Data format

Raw data is stored as daily NDJSON files, where each line represents one API snapshot, including a timestamp `last_updated` from the API:

```json
{"last_updated":1777830904,"ttl":60,"version":"2.3","data":{}}
{"last_updated":1777838104,"ttl":60,"version":"2.3","data":{}}
```

For easier inspection (e.g. in VS Code), an NDJSON file can be converted into a JSON array:

```sh
jq -s '.' data/raw/2026-05-05.ndjson > data/raw/2026-05-05.json
```

## API overview

This project uses two Shared Mobility APIs:

- **GBFS API:** Used for repeated collection of Velospot station status snapshots, including the number and type of available bikes at each station.
- **REST API:** Used to retrieve reference and station metadata, such as providers, regions, station locations, and coordinates. This information is used to identify and filter stations in Bern.

The final dataset combines real-time availability data with station metadata for spatial and temporal analysis in Tableau.

## References

- Data Source: https://opendata.swiss/de/dataset/standorte-und-verfugbarkeit-von-shared-mobility-angeboten
- Shared Mobility REST API: https://github.com/SFOE/sharedmobility/blob/main/Sharedmobility.ch-API.md
- Shared Mobility GBFS API: https://github.com/SFOE/sharedmobility/blob/main/Access%20the%20data.md
