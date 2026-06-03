import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../../../common_widgets/app_bar_widget.dart';
import '../controllers/simple_trips_controller.dart';
import '../domain/models/simple_passenger_model.dart';
import '../domain/models/simple_trip_model.dart';
import '../widgets/passenger_route_info_widget.dart';
import 'simple_trip_map_screen.dart';

const _inkBlack = Color(0xFF111111);
const _activeBlue = Color(0xFF2F6BFF);
const _lightBlue = Color.fromARGB(255, 213, 228, 248);

Color _headerColor(String? status) {
  switch (status) {
    case 'pending':
    case 'return_pending':
    case 'ongoing':
      return _inkBlack;
    case 'completed':
      return const Color(0xFF1A5C8A);
    case 'cancelled':
      return const Color(0xFFC62828);
    default:
      return _inkBlack;
  }
}

String _formatTimeString(String? timeStr) {
  if (timeStr == null || timeStr.isEmpty) return 'N/A';
  try {
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final formattedMinute = minute.toString().padLeft(2, '0');
      return '${formattedHour.toString().padLeft(2, '0')}:$formattedMinute $ampm';
    }
  } catch (_) {}
  return timeStr;
}

class TripDetailsScreen extends StatelessWidget {
  final SimpleTripModel trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: 'trip_details'.tr,
        showBackButton: true,
        backgroundColor: _inkBlack,
      ),
      body: GetBuilder<SimpleTripsController>(builder: (controller) {
        // Ensure we are using the latest trip data if available in the controller
        final currentTrip =
            controller.trips.firstWhereOrNull((t) => t.id == trip.id) ?? trip;
        final isRoutine = currentTrip.carpoolType?.toLowerCase() == 'routine';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, controller, currentTrip),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              if (isRoutine) ...[
                // Blue badge pill
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _activeBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: _activeBlue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_rounded,
                            size: 16, color: _activeBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Same Passengers for Both Trips',
                          style: textMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: _activeBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                // Morning Trip Leg Card
                RoutineTripLegCard(
                  title: 'Morning Trip',
                  icon: Icons.wb_sunny_rounded,
                  time: _formatTimeString(currentTrip.departureTime),
                  pickupAddress:
                      currentTrip.startAddress ?? 'unknown_location'.tr,
                  dropoffAddress:
                      currentTrip.endAddress ?? 'unknown_location'.tr,
                  buttonLabel: 'Start Morning Trip',
                  isButtonEnabled: currentTrip.canStartOutbound ?? true,
                  isButtonLoading:
                      controller.isTripBeingStarted(currentTrip.id ?? 0) &&
                          currentTrip.effectiveTripLeg == 'outbound',
                  onPressed: () => controller.startTrip(currentTrip.id ?? 0),
                  onPickupMapPressed: () {
                    if (currentTrip.startCoordinates != null &&
                        currentTrip.startCoordinates!.length >= 2) {
                      _openMap(currentTrip.startCoordinates![0],
                          currentTrip.startCoordinates![1]);
                    }
                  },
                  onDropoffMapPressed: () {
                    if (currentTrip.endCoordinates != null &&
                        currentTrip.endCoordinates!.length >= 2) {
                      _openMap(currentTrip.endCoordinates![0],
                          currentTrip.endCoordinates![1]);
                    }
                  },
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                // Evening Return Leg Card
                if (currentTrip.hasReturnLeg == true) ...[
                  RoutineTripLegCard(
                    title: 'Evening Return',
                    icon: Icons.nightlight_round,
                    time: _formatTimeString(currentTrip.returnTime),
                    pickupAddress:
                        currentTrip.endAddress ?? 'unknown_location'.tr,
                    dropoffAddress:
                        currentTrip.startAddress ?? 'unknown_location'.tr,
                    buttonLabel: 'Start Evening Return',
                    isButtonEnabled: currentTrip.canStartReturn ?? true,
                    isButtonLoading:
                        controller.isTripBeingStarted(currentTrip.id ?? 0) &&
                            currentTrip.effectiveTripLeg == 'return',
                    onPressed: () => controller.startTrip(currentTrip.id ?? 0),
                    onPickupMapPressed: () {
                      if (currentTrip.endCoordinates != null &&
                          currentTrip.endCoordinates!.length >= 2) {
                        _openMap(currentTrip.endCoordinates![0],
                            currentTrip.endCoordinates![1]);
                      }
                    },
                    onDropoffMapPressed: () {
                      if (currentTrip.startCoordinates != null &&
                          currentTrip.startCoordinates!.length >= 2) {
                        _openMap(currentTrip.startCoordinates![0],
                            currentTrip.startCoordinates![1]);
                      }
                    },
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                ],
              ] else ...[
                _buildRouteInfo(context, currentTrip),
                const SizedBox(height: Dimensions.paddingSizeDefault),
              ],
              _buildTripInfo(context, controller, currentTrip),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Builder(
                builder: (context) {
                  final passengers = currentTrip.passengers;
                  if (passengers != null && passengers.isNotEmpty) {
                    return _buildPassengersList(context, currentTrip);
                  }
                  return const SizedBox();
                },
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              // if (currentTrip.tripStatus == 'ongoing') ...[
              _buildActionButtons(context, controller, currentTrip),
              // ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context, SimpleTripsController controller,
      SimpleTripModel trip) {
    final headerColor = _headerColor(trip.tripStatus);
    final isRoutine = trip.carpoolType?.toLowerCase() == 'routine';

    if (isRoutine) {
      return Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: headerColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'trip_id'.tr,
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    Text(
                      ' #${trip.id}',
                      style: textBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    controller.getTripStatusDisplayText(trip.tripStatus),
                    style: textMedium.copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${trip.formattedStartDate} • ${_formatTimeString(trip.departureTime)} (Morning)',
                    style: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
            if (trip.hasReturnLeg == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.nightlight_round_outlined,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${trip.formattedStartDate} • ${_formatTimeString(trip.returnTime)} (Evening Return)',
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'trip_id'.tr,
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    Text(
                      ' #${trip.id}',
                      style: textBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${trip.formattedStartDate} • ${trip.formattedStartTime}',
                        style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Text(
              controller.getTripStatusDisplayText(trip.tripStatus),
              style: textMedium.copyWith(
                color: Colors.white,
                fontSize: Dimensions.fontSizeSmall,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(BuildContext context, SimpleTripModel trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'where_do_you_want_to_go'.tr,
          style: textBold.copyWith(fontSize: 16, color: _inkBlack),
        ),
        const SizedBox(height: 10),
        _buildLocationTile(
          label: 'starting_point'.tr,
          address: trip.startAddress ?? 'unknown_location'.tr,
          icon: Icons.trip_origin_rounded,
        ),
        const SizedBox(height: 8),
        _buildLocationTile(
          label: 'destination'.tr,
          address: trip.endAddress ?? 'unknown_location'.tr,
          icon: Icons.flag_rounded,
        ),
      ],
    );
  }

  Widget _buildLocationTile({
    required String label,
    required String address,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _lightBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _lightBlue),
      ),
      child: Row(
        children: [
          Icon(icon, color: _activeBlue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textMedium.copyWith(
                    fontSize: 11,
                    color: _inkBlack.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textMedium.copyWith(
                    fontSize: 14,
                    color: _inkBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.map_outlined,
              color: _activeBlue.withValues(alpha: 0.8), size: 20),
        ],
      ),
    );
  }

  Widget _buildTripInfo(BuildContext context, SimpleTripsController controller,
      SimpleTripModel trip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lightBlue.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.event_seat_rounded,
                '${controller.getAvailableSeats(trip)}',
                'available_seats'.tr,
              ),
              _buildStatItem(
                Icons.people_rounded,
                '${trip.passengersCount ?? 0}',
                'passengers'.tr,
              ),
              _buildStatItem(
                Icons.payments_rounded,
                trip.formattedPrice,
                'price'.tr,
              ),
            ],
          ),
          if (trip.tripType != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.repeat_rounded,
              trip.tripType == 'repeated' ? 'Repeated Trip' : 'One Time Trip',
            ),
          ],
          Builder(
            builder: (context) {
              final vehicleName = trip.vehicleName;
              if (vehicleName != null) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child:
                      _buildInfoRow(Icons.directions_car_rounded, vehicleName),
                );
              }
              return const SizedBox();
            },
          ),
          if (trip.features.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'features'.tr,
                style: textMedium.copyWith(
                  fontSize: 13,
                  color: _inkBlack.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: trip.features
                  .map(
                    (f) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _lightBlue.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _activeBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        f,
                        style: textRegular.copyWith(
                          fontSize: 11,
                          color: _activeBlue,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _lightBlue.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: _activeBlue),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: textBold.copyWith(fontSize: 14, color: _inkBlack),
        ),
        Text(
          label,
          style: textRegular.copyWith(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _lightBlue.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _activeBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: textMedium.copyWith(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringDates(BuildContext context, SimpleTripModel trip) {
    final tripDates = trip.tripDates;
    if (tripDates == null) return const SizedBox();

    final validDates = tripDates
        .where((d) => d.isCancelled != true)
        .map((d) => d.date)
        .whereType<String>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${validDates.length} ${'days'.tr}',
            style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
        if (validDates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: validDates
                  .map((date) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _lightBlue.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _activeBlue.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          date,
                          style: textRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: _activeBlue,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
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

  Widget _buildPassengerRow(BuildContext context,
      SimplePassengerModel passenger, SimpleTripModel trip) {
    final imageUrl = passenger.fullProfileImage;
    print('image url: $imageUrl');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: _lightBlue,
          child: ClipOval(
            child: (imageUrl != null && imageUrl.isNotEmpty)
                ? Image.network(
                    imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/image/app_version_warning_icon.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    'assets/image/app_version_warning_icon.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passenger.name ?? 'unknown_passenger'.tr,
                          style: textMedium.copyWith(
                            fontSize: 14,
                            color: _inkBlack,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.event_seat,
                                size: 14,
                                color: _inkBlack.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Text(
                              '${passenger.seatsCount ?? 1} ${'seats'.tr}',
                              style: textRegular.copyWith(
                                fontSize: 12,
                                color: _inkBlack.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _activeBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _activeBlue.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      passenger.formattedFare,
                      style:
                          textBold.copyWith(fontSize: 13, color: _activeBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Clickable Pickup Address
              InkWell(
                onTap: () {
                  final pickupCoords = passenger.closestPickupPoint ??
                      passenger.pickupCoordinates;
                  if (pickupCoords != null && pickupCoords.length >= 2) {
                    _openMap(pickupCoords[0], pickupCoords[1]);
                  } else {
                    Get.snackbar('Error', 'location_not_available'.tr,
                        backgroundColor: Colors.red, colorText: Colors.white);
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.trip_origin_rounded,
                        color: Color(0xFF2E7D32), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${'pickup_location'.tr}: ${passenger.displayPickupAddress(trip.startAddress)}',
                        style: textRegular.copyWith(
                            fontSize: 12,
                            color: _inkBlack.withValues(alpha: 0.7)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Clickable Dropoff Address
              InkWell(
                onTap: () {
                  final dropoffCoords = passenger.dropoffCoordinates;
                  if (dropoffCoords != null && dropoffCoords.length >= 2) {
                    _openMap(dropoffCoords[0], dropoffCoords[1]);
                  } else {
                    Get.snackbar('Error', 'location_not_available'.tr,
                        backgroundColor: Colors.red, colorText: Colors.white);
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded,
                        color: Color(0xFFC62828), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${'dropoff_location'.tr}: ${passenger.displayDropoffAddress(trip.endAddress)}',
                        style: textRegular.copyWith(
                            fontSize: 12,
                            color: _inkBlack.withValues(alpha: 0.7)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (trip.carpoolType?.toLowerCase() != 'travel') ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () =>
                        _showRouteOptionsBottomSheet(context, passenger, trip),
                    borderRadius: BorderRadius.circular(10),
                    child: PassengerRouteInfoWidget(
                      passenger: passenger,
                      tripId: trip.id.toString(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPassengersList(BuildContext context, SimpleTripModel trip) {
    final passengers = trip.passengers;
    return Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _lightBlue.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title
            Text(
              'passengers'.tr,
              style: textBold.copyWith(fontSize: 16, color: _inkBlack),
            ),
            const SizedBox(height: 12),
            if (passengers != null)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: passengers.length,
                separatorBuilder: (_, __) => Divider(
                  height: 18,
                  thickness: 0.5,
                  color: _lightBlue,
                ),
                itemBuilder: (context, index) {
                  final passenger = passengers[index];
                  return _buildPassengerRow(context, passenger, trip);
                },
              ),
          ],
        ));
  }

  Widget _buildActionButtons(BuildContext context,
      SimpleTripsController controller, SimpleTripModel trip) {
    if (trip.tripStatus == 'pending') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: controller.isTripBeingStarted(trip.id ?? 0)
                  ? null
                  : () => controller.startTrip(trip.id ?? 0),
              icon: controller.isTripBeingStarted(trip.id ?? 0)
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: Text(
                'start_trip'.tr,
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _inkBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: controller.isTripBeingCancelled(trip.id ?? 0)
                  ? null
                  : () => _showCancelOptions(context, controller, trip),
              icon: controller.isTripBeingCancelled(trip.id ?? 0)
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : const Icon(Icons.cancel_outlined, color: Colors.red),
              label: Text(
                'cancel_trip'.tr,
                style: const TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (trip.tripStatus == 'ongoing') {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (trip.startCoordinates != null &&
                      trip.endCoordinates != null) {
                    Get.to(() => SimpleTripMapScreen(trip: trip));
                  } else {
                    Get.snackbar(
                      'error'.tr,
                      'no_route_coordinates'.tr,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
                icon: const Icon(Icons.map, color: _activeBlue),
                label: Text('show_map'.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _activeBlue,
                  side: const BorderSide(color: _activeBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: controller.isTripBeingEnded(trip.id ?? 0)
                    ? null
                    : () => _showEndTripConfirmationDialog(
                        context, controller, trip),
                icon: controller.isTripBeingEnded(trip.id ?? 0)
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Icon(Icons.stop, color: Colors.red),
                label: Text('end_trip'.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox();
  }

  void _showCancelOptions(BuildContext context,
      SimpleTripsController controller, SimpleTripModel trip) {
    final tripDates = trip.tripDates;
    if (trip.tripType == 'repeated' &&
        tripDates != null &&
        tripDates.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'cancel_trip'.tr,
                  style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.red),
                  title: Text('cancel_specific_dates'.tr),
                  onTap: () {
                    Navigator.pop(context);
                    _showDateSelectionDialog(context, controller, trip);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('cancel_entire_trip'.tr),
                  onTap: () {
                    Navigator.pop(context);
                    _showCancelConfirmationDialog(
                        context, controller, trip.id ?? 0,
                        isEntireTrip: true);
                  },
                ),
              ],
            ),
          );
        },
      );
    } else {
      _showCancelConfirmationDialog(context, controller, trip.id ?? 0);
    }
  }

  void _showDateSelectionDialog(BuildContext context,
      SimpleTripsController controller, SimpleTripModel trip) {
    final List<String> availableDates = trip.tripDates
            ?.where((dateModel) => dateModel.isCancelled != true)
            .map((dateModel) => dateModel.date)
            .whereType<String>()
            .toList() ??
        [];
    final List<String> selectedDates = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('select_dates_to_cancel'.tr),
              content: SizedBox(
                width: double.maxFinite,
                child: availableDates.isEmpty
                    ? Center(child: Text('no_dates_to_cancel'.tr))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableDates.length,
                        itemBuilder: (context, index) {
                          final date = availableDates[index];
                          final isSelected = selectedDates.contains(date);
                          return CheckboxListTile(
                            title: Text(date),
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedDates.add(date);
                                } else {
                                  selectedDates.remove(date);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr),
                ),
                TextButton(
                  onPressed: selectedDates.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          controller.cancelTripDates(trip.id ?? 0,
                              selectedDates, 'User requested cancellation');
                        },
                  child: Text(
                    'cancel_selected'.tr,
                    style: TextStyle(
                      color: selectedDates.isEmpty ? Colors.grey : Colors.red,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCancelConfirmationDialog(
      BuildContext context, SimpleTripsController controller, int tripId,
      {bool isEntireTrip = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('cancel_trip'.tr),
        content: Text('cancel_trip_confirmation'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('no'.tr),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isEntireTrip) {
                controller.cancelEntireTrip(
                    tripId, 'User requested entire trip cancellation');
              } else {
                controller.cancelTrip(tripId);
              }
            },
            child: Text('yes'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEndTripConfirmationDialog(BuildContext context,
      SimpleTripsController controller, SimpleTripModel trip) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: _activeBlue),
              const SizedBox(width: 8),
              Text('end_trip'.tr),
            ],
          ),
          content: Text('end_trip_confirmation'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                controller.endTrip(trip.id ?? 0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _inkBlack,
                foregroundColor: Colors.white,
              ),
              child: Text('end_trip'.tr),
            ),
          ],
        );
      },
    );
  }
}

class RoutineTripLegCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String time;
  final String pickupAddress;
  final String dropoffAddress;
  final String buttonLabel;
  final bool isButtonEnabled;
  final bool isButtonLoading;
  final VoidCallback? onPressed;
  final VoidCallback? onPickupMapPressed;
  final VoidCallback? onDropoffMapPressed;

  const RoutineTripLegCard({
    super.key,
    required this.title,
    required this.icon,
    required this.time,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.buttonLabel,
    required this.isButtonEnabled,
    this.isButtonLoading = false,
    this.onPressed,
    this.onPickupMapPressed,
    this.onDropoffMapPressed,
  });

  @override
  Widget build(BuildContext context) {
    const activeBlue = Color(0xFF2F6BFF);
    const lightBlue = Color.fromARGB(255, 213, 228, 248);
    const inkBlack = Color(0xFF111111);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightBlue.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: lightBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: activeBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: textBold.copyWith(
                  fontSize: 16,
                  color: activeBlue,
                ),
              ),
              const Spacer(),
              const Icon(Icons.schedule, size: 16, color: activeBlue),
              const SizedBox(width: 4),
              Text(
                time,
                style: textMedium.copyWith(
                  fontSize: 14,
                  color: activeBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Timeline for Pickup & Dropoff
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon timeline vertical column
              Column(
                children: [
                  const Icon(Icons.radio_button_checked_rounded,
                      color: activeBlue, size: 20),
                  Container(
                    width: 2,
                    height: 40,
                    decoration: BoxDecoration(
                      color: activeBlue.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const Icon(Icons.flag_rounded, color: activeBlue, size: 20),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pickup Details
                    Text(
                      'starting_point'.tr,
                      style: textMedium.copyWith(
                        fontSize: 11,
                        color: inkBlack.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pickupAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textMedium.copyWith(
                        fontSize: 13,
                        color: inkBlack,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Dropoff Details
                    Text(
                      'destination'.tr,
                      style: textMedium.copyWith(
                        fontSize: 11,
                        color: inkBlack.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dropoffAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textMedium.copyWith(
                        fontSize: 13,
                        color: inkBlack,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Map buttons for quick navigation
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.map_outlined,
                        color: activeBlue.withValues(alpha: 0.8), size: 20),
                    onPressed: onPickupMapPressed,
                  ),
                  const SizedBox(height: 18),
                  IconButton(
                    icon: Icon(Icons.map_outlined,
                        color: activeBlue.withValues(alpha: 0.8), size: 20),
                    onPressed: onDropoffMapPressed,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isButtonEnabled && !isButtonLoading ? onPressed : null,
              icon: isButtonLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: Text(
                buttonLabel,
                style: textMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: activeBlue,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
