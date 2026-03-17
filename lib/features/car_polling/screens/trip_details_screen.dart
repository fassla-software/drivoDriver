import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../../../common_widgets/app_bar_widget.dart';
import '../controllers/simple_trips_controller.dart';
import '../domain/models/simple_trip_model.dart';
import 'simple_trip_map_screen.dart';

class TripDetailsScreen extends StatelessWidget {
  final SimpleTripModel trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'trip_details'.tr,
        showBackButton: true,
      ),
      body: GetBuilder<SimpleTripsController>(builder: (controller) {
        // Ensure we are using the latest trip data if available in the controller
        final currentTrip =
            controller.trips.firstWhereOrNull((t) => t.id == trip.id) ?? trip;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, controller, currentTrip),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              _buildRouteInfo(context, currentTrip),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              _buildTripInfo(context, controller, currentTrip),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              if (currentTrip.passengers != null &&
                  currentTrip.passengers!.isNotEmpty)
                _buildPassengersList(context, currentTrip),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              _buildActionButtons(context, controller, currentTrip),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context, SimpleTripsController controller,
      SimpleTripModel trip) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'trip_id'.tr,
                    style: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  Text(
                    ' #${trip.id}',
                    style: textBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: Theme.of(context).hintColor),
                  const SizedBox(width: 4),
                  Text(
                    '${trip.formattedStartDate} • ${trip.formattedStartTime}',
                    style: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: controller
                  .getTripStatusColor(trip.tripStatus)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: controller.getTripStatusColor(trip.tripStatus)),
            ),
            child: Text(
              controller.getTripStatusDisplayText(trip.tripStatus),
              style: textMedium.copyWith(
                color: controller.getTripStatusColor(trip.tripStatus),
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(BuildContext context, SimpleTripModel trip) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'route'.tr,
            style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(Icons.my_location, color: Colors.green, size: 24),
                  Container(
                    height: 40,
                    width: 2,
                    color: Theme.of(context).hintColor.withOpacity(0.2),
                  ),
                  Icon(Icons.location_on, color: Colors.red, size: 24),
                ],
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.startAddress ?? 'unknown_location'.tr,
                      style: textMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault),
                    ),
                    const SizedBox(
                        height: 45), // Match height of line + icons roughly
                    Text(
                      trip.endAddress ?? 'unknown_location'.tr,
                      style: textMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripInfo(BuildContext context, SimpleTripsController controller,
      SimpleTripModel trip) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(context, 'available_seats'.tr,
                  '${controller.getAvailableSeats(trip)}', Icons.event_seat),
              _buildInfoItem(context, 'passengers'.tr,
                  '${trip.passengersCount ?? 0}', Icons.people),
              _buildInfoItem(
                  context, 'price'.tr, trip.formattedPrice, Icons.attach_money),
            ],
          ),
          if (trip.tripType != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.repeat, color: Theme.of(context).primaryColor),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'recurrence'.tr,
                        style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      Text(
                        trip.tripType == 'repeated' ? 'repeated'.tr : 'once'.tr,
                        style: textMedium.copyWith(
                            fontSize: Dimensions.fontSizeDefault),
                      ),
                      if (trip.tripType == 'repeated' &&
                          trip.tripDates != null &&
                          trip.tripDates!.isNotEmpty)
                        _buildRecurringDates(context, trip),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (trip.vehicleName != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.directions_car,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Text(
                  trip.vehicleName!,
                  style:
                      textMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
              ],
            ),
          ],
          if (trip.features.isNotEmpty) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trip.features
                  .map((feature) => Chip(
                        label: Text(feature,
                            style: textRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall)),
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.1),
                        labelStyle:
                            TextStyle(color: Theme.of(context).primaryColor),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecurringDates(BuildContext context, SimpleTripModel trip) {
    final validDates = trip.tripDates!
        .where((d) => d.isCancelled != true && d.date != null)
        .map((d) => d.date!)
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
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.2)),
                        ),
                        child: Text(
                          date,
                          style: textRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoItem(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: textBold.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: Theme.of(context).primaryColor),
        ),
        Text(
          label,
          style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).hintColor),
        ),
      ],
    );
  }

  Widget _buildPassengersList(BuildContext context, SimpleTripModel trip) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'passengers'.tr,
            style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trip.passengers!.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final passenger = trip.passengers![index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: passenger.profileImage != null
                      ? NetworkImage(passenger.profileImage!)
                      : null,
                  child: passenger.profileImage == null
                      ? Icon(Icons.person,
                          color: Theme.of(context).primaryColor)
                      : null,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                title: Text(passenger.name ?? 'unknown_passenger'.tr,
                    style: textMedium),
                subtitle: Text(
                    '${passenger.seatsCount ?? 1} ${'seats'.tr} • ${passenger.formattedFare}'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context,
      SimpleTripsController controller, SimpleTripModel trip) {
    if (trip.tripStatus == 'pending') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isTripBeingStarted(trip.id ?? 0)
                  ? null
                  : () => controller.startTrip(trip.id ?? 0),
              icon: controller.isTripBeingStarted(trip.id ?? 0)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow, color: Colors.white),
              label: Text('start_trip'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeDefault),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.isTripBeingCancelled(trip.id ?? 0)
                  ? null
                  : () {
                      _showCancelOptions(context, controller, trip);
                    },
              icon: controller.isTripBeingCancelled(trip.id ?? 0)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.red),
                    )
                  : const Icon(Icons.cancel, color: Colors.red),
              label: Text(
                'cancel_trip'.tr,
                style: const TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeDefault),
              ),
            ),
          ),
        ],
      );
    } else if (trip.tripStatus == 'ongoing') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (trip.startCoordinates != null &&
                    trip.endCoordinates != null) {
                  Get.to(() => SimpleTripMapScreen(trip: trip));
                } else {
                  Get.snackbar('error'.tr, 'no_route_coordinates'.tr,
                      backgroundColor: Colors.red, colorText: Colors.white);
                }
              },
              icon: const Icon(Icons.map, color: Colors.white),
              label: Text('show_map'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeDefault),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: controller.isTripBeingEnded(trip.id ?? 0)
                  ? null
                  : () =>
                      _showEndTripConfirmationDialog(context, controller, trip),
              icon: controller.isTripBeingEnded(trip.id ?? 0)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.stop, color: Colors.white),
              label: Text('end_trip'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeDefault),
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
    if (trip.tripType == 'repeated' &&
        trip.tripDates != null &&
        trip.tripDates!.isNotEmpty) {
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
            ?.where((dateModel) =>
                dateModel.isCancelled != true && dateModel.date != null)
            .map((dateModel) => dateModel.date!)
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
          title: Text('end_trip'.tr),
          content: Text('end_trip_confirmation'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.endTrip(trip.id ?? 0);
              },
              child: Text(
                'end'.tr,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
