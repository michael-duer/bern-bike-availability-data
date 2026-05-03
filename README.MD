# Bern Bike Availability Data

Collect real-time PubliBike station availability data in Bern using [Shared Mobility Open Data API](https://opendata.swiss/de/dataset/standorte-und-verfugbarkeit-von-shared-mobility-angeboten).

## API Requests
The REST api is very convenient for spatial filtering so you can simple request all stations in a radius (`Tolerance`) around a point (`Geometry`).

The GBFS 2.3 API on the other hand is designed for station status feeds and repeated data collection. (Using this API requires you to use a valid email address in the header of the request.)

It is probably best to first use the REST API to get the id of all stations and then use the GBFS 2.3 API to collect the data over time.

### REST api
#### Get all Providors
```sh
curl -X 'GET' 'https://api.sharedmobility.ch/v1/sharedmobility/providers' -H 'accept: application/json'
```

#### Get all Publibike stations in Bern
With the following request you get a list of all stations inside the specified radius. The `station_status_num_vehicle_available` attribute provides you with the number of bikes available but does not specify the type. 
```sh
curl -X 'GET' \ 
  'https://api.sharedmobility.ch/v1/sharedmobility/identify?' \ 
  'filters=ch.bfe.sharedmobility.provider.id%3Dpublibike' \ 
  '&filters=ch.bfe.sharedmobility.pickup_type%3Dstation_based' \ 
  '&Geometry=7.4474%2C46.9480' \ 
  '&Tolerance=5000' \ 
  '&offset=0' \ 
  '&geometryFormat=esrijson' \ 
  -H 'accept: application/json'
```

There are about 250 Publibike stations in a 5km radius around the center of Bern.