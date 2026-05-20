for type trip 
request body 
{
  "carpool_type": "trip",
  "start_lat": 30.0444,
  "start_lng": 31.2357,
  "end_lat": 30.0626,
  "end_lng": 31.2497,
  "start_time": "2026-05-25 08:00:00",
  "price": 150,
  "seats_available": 3,
  "allowed_gender": "both"
}
response 
{
    "response_code": "default_store_200",
    "message": "Successfully added",
    "total_size": null,
    "limit": null,
    "offset": null,
    "data": {
        "route_id": 404,
        "carpool_type": "trip",
        "is_recurring": false,
        "expires_at": null
    },
    "errors": []
}
-------
travel
request body 
{
  "carpool_type": "travel",
  "start_time": "2026-05-25 06:00:00",
  "boarding_point_start_id": 1,
  "boarding_point_end_id": 3,
  "price": 300,
  "seats_available": 4,
  "is_ac": true,
  "allowed_gender": "both"
}
response 
{
    "response_code": "default_store_200",
    "message": "Successfully added",
    "total_size": null,
    "limit": null,
    "offset": null,
    "data": {
        "route_id": 405,
        "carpool_type": "travel",
        "is_recurring": false,
        "expires_at": null
    },
    "errors": []
}
---------
type routine
request body
{
  "carpool_type": "routine",
  "start_time": "2026-05-18 07:30:00",
  "start_lat": 30.05,
  "start_lng": 31.24,
  "end_lat": 30.10,
  "end_lng": 31.30,
  "departure_time": "07:30",
  "return_time": "17:00",
  "price": 2000,
  "seats_available": 3
}
response 
{
    "response_code": "default_store_200",
    "message": "Successfully added",
    "total_size": null,
    "limit": null,
    "offset": null,
    "data": {
        "route_id": 406,
        "carpool_type": "routine",
        "is_recurring": true,
        "expires_at": "2026-05-31"
    },
    "errors": []
}
-----------
for type north_coast
request body 
{
  "carpool_type": "north_coast",
  "start_time": "2026-06-01 09:00:00",
  "start_lat": 31.10,
  "start_lng": 29.70,
  "end_lat": 31.05,
  "end_lng": 29.75,
  "price": 80,
  "seats_available": 3
}
response
{
    "response_code": "default_store_200",
    "message": "Successfully added",
    "total_size": null,
    "limit": null,
    "offset": null,
    "data": {
        "route_id": 407,
        "carpool_type": "north_coast",
        "is_recurring": false,
        "expires_at": null
    },
    "errors": []
}
