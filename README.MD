# Bern Bike Availability Data

Collect and store real-time bike sharing availability data in Bern using the [Shared Mobility Open Data API](https://opendata.swiss/de/dataset/standorte-und-verfugbarkeit-von-shared-mobility-angeboten). The collected data is used to analyze bike availability patterns over time.

## Setup

1. Clone repository

```sh
git clone https://github.com/michael-duer/bern-bike-availability-data.git
cd bern-bike-availability-data
```

2. Configure environment

- Copy the environment template to create your local `.env` file:

```
cp .env.test .env
```

- Add your email address:

```
EMAIL_ADDRESS=your_email@example.com
```

- Make the script executable:

```sh
chmod +x data_collection.sh
```

3. Run the data collection script:

```sh
./data_collection.sh
```

<details>
<summary>Raspberry Pi Setup (Optional)</summary>

To run the data collection continuously, you can use a Raspberry Pi.

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

cp .env.test .env
# edit .env and add your email

chmod +x data_collection.sh
```

### 5. Test the script

Before setting up cron, verify that the script runs successfully:

```sh
./data_collection.sh
```

### 6. Prepare script for cron

Cron runs in a minimal environment and cannot reliably handle relative paths.
Therefore, use absolute paths for `.env`, data, and logs.

```sh
source /home/pi/bern-bike-availability-data/.env # Line 6
DATA_FILE="/home/pi/bern-bike-availability-data/data/$(date +%F).ndjson" # Line 14
ERROR_LOG="/home/pi/bern-bike-availability-data/collector_errors.log" # Line 15
```

### 7. Schedule automatic execution (cron)

Open the crontab:

```sh
crontab -e
```

Add the following line to run the script every 5 minutes:

```sh
*/5 * * * * /home/pi/bern-bike-availability-data/data_collection.sh
```

### 7. Verify data collection

After a few minutes, verify that the cron job is working using the following command. It displays the number of lines of all files in the data folder, which reflects the number of successful requests.

```sh
wc -l data/*.ndjson
```

Check the error log for failed requests or JSON parsing issues:

```sh
tail -f collector_errors.log
```

### 8. Copy data to other machine

Copy collected data files from the Raspberry Pi to the current local folder:

```sh
scp <username>@<ip address>:/home/pi/bern-bike-availability-data/data/ .
```

</details>

## Output

Collected data is stored in daily NDJSON files (`newline-delimited JSON`) to simplify file management and reduce the risk of data loss.

Each line in a file represents a single API snapshot, including the API timestamp `last_updated`:

```json
{"last_updated":1777830904, ...}
{"last_updated":1777838104, ...}
```

For easier inspection (e.g. in VS Code), the data can be converted into a JSON array:

```sh
jq -s '.' data.ndjson > data.json
```

## Data Collection Plan

1. Use the GBFS API to collect all station status data at regular intervals
2. Use the `station_information` endpoint to identify stations located in Bern
3. Filter the collected data locally by `station_id`
4. Get additional information about stations (e.g. address, gps) using the REST API

## API Overview

This project uses two APIs:

- **GBFS API** for repeated collection of station status data
- **REST API** for filtering and identifying stations in Bern

### REST API

The REST API allows querying stations within a geographic radius.
This is mainly used to identify `station_id`s belonging to Bern. These IDs are then used to filter the data collected via the GBFS API.

#### Get all Providers

```sh
curl -X 'GET' 'https://api.sharedmobility.ch/v1/sharedmobility/providers' -H 'accept: application/json'
```

#### Get all stations in radius around gps coordinates of Bern

The following request returns a list of all stations inside the specified radius (`Tolerance`). The `station_status_num_vehicle_available` attribute provides you with the number of bikes available but does not specify the type (e.g. e-bike).

```sh
curl -X 'GET' \
  'https://api.sharedmobility.ch/v1/sharedmobility/identify?' \
  'filters=ch.bfe.sharedmobility.provider.id%3Dvelospot' \
  '&filters=ch.bfe.sharedmobility.pickup_type%3Dstation_based' \
  '&Geometry=7.4474%2C46.9480' \
  '&Tolerance=5000' \
  '&offset=0' \
  '&geometryFormat=esrijson' \
  -H 'accept: application/json'
```

### GBFS 2.3 API

#### Station status

Using the following url we can request the station status of all Velospot stations in Switzerland.

```sh
https://sharedmobility.ch/v2/gbfs/velospot/station_status?Authorization=gbfs@sharedmobility.ch
```

#### Available API endpoints for providers

Get a list of all endpoints available for **velospot**:

```sh
https://sharedmobility.ch/v2/gbfs/velospot/gbfs?Authorization=gbfs@sharedmobility.ch
```

**System information**

```sh
https://sharedmobility.ch/v2/gbfs/velospot/system_information?Authorization=gbfs@sharedmobility.ch
```

**Station information**

```sh
https://sharedmobility.ch/v2/gbfs/velospot/station_information?Authorization=gbfs@sharedmobility.ch
```

**Station Status**

```sh
https://sharedmobility.ch/v2/gbfs/velospot/station_status?Authorization=gbfs@sharedmobility.ch
```

**Vehicle Types**

```sh
https://sharedmobility.ch/v2/gbfs/velospot/vehicle_types?Authorization=gbfs@sharedmobility.ch
```

## References

- Shared Mobility REST API: https://github.com/SFOE/sharedmobility/blob/main/Sharedmobility.ch-API.md
- GBFS API: https://github.com/SFOE/sharedmobility/blob/main/Access%20the%20data.md
