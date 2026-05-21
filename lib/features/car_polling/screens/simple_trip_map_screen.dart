import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_sharing_user_app/features/car_polling/controllers/simple_trip_otp_controller.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common_widgets/app_bar_widget.dart';
import '../../../util/dimensions.dart';
import '../../../util/images.dart';
import '../../../util/styles.dart';

import 'carpool_main_map_screen.dart';
import '../domain/models/simple_trip_model.dart';
import '../domain/models/simple_passenger_model.dart';
import '../controllers/simple_trip_map_controller.dart';
import '../widgets/passenger_route_info_widget.dart';
import '../widgets/simple_trip_otp_widget.dart';
import '../widgets/improved_trip_otp_widget.dart';

class SimpleTripMapScreen extends StatefulWidget {
  final SimpleTripModel trip;

  const SimpleTripMapScreen({
    super.key,
    required this.trip,
  });

  @override
  State<SimpleTripMapScreen> createState() => _SimpleTripMapScreenState();
}

class _SimpleTripMapScreenState extends State<SimpleTripMapScreen>
    with TickerProviderStateMixin {
  late SimpleTripMapController controller;
  Offset _passengersPanelPosition = const Offset(16, 100); // Initial position
  GoogleMapController? _mapController;

  // Animation controllers for UI elements
  late AnimationController _uiAnimationController;
  late Animation<double> _uiFadeAnimation;
  late Animation<Offset> _uiSlideAnimation;

  @override
  void initState() {
    super.initState();
    print('=== SimpleTripMapScreen initState ===');
    print('=== Trip ID: ${widget.trip.id} ===');
    print(
        '=== Trip passenger coordinates: ${widget.trip.passengerCoordinates?.length ?? 0} ===');
    print('=== Trip passengers: ${widget.trip.passengers?.length ?? 0} ===');

    controller = Get.put(SimpleTripMapController(trip: widget.trip));

    // Ensure SimpleTripOtpController is registered before GetBuilder needs it
    if (!Get.isRegistered<SimpleTripOtpController>()) {
      Get.find<SimpleTripOtpController>();
    }

    // Initialize UI animations
    _uiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _uiFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _uiAnimationController,
      curve: Curves.easeOut,
    ));

    _uiSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _uiAnimationController,
      curve: Curves.elasticOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeMap();
      _uiAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _uiAnimationController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'trip_map'.tr,
        showBackButton: true,
      ),
      body: GetBuilder<SimpleTripMapController>(
        builder: (ctrl) {
          if (ctrl.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final trip = widget.trip;
          final passengers = trip.passengers;
          final passengerCoordinates = trip.passengerCoordinates;
          final encodedPolyline = trip.encodedPolyline;
          final hasPolyline =
              encodedPolyline != null && encodedPolyline.isNotEmpty;

          return Stack(
            children: [
              // Map
              GoogleMap(
                onMapCreated: (GoogleMapController mapController) {
                  _mapController = mapController;
                  ctrl.setMapController(mapController);
                },
                initialCameraPosition: CameraPosition(
                  target: ctrl.initialPosition,
                  zoom: 15.0,
                ),
                markers: ctrl.markers,
                polylines: ctrl.polylines,
                onCameraMove: (position) {
                  ctrl.onCameraMove();
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),

              // Control Buttons
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: "fitMarkers",
                      onPressed: () => ctrl.fitMarkersOnMap(),
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.fit_screen, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: "openGoogleMaps",
                      onPressed: () => ctrl.openInGoogleMaps(),
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.open_in_new, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: "returnToDriver",
                      onPressed: () => ctrl.returnToDriver(),
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.location_on, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    // Show passengers panel button
                    FloatingActionButton(
                      heroTag: "showPassengers",
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _passengersPanelPosition = const Offset(16, 100);
                        });
                      },
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.people, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    // Open in main map screen button
                    FloatingActionButton(
                      heroTag: "openInMainMap",
                      onPressed: () => _openInMainMapScreen(),
                      backgroundColor: Colors.orange,
                      child: const Icon(Icons.map, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Follow Driver Button
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  heroTag: "followDriver",
                  onPressed: () => ctrl.toggleFollowDriver(),
                  backgroundColor: ctrl.isFollowingDriver
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                  label: Text(
                    ctrl.isFollowingDriver ? 'following'.tr : 'follow'.tr,
                    style: textMedium.copyWith(color: Colors.white),
                  ),
                  icon: Icon(
                    ctrl.isFollowingDriver
                        ? Icons.gps_fixed
                        : Icons.gps_not_fixed,
                    color: Colors.white,
                  ),
                ),
              ),

              // Unified Trip Information Panel - Top Center
              Positioned(
                top: MediaQuery.of(context).size.height - 420,
                left: 16,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // يمكن إضافة تفاعل إضافي هنا
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).cardColor.withOpacity(0.88),
                            Theme.of(context).cardColor.withOpacity(0.83),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header Row
                          Row(
                            children: [
                              // Trip ID
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.confirmation_number,
                                      color: Theme.of(context).primaryColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '#${trip.id ?? 'N/A'}',
                                      style: textMedium.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: Dimensions.fontSizeSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Trip Status
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      trip.isTripStarted == 1
                                          ? Colors.green.withOpacity(0.9)
                                          : Colors.orange.withOpacity(0.9),
                                      trip.isTripStarted == 1
                                          ? Colors.green.shade600
                                              .withOpacity(0.9)
                                          : Colors.orange.shade600
                                              .withOpacity(0.9),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      trip.isTripStarted == 1
                                          ? 'active'.tr
                                          : 'pending'.tr,
                                      style: textBold.copyWith(
                                        color: Colors.white,
                                        fontSize: Dimensions.fontSizeSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Info Row
                          Row(
                            children: [
                              // Distance
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.straighten,
                                        color: Theme.of(context).primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'distance'.tr,
                                            style: textRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeSmall,
                                              color:
                                                  Theme.of(context).hintColor,
                                            ),
                                          ),
                                          Text(
                                            ctrl.mainRoutePoints.isNotEmpty
                                                ? ctrl.remainingDistance
                                                : 'N/A',
                                            style: textBold.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeDefault,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // ETA
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.access_time,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'eta'.tr,
                                            style: textRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeSmall,
                                              color:
                                                  Theme.of(context).hintColor,
                                            ),
                                          ),
                                          Text(
                                            ctrl.mainRoutePoints.isNotEmpty
                                                ? ctrl
                                                    .estimatedTimeToDestination
                                                : 'N/A',
                                            style: textBold.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeDefault,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Price
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green.withOpacity(0.9),
                                        Colors.green.shade600.withOpacity(0.9),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'price'.tr,
                                        style: textRegular.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: Dimensions.fontSizeSmall,
                                        ),
                                      ),
                                      Text(
                                        trip.formattedPrice,
                                        style: textBold.copyWith(
                                          color: Colors.white,
                                          fontSize: Dimensions.fontSizeDefault,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Route Statistics
                          if (passengerCoordinates != null &&
                              passengerCoordinates.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.route,
                                        color: Theme.of(context).primaryColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${ctrl.mainRoutePoints.length} ${'route_points'.tr}',
                                        style: textMedium.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: Dimensions.fontSizeSmall,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        hasPolyline
                                            ? Icons.check_circle
                                            : Icons.error_outline,
                                        color: hasPolyline
                                            ? Colors.green
                                            : Colors.red,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasPolyline ? 'server'.tr : 'none'.tr,
                                        style: textMedium.copyWith(
                                          color: hasPolyline
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: Dimensions.fontSizeSmall,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.people,
                                        color: Theme.of(context).primaryColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${passengers?.length ?? 0} ${'passengers'.tr}',
                                        style: textMedium.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: Dimensions.fontSizeSmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Theme.of(context).hintColor,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        ctrl.polylineSource,
                                        style: textRegular.copyWith(
                                          color: Theme.of(context).hintColor,
                                          fontSize:
                                              Dimensions.fontSizeExtraSmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Passengers Panel
              if (passengers != null && passengers.isNotEmpty)
                Positioned(
                  top: _passengersPanelPosition.dy,
                  left: _passengersPanelPosition.dx,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _passengersPanelPosition = Offset(
                          (_passengersPanelPosition.dx + details.delta.dx)
                              .clamp(
                            0,
                            MediaQuery.of(context).size.width - 300,
                          ),
                          (_passengersPanelPosition.dy + details.delta.dy)
                              .clamp(
                            50,
                            MediaQuery.of(context).size.height - 400,
                          ),
                        );
                      });
                    },
                    onPanStart: (details) {
                      // Add haptic feedback when starting to drag
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      width: 300,
                      constraints: const BoxConstraints(maxHeight: 400),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(
                                Dimensions.paddingSizeDefault),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(
                                    width: Dimensions.paddingSizeSmall),
                                Expanded(
                                  child: Text(
                                    'passengers'.tr,
                                    style: textBold.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                    width: Dimensions.paddingSizeSmall),
                                // Drag indicator
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _passengersPanelPosition =
                                          const Offset(16, 100);
                                    });
                                  },
                                  child: Icon(
                                    Icons.drag_handle,
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.6),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(
                                    width: Dimensions.paddingSizeSmall),
                                // Close button
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      // Hide the panel by moving it off screen
                                      _passengersPanelPosition = Offset(
                                        MediaQuery.of(context).size.width + 100,
                                        _passengersPanelPosition.dy,
                                      );
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                    width: Dimensions.paddingSizeSmall),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${passengers.length}',
                                    style: textMedium.copyWith(
                                      color: Colors.white,
                                      fontSize: Dimensions.fontSizeExtraSmall,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Passengers List
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeDefault),
                              itemCount: passengers.length,
                              itemBuilder: (context, index) {
                                final passenger = passengers[index];
                                return _buildPassengerCard(passenger);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
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
              /// Avatar FIXED
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
                    InkWell(
                      onTap: () => _showRouteOptionsBottomSheet(
                          context, passenger, widget.trip),
                      borderRadius: BorderRadius.circular(10),
                      child: PassengerRouteInfoWidget(
                        passenger: passenger,
                        tripStartAddress: widget.trip.startAddress,
                        tripEndAddress: widget.trip.endAddress,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ),

              /// OTP Button
              GetBuilder<SimpleTripOtpController>(
                  builder: (controller) {
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
                  }),
            ],
          ),

          const SizedBox(height: Dimensions.paddingSizeSmall),

          /// Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
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
    // تأكد من وجود carpool_trip_id
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
              passengerName: passenger.name ?? 'Unknown Passenger',
              onShowSnackBar: _showSnackBar,
              controller: controller,
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

  void _openInMainMapScreen() {
    // Navigate to carpool main map screen with trip data
    Get.to(() => CarpoolMainMapScreen(carpoolTrip: widget.trip));
  }
}
