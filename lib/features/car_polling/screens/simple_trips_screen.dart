import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/car_polling/screens/register_route_screen.dart';
import '../../../common_widgets/app_bar_widget.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../controllers/simple_trips_controller.dart';
import '../domain/models/simple_trip_model.dart';
import '../domain/models/simple_passenger_model.dart';
import 'simple_trip_map_screen.dart';
import 'trip_details_screen.dart';

class SimpleTripsScreen extends StatefulWidget {
  const SimpleTripsScreen({super.key});

  @override
  State<SimpleTripsScreen> createState() => _SimpleTripsScreenState();
}

class _SimpleTripsScreenState extends State<SimpleTripsScreen>
    with SingleTickerProviderStateMixin {
  static const _inkBlack = Color.fromARGB(255, 0, 0, 0);
  static const _activeBlue = Color(0xFF2F6BFF);
  static const _lightBlue = Color.fromARGB(255, 213, 228, 248);
  static const _lightBlueSoft = Color.fromARGB(255, 213, 228, 248);

  late TabController _tabController;
  late SimpleTripsController controller;

  Color _headerColor(String? status) {
    switch (status) {
      case 'pending':
      case 'ongoing':
        return _inkBlack;
      case 'completed':
        return _inkBlack;
      case 'cancelled':
        return _inkBlack;
      default:
        return _inkBlack;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Get or create the controller
    try {
      controller = Get.find<SimpleTripsController>();
      if (kDebugMode) {
        print('=== SimpleTripsController found: $controller ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('=== SimpleTripsController not found, creating new one: $e ===');
      }
      controller = Get.put(SimpleTripsController(
        currentTripsServiceInterface: Get.find(),
      ));
    }

    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        print('=== Loading data in postFrameCallback ===');
      }
      controller.getCurrentTrips();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: 'my_current_trips'.tr,
        showBackButton: true,
        backgroundColor: _inkBlack,
      ),
      body: GetBuilder<SimpleTripsController>(
        init: controller,
        builder: (ctrl) {
          if (ctrl.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _activeBlue),
            );
          }

          return (controller.isStartingTrip || controller.isEndingTrip)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: _activeBlue,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Text(
                        controller.isStartingTrip
                            ? 'starting_trip'.tr
                            : 'ending'.tr,
                        style: textMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Tab Bar
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeLarge,
                        vertical: Dimensions.paddingSizeDefault,
                      ),
                      decoration: BoxDecoration(
                        color: _inkBlack,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _lightBlue.withValues(alpha: 0.7),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: _activeBlue,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                        labelStyle: textMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                        tabs: [
                          Tab(text: 'pending'.tr),
                          Tab(text: 'ongoing'.tr),
                          Tab(text: 'completed'.tr),
                          Tab(text: 'cancelled'.tr),
                        ],
                      ),
                    ),

                    // Tab Bar View
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTripsListView(ctrl, ctrl.pendingTrips),
                          _buildTripsListView(ctrl, ctrl.ongoingTrips),
                          _buildTripsListView(ctrl, ctrl.completedTrips),
                          _buildTripsListView(ctrl, ctrl.cancelledTrips),
                        ],
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildTripsListView(
      SimpleTripsController controller, List<SimpleTripModel> trips) {
    if (trips.isEmpty) {
      return Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [

      /// 🌟 Fancy icon container instead of plain icon
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _lightBlue.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(color: _activeBlue.withValues(alpha: 0.25)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.route_outlined,
              size: 55,
              color: _activeBlue,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: _inkBlack,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 18),

      /// Title
      Text(
        'no_trips_found'.tr,
        style: textMedium.copyWith(
          fontSize: Dimensions.fontSizeLarge,
          fontWeight: FontWeight.w600,
        ),
      ),

      const SizedBox(height: 8),

      /// Subtitle
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Text(
          'no_trips_description'.tr,
          textAlign: TextAlign.center,
          style: textRegular.copyWith(
            color: Theme.of(context).hintColor,
          ),
        ),
      ),

      const SizedBox(height: 20),

      /// Optional CTA button
      ElevatedButton.icon(
        onPressed: () {
          Get.to(() => const RegisterRouteScreen(type: 'trip'));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _inkBlack,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.add),
        label: Text('Create Trip'.tr),
      ),
    ],
  ),
);
    }

    return RefreshIndicator(
      color: _activeBlue,
      onRefresh: () => controller.refreshTrips(),
      child: ListView.builder(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _buildTripCard(controller, trip, index);
        },
      ),
    );
  }

  Widget _buildTripCard(
      SimpleTripsController controller, SimpleTripModel trip, int index) {
    final status = trip.tripStatus ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _headerColor(status).withValues(alpha: 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Get.to(() => TripDetailsScreen(trip: trip)),
        borderRadius: BorderRadius.circular(18),
        child: _buildUnifiedTripCardBody(controller, trip),
      ),
    );
  }

  Widget _buildUnifiedTripCardBody(
      SimpleTripsController controller, SimpleTripModel trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTripHeader(controller, trip),
        Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'where_do_you_want_to_go'.tr,
                style: textBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: _inkBlack,
                ),
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: _inkBlack.withValues(alpha: 0.08)),
                    bottom: BorderSide(color: _inkBlack.withValues(alpha: 0.08)),
                  ),
                ),
                child: _buildTripDetailsSection(controller, trip),
              ),
              _buildTripActions(controller, trip),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripActions(
      SimpleTripsController controller, SimpleTripModel trip) {
    switch (trip.tripStatus) {
      case 'pending':
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: controller.isTripBeingStarted(trip.id ?? 0)
                  ? null
                  : () => controller.startTrip(trip.id ?? 0),
              style: ElevatedButton.styleFrom(
                backgroundColor: _inkBlack,
                disabledBackgroundColor: _inkBlack.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              icon: controller.isTripBeingStarted(trip.id ?? 0)
                  ? const SizedBox.shrink()
                  : const Icon(Icons.play_arrow_rounded, size: 22),
              label: controller.isTripBeingStarted(trip.id ?? 0)
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'start_trip'.tr,
                      style: textBold.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        );

      case 'ongoing':
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (trip.startCoordinates != null &&
                          trip.endCoordinates != null) {
                        Get.to(() => SimpleTripMapScreen(trip: trip));
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _activeBlue,
                      side: const BorderSide(color: _activeBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: const Icon(Icons.map, size: 18),
                    label: Text('show_map'.tr),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showEndTripConfirmationDialog(controller, trip),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: const Icon(Icons.stop, size: 18),
                    label: Text('end_trip'.tr),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'completed':
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 29, 162, 60).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color.fromARGB(255, 8, 133, 41).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Color(0xFF1A5C8A), size: 20),
                const SizedBox(width: 8),
                Text(
                  'completed'.tr,
                  style: textMedium.copyWith(
                    color: const Color(0xFF1A5C8A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );

      case 'cancelled':
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFC62828).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFC62828).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cancel_outlined,
                    color: Color(0xFFC62828), size: 20),
                const SizedBox(width: 8),
                Text(
                  'cancelled'.tr,
                  style: textMedium.copyWith(
                    color: const Color(0xFFC62828),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
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
                  maxLines: 2,
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
          Icon(
            Icons.map_outlined,
            color: _activeBlue.withValues(alpha: 0.8),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTripHeader(
    SimpleTripsController controller,
    SimpleTripModel trip,
  ) {
    final headerColor = _headerColor(trip.tripStatus);

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(17),
          topRight: Radius.circular(17),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
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
                      style: textMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
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
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Text(
              controller.getTripStatusDisplayText(trip.tripStatus),
              style: textMedium.copyWith(
                color: Colors.white,
                fontSize: Dimensions.fontSizeExtraSmall,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailsSection(
      SimpleTripsController controller, SimpleTripModel trip) {
    return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'available_seats'.tr,
                  '${controller.getAvailableSeats(trip)}',
                  Icons.airline_seat_recline_normal,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'passengers'.tr,
                  '${trip.passengersCount ?? 0}',
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'price'.tr,
                  trip.formattedPrice,
                  Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
          if (trip.vehicleName != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _buildVehicleInfo(trip),
          ],
          if (trip.features.isNotEmpty) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _buildRouteFeatures(trip),
          ],
        ],
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: _activeBlue, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: textMedium.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: _inkBlack,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          title,
          style: textRegular.copyWith(
            fontSize: Dimensions.fontSizeExtraSmall,
            color: Theme.of(context).hintColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVehicleInfo(SimpleTripModel trip) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _lightBlue.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_car,
            color: _activeBlue,
            size: 20,
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              trip.vehicleName ?? 'unknown_vehicle'.tr,
              style: textMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteFeatures(SimpleTripModel trip) {
    final features = trip.features;
    if (features.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'features'.tr,
          style: textMedium.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: features
              .map((feature) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _lightBlue.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _activeBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      feature,
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: _activeBlue,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }


  /// Show confirmation dialog for ending trip
  void _showEndTripConfirmationDialog(
      SimpleTripsController controller, SimpleTripModel trip) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: _activeBlue,
                size: 24,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                'end_trip'.tr,
                style: textBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'are_you_sure_end_trip'.tr,
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'Trip ID: #${trip.id}',
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'this_action_cannot_be_undone'.tr,
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'cancel'.tr,
                style: textMedium.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.endTrip(trip.id ?? 0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _inkBlack,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'end_trip'.tr,
                style: textMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
