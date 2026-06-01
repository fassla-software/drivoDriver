import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../domain/models/simple_passenger_model.dart';
import '../domain/models/simple_trip_model.dart';
import 'passenger_map_marker_helper.dart';

class SimpleTripMapController extends GetxController {
  final SimpleTripModel trip;

  SimpleTripMapController({required this.trip});

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  GoogleMapController? _mapController;
  Position? _currentPosition;

  // Map data
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _mainRoutePoints = [];
  List<LatLng> _driverToStartRoute = [];
  List<LatLng> _passengerRoutePoints = [];
  bool _isFollowingDriver = false;

  // Getters
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  List<LatLng> get mainRoutePoints => _mainRoutePoints;
  List<LatLng> get driverToStartRoute => _driverToStartRoute;
  List<LatLng> get passengerRoutePoints => _passengerRoutePoints;
  bool get isFollowingDriver => _isFollowingDriver;

  LatLng get initialPosition {
    if (trip.startCoordinates != null && trip.startCoordinates!.length >= 2) {
      // API returns [longitude, latitude] but Google Maps expects (latitude, longitude)
      return LatLng(trip.startCoordinates![1], trip.startCoordinates![0]);
    }
    return const LatLng(30.0444, 31.2357); // Cairo default
  }

  String get remainingDistance {
    if (_mainRoutePoints.isEmpty) return 'Calculating...';
    double distance = _calculateTotalRouteDistance();
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.toInt()} m';
  }

  String get estimatedTimeToDestination {
    if (_mainRoutePoints.isEmpty) return 'Calculating...';
    double distance = _calculateTotalRouteDistance();
    // Assume average speed of 40 km/h in city traffic
    double hours = (distance / 1000) / 40;
    int minutes = (hours * 60).round();
    if (minutes < 1) return '< 1 min';
    if (minutes >= 60) {
      return '${(minutes / 60).floor()} hr ${minutes % 60} min';
    }
    return '$minutes min';
  }

  /// Calculate total route distance from polyline points in meters
  double _calculateTotalRouteDistance() {
    if (_mainRoutePoints.length < 2) return 0.0;
    double totalDistance = 0.0;
    for (int i = 0; i < _mainRoutePoints.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        _mainRoutePoints[i].latitude,
        _mainRoutePoints[i].longitude,
        _mainRoutePoints[i + 1].latitude,
        _mainRoutePoints[i + 1].longitude,
      );
    }
    return totalDistance;
  }

  String get polylineSource {
    if (trip.encodedPolyline != null && trip.encodedPolyline!.isNotEmpty) {
      return 'Trip Polyline (${trip.encodedPolyline!.length} chars)';
    }
    return 'No polyline available';
  }

  // أضف متغير لمفتاح Google Maps Directions API
  // static const String googleMapsApiKey =
  //     'AIzaSyAxbSlJiU3JKv7zdfm3GL7dFsEeu495tbs'; // ضع مفتاحك هنا

  /// جلب مسار القيادة الحقيقي من Google Directions API
  // Future<List<LatLng>> getRoutePolyline(List<LatLng> points) async {
  //   if (points.length < 2) return points;
  //   final origin = '${points.first.latitude},${points.first.longitude}';
  //   final destination = '${points.last.latitude},${points.last.longitude}';
  //   String waypoints = '';
  //   if (points.length > 2) {
  //     waypoints = points
  //         .sublist(1, points.length - 1)
  //         .map((p) => '${p.latitude},${p.longitude}')
  //         .join('|');
  //   }
  //   final url =
  //       'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}&key=$googleMapsApiKey&mode=driving';
  //   print('=== Directions API URL: $url ===');
  //   final response = await http.get(Uri.parse(url));
  //   final data = json.decode(response.body);
  //   if (data['routes'] != null && data['routes'].isNotEmpty) {
  //     final polyline = data['routes'][0]['overview_polyline']['points'];
  //     return decodePolyline(polyline);
  //   }
  //   print('=== Directions API error: ${data['status']} ===');
  //   return points;
  // }

  /// فك تشفير polyline
  List<LatLng> decodePolyline(String encoded) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(encoded);
    return result.map((p) => LatLng(p.latitude, p.longitude)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    print(
        '=== SimpleTripMapController initialized for trip ID: ${trip.id} ===');
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    // Fit all markers once the map is actually ready
    if (_markers.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _fitMarkersOnMap();
      });
    }
  }

  Future<void> initializeMap() async {
    try {
      print('=== Initializing map for trip ID: ${trip.id} ===');
      print('=== Trip data: ===');
      print('=== Start coordinates: ${trip.startCoordinates} ===');
      print('=== End coordinates: ${trip.endCoordinates} ===');
      print(
          '=== Passenger coordinates count: ${trip.passengerCoordinates?.length ?? 0} ===');
      print('=== Passengers count: ${trip.passengers?.length ?? 0} ===');

      _isLoading = true;
      update();

      // Get current location
      await _getCurrentLocation();

      // Create markers (passenger avatars on map)
      await _createMarkers();

      // Create polylines
      _createPolylines();

      // Load route data
      await _loadMainRoute();
      // await _loadDriverToStartRoute();

      _isLoading = false;
      update();

      // _fitMarkersOnMap() is primarily called from setMapController()
      // when the GoogleMap widget fires onMapCreated. However, if onMapCreated
      // already fired (race condition), fit markers now.
      if (_mapController != null && _markers.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _fitMarkersOnMap();
        });
      }
    } catch (e) {
      print('=== Error initializing map: $e ===');
      _isLoading = false;
      update();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('=== Location services are disabled ===');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('=== Location permissions are denied ===');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('=== Location permissions are permanently denied ===');
        return;
      }

      // Add timeout to prevent infinite loading
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('=== Location request timeout ===');
          throw Exception('Location request timeout');
        },
      );

      print(
          '=== Current position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude} ===');
    } catch (e) {
      print('=== Error getting current location: $e ===');
      // Don't throw error, just continue without location
    }
  }

  SimplePassengerModel? _findPassenger(String? passengerId) {
    if (passengerId == null || trip.passengers == null) return null;
    for (final passenger in trip.passengers!) {
      if (passenger.carpoolTripId == passengerId ||
          passenger.id?.toString() == passengerId) {
        return passenger;
      }
    }
    return null;
  }

  Future<BitmapDescriptor> _passengerMarkerIcon(
      SimplePassengerModel? passenger) async {
    if (passenger != null) {
      return PassengerMapMarkerHelper.fromPassenger(passenger);
    }
    return PassengerMapMarkerHelper.placeholder();
  }

  Future<void> _createMarkers() async {
    _markers.clear();

    // Start marker
    if (trip.startCoordinates != null && trip.startCoordinates!.length >= 2) {
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position:
              LatLng(trip.startCoordinates![0], trip.startCoordinates![1]),
          infoWindow: InfoWindow(
            title: 'Start',
            snippet: trip.startAddress ?? 'Start location',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    // End marker
    if (trip.endCoordinates != null && trip.endCoordinates!.length >= 2) {
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(trip.endCoordinates![0], trip.endCoordinates![1]),
          infoWindow: InfoWindow(
            title: 'End',
            snippet: trip.endAddress ?? 'End location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    print('=== Creating passenger pickup & dropoff markers with avatars ===');
    final addedPickupIds = <String>{};
    final addedDropoffIds = <String>{};

    // --- Passenger markers from passengerCoordinates ---
    if (trip.passengerCoordinates != null) {
      for (int i = 0; i < trip.passengerCoordinates!.length; i++) {
        final passengerCoord = trip.passengerCoordinates![i];

        if (!passengerCoord.hasValidCoordinates) continue;

        final coords = passengerCoord.coordinates;
        if (coords == null || coords.length < 2) continue;

        final latLng = LatLng(coords[0], coords[1]);
        final passengerId = passengerCoord.passengerId ?? 'idx_$i';
        final passenger = _findPassenger(passengerCoord.passengerId);
        final passengerName = passenger?.name ?? 'Unknown';
        final passengerInfo =
            '$passengerName (${passenger?.seatsCount ?? 1} seats)';

        if (passengerCoord.isPickup) {
          if (addedPickupIds.contains(passengerId)) continue;

          final icon = await _passengerMarkerIcon(passenger);
          _markers.add(
            Marker(
              markerId: MarkerId('passenger_pickup_$passengerId'),
              position: latLng,
              anchor: const Offset(0.5, 0.5),
              infoWindow: InfoWindow(
                title: 'Pickup - $passengerInfo',
                snippet:
                    '${passengerCoord.address ?? passenger?.pickupAddress ?? 'Passenger pickup location'}\nStatus: ${_getPassengerStatus(passengerId)}',
              ),
              icon: icon,
            ),
          );
          addedPickupIds.add(passengerId);
        } else if (passengerCoord.isDropoff) {
          if (addedDropoffIds.contains(passengerId)) continue;
          final icon = await _passengerMarkerIcon(passenger);
          _markers.add(
            Marker(
              markerId: MarkerId('passenger_dropoff_$passengerId'),
              position: latLng,
              infoWindow: InfoWindow(
                title: 'Dropoff - $passengerInfo',
                snippet:
                    '${passengerCoord.address ?? passenger?.dropoffAddress ?? 'Passenger dropoff location'}\nStatus: ${_getPassengerStatus(passengerId)}',
              ),
              icon: icon,
            ),
          );
          addedDropoffIds.add(passengerId);
        }
      }
    }

    // --- Fallback: markers from passengers list ---
    if (trip.passengers != null) {
      for (final passenger in trip.passengers!) {
        final passengerId =
            passenger.carpoolTripId ?? passenger.id?.toString() ?? '';
        if (passengerId.isEmpty) continue;

        // Pickup marker fallback
        if (!addedPickupIds.contains(passengerId)) {
          final coords =
              passenger.closestPickupPoint ?? passenger.pickupCoordinates;
          if (coords != null && coords.length >= 2) {
            final icon = await _passengerMarkerIcon(passenger);
            _markers.add(
              Marker(
                markerId: MarkerId('passenger_pickup_$passengerId'),
                position: LatLng(coords[0], coords[1]),
                anchor: const Offset(0.5, 0.5),
                infoWindow: InfoWindow(
                  title: 'Pickup - ${passenger.name ?? 'Unknown'}',
                  snippet: passenger.displayPickupAddress(trip.startAddress),
                ),
                icon: icon,
              ),
            );
            addedPickupIds.add(passengerId);
          }
        }
        print('pessanger dropoffs: ${passenger?.dropoffCoordinates}');
        // Dropoff marker fallback
        // if (!addedDropoffIds.contains(passengerId)) {
        final dropCoords = passenger.dropoffCoordinates;
        if (dropCoords != null && dropCoords.length >= 2) {
          // _markers.add(
          //   Marker(
          //     markerId: MarkerId('passenger_dropoff_$passengerId'),
          //     position: LatLng(dropCoords[0], dropCoords[1]),
          //     infoWindow: InfoWindow(
          //       title: 'Dropoff - ${passenger.name ?? 'Unknown'}',
          //       snippet: passenger.displayDropoffAddress(trip.endAddress),
          //     ),
          //     icon: BitmapDescriptor.defaultMarkerWithHue(
          //         BitmapDescriptor.hueOrange),
          //   ),
          // );
          addedDropoffIds.add(passengerId);
        }
        // }
      }
    }

    print(
        '=== Total markers created: ${_markers.length} (pickups: ${addedPickupIds.length}, dropoffs: ${addedDropoffIds.length}) ===');
    update();
  }

  void _createPolylines() {
    _polylines.clear();
    update();
  }

  Future<void> _loadMainRoute() async {
    try {
      print('=== Loading main route ===');
      print('=== Encoded polyline: ${trip.encodedPolyline} ===');

      // Use encoded polyline from the server (static route for carpool trips)
      if (trip.encodedPolyline != null && trip.encodedPolyline!.isNotEmpty) {
        print('=== Using encoded polyline from server ===');
        print(
            '=== Encoded polyline length: ${trip.encodedPolyline!.length} characters ===');
        _mainRoutePoints = decodePolyline(trip.encodedPolyline!);
        _updateMainRoutePolyline();
        print('=== Decoded polyline points: ${_mainRoutePoints.length} ===');
        print('=== Polyline source: Server (static carpool route) ===');
      } else {
        print('=== No encoded polyline available from server ===');
        print('=== No polyline will be drawn ===');
      }
    } catch (e) {
      print('=== Error loading main route: $e ===');
    }
  }

  // Future<void> _loadDriverToStartRoute() async {
  //   try {
  //     if (_currentPosition != null &&
  //         trip.startCoordinates != null &&
  //         trip.startCoordinates!.length >= 2) {
  //       // For now, create a simple route from driver to start
  //       _driverToStartRoute = [
  //         LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
  //         LatLng(
  //             trip.startCoordinates![1],
  //             trip.startCoordinates![
  //                 0]), // [longitude, latitude] -> (latitude, longitude)
  //       ];

  //       // Update polylines
  //       _updateDriverToStartPolyline();
  //     }
  //   } catch (e) {
  //     print('=== Error loading driver to start route: $e ===');
  //   }
  // }

  void _updateMainRoutePolyline() {
    print('=== Updating main route polyline ===');
    print('=== Main route points count: ${_mainRoutePoints.length} ===');

    _polylines.removeWhere(
        (polyline) => polyline.polylineId == const PolylineId('main_route'));

    if (_mainRoutePoints.isNotEmpty) {
      print('=== Creating polyline with ${_mainRoutePoints.length} points ===');
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('main_route'),
          points: _mainRoutePoints,
          color: Colors.blue,
          width: 5,
          geodesic: true,
        ),
      );
      print('=== Polyline added successfully ===');

      _updateStartEndMarkersFromRoute();
    } else {
      print('=== No route points to create polyline ===');
    }

    print('=== Total polylines: ${_polylines.length} ===');
    update();
  }

  void _updateStartEndMarkersFromRoute() {
    if (_mainRoutePoints.isEmpty) {
      return;
    }

    final LatLng startPoint = _mainRoutePoints.first;
    final LatLng endPoint = _mainRoutePoints.last;

    _markers.removeWhere(
        (m) => m.markerId.value == 'start' || m.markerId.value == 'end');

    // Re-create start marker at first polyline point
    _markers.add(
      Marker(
        markerId: const MarkerId('start'),
        position: startPoint,
        infoWindow: InfoWindow(
          title: 'Start',
          snippet: trip.startAddress ?? 'Start location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Re-create end marker at last polyline point
    _markers.add(
      Marker(
        markerId: const MarkerId('end'),
        position: endPoint,
        infoWindow: InfoWindow(
          title: 'End',
          snippet: trip.endAddress ?? 'End location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    print(
        '=== Updated start/end markers from polyline route: start=$startPoint end=$endPoint ===');
    update();
  }

  String _getPassengerStatus(String passengerId) {
    if (trip.passengers != null) {
      for (final passenger in trip.passengers!) {
        if (passenger.carpoolTripId == passengerId) {
          return passenger.status ?? 'Unknown';
        }
      }
    }
    return 'Unknown';
  }

  void _fitMarkersOnMap() {
    if (_mapController != null && _markers.isNotEmpty) {
      try {
        LatLngBounds bounds = _getBoundsForMarkers();
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50.0),
        );
      } catch (e) {
        print('=== Error fitting markers: $e ===');
      }
    }
  }

  LatLngBounds _getBoundsForMarkers() {
    double? minLat, maxLat, minLng, maxLng;

    for (Marker marker in _markers) {
      if (minLat == null || marker.position.latitude < minLat) {
        minLat = marker.position.latitude;
      }
      if (maxLat == null || marker.position.latitude > maxLat) {
        maxLat = marker.position.latitude;
      }
      if (minLng == null || marker.position.longitude < minLng) {
        minLng = marker.position.longitude;
      }
      if (maxLng == null || marker.position.longitude > maxLng) {
        maxLng = marker.position.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat ?? 0, minLng ?? 0),
      northeast: LatLng(maxLat ?? 0, maxLng ?? 0),
    );
  }

  void fitMarkersOnMap() {
    _fitMarkersOnMap();
  }

  void onCameraMove() {
    if (_isFollowingDriver) {
      _isFollowingDriver = false;
      update();
    }
  }

  void toggleFollowDriver() {
    _isFollowingDriver = !_isFollowingDriver;
    update();

    if (_isFollowingDriver && _currentPosition != null) {
      _animateToDriver();
    }
  }

  void _animateToDriver() {
    if (_mapController != null && _currentPosition != null) {
      try {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          ),
        );
      } catch (e) {
        print('=== Error animating to driver: $e ===');
      }
    }
  }

  void returnToDriver() {
    _animateToDriver();
    Get.showSnackbar(GetSnackBar(
      title: 'info'.tr,
      message: 'returned_to_driver'.tr,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.blue,
    ));
  }

  Future<void> openInGoogleMaps() async {
    try {
      if (trip.startCoordinates != null &&
          trip.endCoordinates != null &&
          trip.startCoordinates!.length >= 2 &&
          trip.endCoordinates!.length >= 2) {
        String startCoords =
            '${trip.startCoordinates![1]},${trip.startCoordinates![0]}';
        String endCoords =
            '${trip.endCoordinates![1]},${trip.endCoordinates![0]}';

        Uri googleMapsUri = Uri.parse(
            'https://www.google.com/maps/dir/$startCoords/$endCoords');

        print('=== openInGoogleMaps startUri: $googleMapsUri ===');

        bool launched = false;

        if (await canLaunchUrl(googleMapsUri)) {
          launched = await launchUrl(
            googleMapsUri,
            mode: LaunchMode.externalApplication,
          );
          print('=== openInGoogleMaps launched googleMapsUri: $launched ===');
        }

        if (!launched) {
          Uri fallbackUri = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$startCoords');
          print('=== openInGoogleMaps fallbackUri: $fallbackUri ===');

          if (await canLaunchUrl(fallbackUri)) {
            launched = await launchUrl(
              fallbackUri,
              mode: LaunchMode.externalApplication,
            );
            print('=== openInGoogleMaps launched fallbackUri: $launched ===');
          }
        }

        if (!launched) {
          String errorMessage =
              'Could not launch Google Maps URL. Please install Google Maps or open browser manually.';
          print('=== openInGoogleMaps failed: $errorMessage ===');
          throw Exception(errorMessage);
        }
      } else {
        Get.showSnackbar(GetSnackBar(
          title: 'error'.tr,
          message: 'no_coordinates_available'.tr,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print('=== Error opening Google Maps: $e ===');
      Get.showSnackbar(GetSnackBar(
        title: 'error'.tr,
        message: '${'failed_to_open_google_maps'.tr}: ${e.toString()}',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ));
    }
  }
}
