import 'dart:async';
import 'dart:io';

import 'package:ride_sharing_user_app/features/car_polling/controllers/simple_trip_otp_controller.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_sharing_user_app/common_widgets/expandable_bottom_sheet.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/map/widgets/custom_icon_card_widget.dart';
import 'package:ride_sharing_user_app/features/map/widgets/driver_header_info_widget.dart';
import 'package:ride_sharing_user_app/features/profile/screens/profile_screen.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/theme/theme_controller.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/car_polling/domain/models/simple_trip_model.dart';
import 'package:ride_sharing_user_app/features/car_polling/controllers/carpool_main_map_controller.dart';
import '../domain/models/simple_passenger_model.dart';
import '../widgets/improved_trip_otp_widget.dart';
import '../widgets/passenger_route_info_widget.dart';

class CarpoolMainMapScreen extends StatefulWidget {
  final String fromScreen;
  final SimpleTripModel? carpoolTrip;

  const CarpoolMainMapScreen({
    super.key,
    this.fromScreen = 'carpool',
    this.carpoolTrip,
  });

  @override
  State<CarpoolMainMapScreen> createState() => _CarpoolMainMapScreenState();
}

class _CarpoolMainMapScreenState extends State<CarpoolMainMapScreen>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  GlobalKey<ExpandableBottomSheetState> key =
      GlobalKey<ExpandableBottomSheetState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _findingCurrentRoute();
    // إزالة stopLocationRecord من هنا لتجنب التضارب مع timer
    // Get.find<ProfileController>().stopLocationRecord();
  }

  _findingCurrentRoute() {
    final trip = widget.carpoolTrip;
    // Initialize carpool main map controller
    if (trip != null) {
      Get.put(CarpoolMainMapController(carpoolTrip: trip));
    }

    Get.find<RideController>().updateRoute(false, notify: false);

    if (Get.isRegistered<CarpoolMainMapController>()) {
      Get.find<CarpoolMainMapController>().setSheetHeight(300, false);
    }

    // Don't call getCurrentLocation here - it will be called in onMapCreated
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Handle app resume
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    final sub = _locationSubscription;
    if (sub != null) {
      sub.cancel();
    }
    // إزالة startLocationRecord من هنا لتجنب التضارب مع timer
    // Get.find<ProfileController>().startLocationRecord();
    super.dispose();
  }

  StreamSubscription? _locationSubscription;
  Marker? marker;
  GoogleMapController? _controller;

  Future<Uint8List> getMarker() async {
    ByteData byteData =
        await DefaultAssetBundle.of(context).load(Images.carTop);
    return byteData.buffer.asUint8List();
  }

  void updateMarkerAndCircle(Position? newLocalData, Uint8List imageData) {
    if (newLocalData == null) return;
    LatLng latLng = LatLng(newLocalData.latitude, newLocalData.longitude);
    setState(() {
      marker = Marker(
          markerId: const MarkerId("home"),
          position: latLng,
          rotation: newLocalData.heading,
          draggable: false,
          zIndex: 2,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.fromBytes(imageData));
    });
  }

  void getCurrentLocation() async {
    try {
      Uint8List imageData = await getMarker();
      var location = await Geolocator.getCurrentPosition();
      updateMarkerAndCircle(location, imageData);

      // Update car position in carpool controller immediately
      if (Get.isRegistered<CarpoolMainMapController>()) {
        Get.find<CarpoolMainMapController>().updateMarkerAndCircle(
          LatLng(location.latitude, location.longitude),
        );
      }

      final sub = _locationSubscription;
      if (sub != null) {
        sub.cancel();
      }

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Increased to reduce API calls
        ),
      ).listen((newLocalData) {
        final controller = _controller;
        if (controller != null && mounted) {
          try {
            // Update car position in carpool controller like in original map screen
            if (Get.isRegistered<CarpoolMainMapController>()) {
              Get.find<CarpoolMainMapController>().updateMarkerAndCircle(
                LatLng(newLocalData.latitude, newLocalData.longitude),
              );
            }

            // Only call getCurrentLocation if following driver
            if (Get.isRegistered<CarpoolMainMapController>() &&
                Get.find<CarpoolMainMapController>().isFollowingDriver) {
              Get.find<LocationController>()
                  .getCurrentLocation(callZone: false);
            }

            // Only move camera if following driver
            if (Get.isRegistered<CarpoolMainMapController>() &&
                Get.find<CarpoolMainMapController>().isFollowingDriver) {
              controller.moveCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(
                      bearing: newLocalData.heading,
                      target:
                          LatLng(newLocalData.latitude, newLocalData.longitude),
                      tilt: 0,
                      zoom: 16)));
            }

            updateMarkerAndCircle(newLocalData, imageData);
          } catch (e) {
            debugPrint('Camera move error: $e');
          }
        }
      }, onError: (error) {
        debugPrint('Location stream error: $error');
      });
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint("Permission Denied");
      } else {
        debugPrint("Platform exception: $e");
      }
    } catch (e) {
      debugPrint("General error in getCurrentLocation: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.carpoolTrip;
    final startCoords = trip?.startCoordinates;

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (res, val) {
        if (res) {
          Get.find<RideController>().getOngoingParcelList();
          Get.find<RideController>().getLastTrip();
          Get.find<RideController>().updateRoute(true, notify: true);
        } else {
          Get.offAll(() => const DashboardScreen());
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: GetBuilder<CarpoolMainMapController>(
            builder: (carpoolMainMapController) {
          return GetBuilder<RideController>(builder: (rideController) {
            return ExpandableBottomSheet(
              key: key,
              persistentContentHeight: carpoolMainMapController.sheetHeight,
              background: GetBuilder<RideController>(builder: (rideController) {
                return Stack(children: [
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: carpoolMainMapController.sheetHeight - 80,
                    ),
                    child: GoogleMap(
                      style: Get.isDarkMode
                          ? Get.find<ThemeController>().darkMap
                          : Get.find<ThemeController>().lightMap,
                      initialCameraPosition: CameraPosition(
                        target: (startCoords != null && startCoords.length >= 2)
                            ? LatLng(
                                startCoords[1],
                                startCoords[0],
                              )
                            : (Get.find<LocationController>().initialPosition ??
                                const LatLng(0, 0)),
                        zoom: 15.0,
                        bearing: 0,
                        tilt: 0,
                      ),
                      onMapCreated: (GoogleMapController controller) async {
                        try {
                          carpoolMainMapController.setMapController(controller);
                          _mapController = controller;
                          _controller = controller;

                          await Future.delayed(
                              const Duration(milliseconds: 100));

                          // Initialize map like in original map screen
                          await carpoolMainMapController.initializeMap();

                          // Get current location once
                          getCurrentLocation();

                          // Start location tracking like in original map screen
                          carpoolMainMapController.startLocationTracking();
                        } catch (e) {
                          debugPrint('Error in onMapCreated: $e');
                        }
                      },
                      onCameraMove: (CameraPosition cameraPosition) {
                        // Handle camera move like in original map screen
                        if (Get.isRegistered<CarpoolMainMapController>()) {
                          Get.find<CarpoolMainMapController>().onCameraMove();
                        }
                      },
                      onCameraIdle: () {},
                      minMaxZoomPreference:
                          const MinMaxZoomPreference(0, AppConstants.mapZoom),
                      markers: Set<Marker>.of(carpoolMainMapController.markers),
                      polylines: carpoolMainMapController.polylines,
                      zoomControlsEnabled: false,
                      compassEnabled: true,
                      trafficEnabled: carpoolMainMapController.isTrafficEnable,
                      indoorViewEnabled: true,
                      mapToolbarEnabled: false,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                  InkWell(
                    onTap: () => Get.to(const ProfileScreen()),
                    child: const DriverHeaderInfoWidget(),
                  ),
                  Positioned(
                      bottom: Get.width * 0.9,
                      right: 0,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: GetBuilder<LocationController>(
                            builder: (locationController) {
                          return CustomIconCardWidget(
                            title: '',
                            index: 5,
                            icon: carpoolMainMapController.isTrafficEnable
                                ? Images.trafficOnlineIcon
                                : Images.trafficOfflineIcon,
                            iconColor: carpoolMainMapController.isTrafficEnable
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).primaryColor,
                            onTap: () =>
                                carpoolMainMapController.toggleTrafficView(),
                          );
                        }),
                      )),
                  Positioned(
                      bottom: Get.width * 0.78,
                      right: 0,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: GetBuilder<LocationController>(
                            builder: (locationController) {
                          return CustomIconCardWidget(
                            iconColor: Theme.of(context).primaryColor,
                            title: '',
                            index: 5,
                            icon: Images.currentLocation,
                            onTap: () async {
                              await locationController.getCurrentLocation(
                                  mapController: _mapController,
                                  isAnimate: false);
                            },
                          );
                        }),
                      )),
                  // Home Button
                ]);
              }),
              persistentHeader: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag indicator
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).hintColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Trip header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Carpool Trip #${trip?.id ?? 'N/A'}',
                                  style: textBold.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                  ),
                                ),
                                Text(
                                  trip?.isTripStarted == 1
                                      ? 'Active Trip'
                                      : 'Pending Trip',
                                  style: textRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: trip?.isTripStarted == 1
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              trip?.formattedPrice ?? 'N/A',
                              style: textBold.copyWith(
                                color: Colors.white,
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Trip details in header
                    if (trip != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildHeaderDetailRow(
                                icon: Icons.location_on,
                                title: 'From',
                                subtitle: trip.startAddress ?? 'N/A',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildHeaderDetailRow(
                                icon: Icons.location_on_outlined,
                                title: 'To',
                                subtitle: trip.endAddress ?? 'N/A',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              expandableContent: Builder(builder: (context) {
                final passengers = trip?.passengers;
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (trip != null) ...[
                        // Trip stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildSimpleStatCard(
                                icon: Icons.people,
                                title: 'Passengers',
                                value: '${trip.passengersCount ?? 0}',
                              ),
                            ),
                            Expanded(
                              child: _buildSimpleStatCard(
                                icon: Icons.event_seat,
                                title: 'Available',
                                value: '${trip.availableSeats ?? 0}',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSimpleStatCard(
                                icon: Icons.access_time,
                                title: 'Time',
                                value: trip.startHour ?? 'N/A',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  carpoolMainMapController.fitMarkersOnMap();
                                },
                                icon: const Icon(Icons.fit_screen, size: 18),
                                label: const Text('Fit Map'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  carpoolMainMapController.openInGoogleMaps();
                                },
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: const Text('Open Maps'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  carpoolMainMapController.returnToDriver();
                                },
                                icon: const Icon(Icons.location_on, size: 18),
                                label: const Text('My Location'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Follow Driver Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              carpoolMainMapController.toggleFollowDriver();
                            },
                            icon: Icon(
                              carpoolMainMapController.isFollowingDriver
                                  ? Icons.gps_fixed
                                  : Icons.gps_not_fixed,
                              size: 18,
                            ),
                            label: Text(
                              carpoolMainMapController.isFollowingDriver
                                  ? 'Following Driver'
                                  : 'Follow Driver',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  carpoolMainMapController.isFollowingDriver
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Divider
                      Divider(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.3),
                          height: 35),

                      // Section Title
                      Row(
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'passengers'.tr,
                            style: textBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color: Get.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${passengers?.length ?? 0}',
                              style: textBold.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Passengers List
                      if (passengers != null && passengers.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: passengers.length,
                          itemBuilder: (context, index) {
                            final passenger = passengers[index];
                            return _buildPassengerCard(passenger);
                          },
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'no_passengers_found'
                                    .tr
                                    .contains('no_passengers_found')
                                ? 'No passengers found'
                                : 'no_passengers_found'.tr,
                            style: textRegular.copyWith(
                              color: Theme.of(context).hintColor,
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }),
            );
          });
        }),
      ),
    );
  }

  // Helper methods for UI components
  Widget _buildHeaderDetailRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: textMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: textMedium.copyWith(
            fontSize: Dimensions.fontSizeSmall,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSimpleStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textBold.copyWith(
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
          Text(
            title,
            style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _passengerAvatar(SimplePassengerModel passenger) {
    final imageUrl = passenger.fullProfileImage;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (_, __, ___) => Image.asset(
          Images.personPlaceholder,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      Images.personPlaceholder,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
    );
  }

  Widget _buildPassengerCard(SimplePassengerModel passenger) {
    final trip = widget.carpoolTrip;
    return Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                /// Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  child: ClipOval(
                    child: _passengerAvatar(passenger),
                  ),
                ),

                const SizedBox(width: Dimensions.paddingSizeSmall),

                /// Info + locations (always visible beside passenger)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passenger.name ?? 'unknown_passenger'.tr,
                        style: textMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.event_seat,
                            color: Theme.of(context).primaryColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${passenger.seatsCount ?? 1} ${'seats'.tr}',
                            style: textRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.payments_outlined,
                            size: 14,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            passenger.formattedFare,
                            style: textBold.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (trip != null)
                        InkWell(
                          onTap: () => _showRouteOptionsBottomSheet(
                              context, passenger, trip),
                          borderRadius: BorderRadius.circular(10),
                          child: PassengerRouteInfoWidget(
                            passenger: passenger,
                            tripStartAddress: trip.startAddress,
                            tripEndAddress: trip.endAddress,
                            compact: true,
                          ),
                        ),
                    ],
                  ),
                ),

                /// OTP Button
                GetBuilder<SimpleTripOtpController>(
                  builder: (SimpleTripOtpController controller) {
                    // final isChecking = controller.isCheckingOtp;

                    // if (isChecking) {
                    //   return const SizedBox(
                    //     width: 40,
                    //     height: 40,
                    //     child: Center(
                    //       child: CircularProgressIndicator(strokeWidth: 2),
                    //     ),
                    //   );
                    // }

                    return ElevatedButton.icon(
                      onPressed: () =>
                          _showOtpVerificationDialog(passenger, controller),
                      icon: const Icon(Icons.verified_user, size: 16),
                      label: Text(
                        'OTP',
                        style: textMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                /// Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: passenger.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: passenger.statusColor),
                  ),
                  child: Text(
                    passenger.statusDisplayText,
                    style: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: passenger.statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ));
  }

  void _openMap(double lat, double lng) async {
    final googleMapsAndroidUrl = "google.navigation:q=$lat,$lng";
    final googleMapsIOSUrl =
        "comgooglemaps://?daddr=$lat,$lng&directionsmode=driving";
    final googleMapsWebUrl =
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final appleMapsUrl = "http://maps.apple.com/?daddr=$lat,$lng";

    try {
      if (Platform.isIOS) {
        if (await canLaunchUrl(Uri.parse(googleMapsIOSUrl))) {
          await launchUrl(Uri.parse(googleMapsIOSUrl));
        } else if (await canLaunchUrl(Uri.parse(googleMapsWebUrl))) {
          await launchUrl(
            Uri.parse(googleMapsWebUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          await launchUrl(Uri.parse(appleMapsUrl));
        }
      } else {
        if (await canLaunchUrl(Uri.parse(googleMapsAndroidUrl))) {
          await launchUrl(Uri.parse(googleMapsAndroidUrl));
        } else {
          await launchUrl(
            Uri.parse(googleMapsWebUrl),
            mode: LaunchMode.externalApplication,
          );
        }
      }
    } catch (e) {
      try {
        if (Platform.isIOS) {
          await launchUrl(Uri.parse(appleMapsUrl));
        } else {
          await launchUrl(
            Uri.parse(googleMapsWebUrl),
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (_) {
        Get.snackbar(
          'location_error'.tr,
          'cannot_open_maps'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  void _showOtpVerificationDialog(
      SimplePassengerModel passenger, SimpleTripOtpController controller) {
    final carpoolTripId = passenger.carpoolTripId;
    if (carpoolTripId == null || carpoolTripId.isEmpty) {
      _showSnackBar('Invalid passenger data', Colors.red, icon: Icons.error);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: ImprovedTripOtpWidget(
              carpoolTripId: carpoolTripId,
              controller: controller,
              passengerName: passenger.name ?? 'Unknown Passenger',
              onShowSnackBar: _showSnackBar,
              onCloseDialog: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, Color backgroundColor,
      {IconData icon = Icons.info_outline,
      Duration duration = const Duration(seconds: 3)}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showRouteOptionsBottomSheet(BuildContext context,
      SimplePassengerModel passenger, SimpleTripModel trip) {
    final pickupCoords =
        passenger.closestPickupPoint ?? passenger.pickupCoordinates;
    final dropoffCoords = passenger.dropoffCoordinates;

    final hasPickup = pickupCoords != null && pickupCoords.length >= 2;
    final hasDropoff = dropoffCoords != null && dropoffCoords.length >= 2;

    if (!hasPickup && !hasDropoff) {
      Get.snackbar(
        'location_error'.tr,
        'location_coordinates_not_available'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // If only one exists, launch directly.
    if (hasPickup && !hasDropoff) {
      _openMap(pickupCoords[0], pickupCoords[1]);
      return;
    }
    if (!hasPickup && hasDropoff) {
      _openMap(dropoffCoords[0], dropoffCoords[1]);
      return;
    }

    // If both exist, show a premium bottom sheet.
    Get.bottomSheet(
      Container(
        width: Get.width,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Dimensions.paddingSizeLarge),
            topRight: Radius.circular(Dimensions.paddingSizeLarge),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                Text(
                  'navigate_to'.tr,
                  style: textBold.copyWith(fontSize: 16),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                ListTile(
                  leading: const Icon(Icons.trip_origin_rounded,
                      color: Color(0xFF2E7D32)),
                  title: Text(
                    'pickup_location'.tr,
                    style: textMedium.copyWith(fontSize: 14),
                  ),
                  subtitle: Text(
                    passenger.displayPickupAddress(trip.startAddress),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textRegular.copyWith(
                        fontSize: 12, color: Theme.of(context).hintColor),
                  ),
                  onTap: () {
                    Get.back();
                    if (pickupCoords != null && pickupCoords.length >= 2) {
                      _openMap(pickupCoords[0], pickupCoords[1]);
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading:
                      const Icon(Icons.flag_rounded, color: Color(0xFFC62828)),
                  title: Text(
                    'dropoff_location'.tr,
                    style: textMedium.copyWith(fontSize: 14),
                  ),
                  subtitle: Text(
                    passenger.displayDropoffAddress(trip.endAddress),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textRegular.copyWith(
                        fontSize: 12, color: Theme.of(context).hintColor),
                  ),
                  onTap: () {
                    Get.back();
                    if (dropoffCoords != null && dropoffCoords.length >= 2) {
                      _openMap(dropoffCoords[0], dropoffCoords[1]);
                    }
                  },
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
