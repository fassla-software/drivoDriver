import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../common_widgets/app_bar_widget.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../controllers/register_route_controller.dart';
import '../../../localization/localization_controller.dart';
import '../widgets/enhanced_coordinate_widget.dart';
import '../widgets/rest_stop_widget.dart';

class RegisterRouteScreen extends StatefulWidget {
  final String type;

  const RegisterRouteScreen({super.key, required this.type});

  @override
  State<RegisterRouteScreen> createState() => _RegisterRouteScreenState();
}

class _RegisterRouteScreenState extends State<RegisterRouteScreen> {
  static const _lightBlue = Color(0xFFA9D0F5);
  static const _inkBlack = Color(0xFF111111);
  static const _activeBlue = Color(0xFF2F6BFF);

  bool _showPreferences = true;
  bool _showFeatures = false;
  bool _showRestStops = false;
  DateTime? _departureDate;
  TimeOfDay? _departureTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<RegisterRouteController>();
      final String mappedType = widget.type == 'single' ? 'trip' : widget.type;
      controller.setRideType(mappedType);
      _loadDateTimeFromController(controller);
      controller.fetchBoardingPoints();
    });
  }

  String get _mappedRideType => widget.type == 'single' ? 'trip' : widget.type;

  void _loadDateTimeFromController(RegisterRouteController controller) {
    final raw = controller.startTimeController.text;
    if (raw.isEmpty) return;
    try {
      final dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw);
      setState(() {
        _departureDate = dt;
        if (_mappedRideType != 'routine') {
          _departureTime = TimeOfDay.fromDateTime(dt);
        }
      });
    } catch (_) {}
  }

  TimeOfDay _routineDepartureTimeOfDay(RegisterRouteController controller) {
    final raw = controller.departureTimeController.text.trim();
    if (raw.isEmpty) return const TimeOfDay(hour: 0, minute: 0);
    final parts = raw.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 0, minute: 0);
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _saveDateTimeToController(RegisterRouteController controller) {
    final departureDate = _departureDate;
    if (departureDate == null) return;

    final TimeOfDay effectiveTime;
    if (_mappedRideType == 'routine') {
      effectiveTime = _routineDepartureTimeOfDay(controller);
    } else {
      final departureTime = _departureTime;
      if (departureTime == null) return;
      effectiveTime = departureTime;
    }

    final dt = DateTime(
      departureDate.year,
      departureDate.month,
      departureDate.day,
      effectiveTime.hour,
      effectiveTime.minute,
    );
    controller.startTimeController.text =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
  }

  String get _tripTypeLabel {
    final String mappedType = widget.type == 'single' ? 'trip' : widget.type;
    switch (mappedType) {
      case 'trip':
        return 'One Trip';
      case 'travel':
        return 'Travel';
      case 'routine':
        return 'Routine';
      case 'north_coast':
        return 'North Coast';
      default:
        return mappedType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String rideType = widget.type == 'single' ? 'trip' : widget.type;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: _tripTypeLabel,
        showBackButton: true,
      ),
      body: GetBuilder<RegisterRouteController>(
        init: Get.find<RegisterRouteController>(),
        builder: (controller) {
          controller.onShowSnackBar = (message, backgroundColor,
              {icon = Icons.info_outline,
              duration = const Duration(seconds: 3)}) {
            _showSnackBar(
              message: message,
              backgroundColor: backgroundColor,
              icon: icon,
              duration: duration,
            );
          };

          final progress = _calculateProgress(controller);

          try {
            return Stack(
              children: [
                Column(
                  children: [
                    _buildProgressStrip(progress),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPromoBanner(),
                            const SizedBox(height: 22),
                            Text(
                              'where_do_you_want_to_go'.tr,
                              style: textBold.copyWith(
                                fontSize: Dimensions.fontSizeExtraLarge,
                                color: _inkBlack,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (rideType == 'travel')
                              CascadedBoardingPointDropdowns(
                                controller: controller,
                                fieldColor: _lightBlue,
                                activeColor: _activeBlue,
                              )
                            else
                              _buildRouteSection(controller),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      final departureDate = _departureDate;
                                      return _buildDateTimeTile(
                                        label: 'date'.tr,
                                        value: departureDate == null
                                            ? null
                                            : DateFormat('dd/MM/yyyy')
                                                .format(departureDate),
                                        icon: Icons.calendar_today_outlined,
                                        onTap: () => _pickDate(controller),
                                      );
                                    },
                                  ),
                                ),
                                if (rideType != 'routine') ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Builder(
                                      builder: (context) {
                                        final departureTime = _departureTime;
                                        return _buildDateTimeTile(
                                          label: 'time'.tr,
                                          value: departureTime?.format(context),
                                          icon: Icons.access_time_rounded,
                                          onTap: () => _pickTime(controller),
                                        );
                                      },
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            if (rideType == 'routine') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDateTimeTile(
                                      label: 'Departure Time'.tr,
                                      value: controller.departureTimeController
                                              .text.isNotEmpty
                                          ? controller
                                              .departureTimeController.text
                                          : null,
                                      icon: Icons.alarm_on_rounded,
                                      onTap: () =>
                                          _pickRoutineDepartureTime(controller),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDateTimeTile(
                                      label: 'Return Time'.tr,
                                      value: controller.returnTimeController
                                              .text.isNotEmpty
                                          ? controller.returnTimeController.text
                                          : null,
                                      icon: Icons.alarm_off_rounded,
                                      onTap: () =>
                                          _pickRoutineReturnTime(controller),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 22),
                            Text(
                              'vehicle_and_pricing'.tr,
                              style: textBold.copyWith(
                                fontSize: Dimensions.fontSizeLarge,
                                color: _inkBlack,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildWhiteField(
                                    label: 'price_per_seat'.tr,
                                    controller: controller.priceController,
                                    keyboardType: TextInputType.number,
                                    icon: Icons.payments_outlined,
                                    hint: '0',
                                    suffix: 'EGP',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildWhiteField(
                                    label: 'available_seats'.tr,
                                    controller: controller.seatsController,
                                    keyboardType: TextInputType.number,
                                    icon: Icons.event_seat_outlined,
                                    hint: '1-50',
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(2),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (rideType == 'trip' ||
                                rideType == 'travel' ||
                                rideType == 'routine' ||
                                rideType == 'north_coast') ...[
                              const SizedBox(height: 22),
                              _buildExpandable(
                                title: 'ride_preferences'.tr,
                                expanded: _showPreferences,
                                onToggle: () => setState(
                                    () => _showPreferences = !_showPreferences),
                                child: _buildPreferences(controller),
                              ),
                            ],
                            if (rideType == 'trip' ||
                                rideType == 'travel' ||
                                rideType == 'routine' ||
                                rideType == 'north_coast') ...[
                              const SizedBox(height: 10),
                              _buildExpandable(
                                title: 'vehicle_features'.tr,
                                expanded: _showFeatures,
                                onToggle: () => setState(
                                    () => _showFeatures = !_showFeatures),
                                child: _buildFeatureChips(controller, rideType),
                              ),
                            ],
                            if (rideType == 'trip') ...[
                              const SizedBox(height: 10),
                              _buildExpandable(
                                title: 'rest_stops'.tr,
                                expanded: _showRestStops,
                                onToggle: () => setState(
                                    () => _showRestStops = !_showRestStops),
                                child: RestStopWidget(
                                  restStops: controller.restStops,
                                  onAddRestStop: controller.addRestStop,
                                  onRemoveRestStop: controller.removeRestStop,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildStickySubmit(controller, progress),
                ),
                if (controller.isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          } catch (e) {
            return _buildErrorState();
          }
        },
      ),
    );
  }

  Widget _buildProgressStrip(double progress) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'form_completion'.tr,
                  style: textMedium.copyWith(fontSize: 12, color: _inkBlack),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: textBold.copyWith(color: _activeBlue, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: _lightBlue.withValues(alpha: 0.35),
              valueColor: const AlwaysStoppedAnimation<Color>(_activeBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _inkBlack,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'share_your_journey'.tr,
                      style: textBold.copyWith(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'find_passengers_on_your_route'.tr,
                      style: textRegular.copyWith(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'create_new_route'.tr,
              style: textRegular.copyWith(fontSize: 11, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSection(RegisterRouteController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Column(
            children: [
              Icon(Icons.trip_origin, color: _activeBlue, size: 20),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: List.generate(
                    4,
                    (_) => Container(
                      width: 2,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: _activeBlue.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const Icon(Icons.flag_rounded, color: _inkBlack, size: 20),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              EnhancedCoordinateWidget(
                title: 'starting_point'.tr,
                latController: controller.startLatController,
                lngController: controller.startLngController,
                icon: Icons.trip_origin,
                iconColor: _activeBlue,
                compactBlueStyle: true,
                fieldColor: _lightBlue,
                onLocationChanged: () => setState(() {}),
              ),
              EnhancedCoordinateWidget(
                title: 'destination'.tr,
                latController: controller.endLatController,
                lngController: controller.endLngController,
                icon: Icons.flag,
                iconColor: _activeBlue,
                compactBlueStyle: true,
                fieldColor: _lightBlue,
                onLocationChanged: () => setState(() {}),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeTile({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: _activeBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: textMedium.copyWith(fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      value ?? 'select'.tr,
                      style: textRegular.copyWith(
                        fontSize: 14,
                        color: value != null ? _inkBlack : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhiteField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    IconData? icon,
    String? hint,
    String? suffix,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textMedium.copyWith(fontSize: 12, color: _inkBlack),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: textMedium.copyWith(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textRegular.copyWith(color: Colors.grey, fontSize: 14),
            prefixIcon:
                icon != null ? Icon(icon, size: 20, color: _activeBlue) : null,
            suffixText: suffix,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _activeBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandable({
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: _activeBlue, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: textMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _inkBlack,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _buildPreferences(RegisterRouteController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildWhiteField(
                label: 'minimum_age'.tr,
                controller: controller.minAgeController,
                keyboardType: TextInputType.number,
                hint: '13',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildWhiteField(
                label: 'maximum_age'.tr,
                controller: controller.maxAgeController,
                keyboardType: TextInputType.number,
                hint: '100',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('allowed_gender'.tr,
            style: textMedium.copyWith(fontSize: 12, color: _inkBlack)),
        const SizedBox(height: 8),
        _buildGenderChips(controller),
      ],
    );
  }

  Widget _buildGenderChips(RegisterRouteController controller) {
    const options = ['both', 'male', 'female'];
    return Row(
      children: options.map((option) {
        final selected = controller.allowedGender == option;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: option != 'female' ? 8 : 0),
            child: ChoiceChip(
              label: Text(option.tr,
                  style: textMedium.copyWith(
                    fontSize: 12,
                    color: selected ? Colors.white : _inkBlack,
                  )),
              selected: selected,
              onSelected: (_) => controller.setAllowedGender(option),
              selectedColor: _activeBlue,
              backgroundColor: _lightBlue.withValues(alpha: 0.35),
              side: BorderSide(
                color: selected ? _activeBlue : const Color(0xFFE0E0E0),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeatureChips(
      RegisterRouteController controller, String rideType) {
    // if (rideType == 'travel') {
    //   // Travel type only supports AC feature
    //   return FilterChip(
    //     label: Text('air_conditioning'.tr,
    //         style: textRegular.copyWith(fontSize: 12)),
    //     selected: controller.isAc,
    //     onSelected: (_) => controller.setIsAc(!controller.isAc),
    //     avatar: Icon(Icons.ac_unit_rounded,
    //         size: 18, color: controller.isAc ? _activeBlue : Colors.grey),
    //     selectedColor: _lightBlue,
    //     checkmarkColor: _activeBlue,
    //     side: BorderSide(
    //       color: controller.isAc ? _activeBlue : const Color(0xFFE0E0E0),
    //     ),
    //   );
    // }

    final features = [
      (
        'air_conditioning'.tr,
        controller.isAc,
        controller.setIsAc,
        Icons.ac_unit_rounded
      ),
      (
        'smoking_allowed'.tr,
        controller.isSmokingAllowed,
        controller.setIsSmokingAllowed,
        Icons.smoking_rooms_rounded
      ),
      (
        'music_system'.tr,
        controller.hasMusic,
        controller.setHasMusic,
        Icons.music_note_rounded
      ),
      (
        'screen_entertainment'.tr,
        controller.hasScreenEntertainment,
        controller.setHasScreenEntertainment,
        Icons.tv_rounded
      ),
      (
        'allow_luggage'.tr,
        controller.allowLuggage,
        controller.setAllowLuggage,
        Icons.luggage_rounded
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features.map((f) {
        return FilterChip(
          label: Text(f.$1, style: textRegular.copyWith(fontSize: 12)),
          selected: f.$2,
          onSelected: (_) => f.$3(!f.$2),
          avatar: Icon(f.$4, size: 18, color: f.$2 ? _activeBlue : Colors.grey),
          selectedColor: _lightBlue,
          checkmarkColor: _activeBlue,
          side: BorderSide(
            color: f.$2 ? _activeBlue : const Color(0xFFE0E0E0),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStickySubmit(
      RegisterRouteController controller, double progress) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed:
                _canSubmit(controller) ? () => _showDataPreviewDialog() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _inkBlack,
              disabledBackgroundColor: const Color(0xFF555555),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              _canSubmit(controller)
                  ? 'register_route'.tr
                  : 'complete_required_fields'.tr,
              style: textBold.copyWith(
                color: Colors.white,
                fontSize: Dimensions.fontSizeDefault,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  bool _canSubmit(RegisterRouteController controller) {
    final String type = widget.type == 'single' ? 'trip' : widget.type;

    final bool hasRoute = type == 'travel'
        ? (controller.selectedStartBoardingPoint != null &&
            controller.selectedEndBoardingPoint != null)
        : (controller.startLatController.text.isNotEmpty &&
            controller.startLngController.text.isNotEmpty &&
            controller.endLatController.text.isNotEmpty &&
            controller.endLngController.text.isNotEmpty);

    final bool hasRoutineTimes = type == 'routine'
        ? (controller.departureTimeController.text.isNotEmpty &&
            controller.returnTimeController.text.isNotEmpty)
        : true;

    return hasRoute &&
        hasRoutineTimes &&
        controller.startTimeController.text.isNotEmpty &&
        controller.priceController.text.isNotEmpty &&
        controller.seatsController.text.isNotEmpty;
  }

  double _calculateProgress(RegisterRouteController controller) {
    final String type = widget.type == 'single' ? 'trip' : widget.type;
    int required = 0;
    int total = 7;

    if (type == 'travel') {
      if (controller.selectedStartBoardingPoint != null) required += 2;
      if (controller.selectedEndBoardingPoint != null) required += 2;
    } else {
      if (controller.startLatController.text.isNotEmpty) required++;
      if (controller.startLngController.text.isNotEmpty) required++;
      if (controller.endLatController.text.isNotEmpty) required++;
      if (controller.endLngController.text.isNotEmpty) required++;
    }

    if (controller.startTimeController.text.isNotEmpty) required++;
    if (controller.priceController.text.isNotEmpty) required++;
    if (controller.seatsController.text.isNotEmpty) required++;

    if (type == 'routine') {
      total = 9;
      if (controller.departureTimeController.text.isNotEmpty) required++;
      if (controller.returnTimeController.text.isNotEmpty) required++;
    }

    return (required / total).clamp(0.0, 1.0);
  }

  Future<void> _pickDate(RegisterRouteController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _departureDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _activeBlue,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) {
      setState(() => _departureDate = date);
      _saveDateTimeToController(controller);
    }
  }

  Future<void> _pickTime(RegisterRouteController controller) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _departureTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _activeBlue,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null && mounted) {
      setState(() => _departureTime = time);
      _saveDateTimeToController(controller);
    }
  }

  Future<void> _pickRoutineDepartureTime(
      RegisterRouteController controller) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _activeBlue,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null && mounted) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      setState(() {
        controller.departureTimeController.text = '$hour:$minute';
      });
      _saveDateTimeToController(controller);
    }
  }

  Future<void> _pickRoutineReturnTime(
      RegisterRouteController controller) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _activeBlue,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null && mounted) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      setState(() {
        controller.returnTimeController.text = '$hour:$minute';
      });
    }
  }

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
    IconData icon = Icons.info_outline,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child:
                    Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _showDataPreviewDialog() async {
    final controller = Get.find<RegisterRouteController>();
    final String type = widget.type == 'single' ? 'trip' : widget.type;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('route_preview'.tr, style: textBold),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (type == 'travel') ...[
                  _buildDataRow('Starting Boarding Point',
                      '${controller.selectedStartBoardingPoint?.name ?? ''} (${controller.selectedStartCity?.name ?? ''})'),
                  _buildDataRow('Destination Boarding Point',
                      '${controller.selectedEndBoardingPoint?.name ?? ''} (${controller.selectedEndCity?.name ?? ''})'),
                ] else ...[
                  _buildDataRow('starting_point'.tr,
                      '${controller.startLatController.text}, ${controller.startLngController.text}'),
                  _buildDataRow('destination'.tr,
                      '${controller.endLatController.text}, ${controller.endLngController.text}'),
                ],
                _buildDataRow(
                    'departure_time'.tr, controller.startTimeController.text),
                if (type == 'routine') ...[
                  _buildDataRow('Departure Time',
                      controller.departureTimeController.text),
                  _buildDataRow(
                      'Return Time', controller.returnTimeController.text),
                ],
                _buildDataRow('price_per_seat'.tr,
                    '${controller.priceController.text} EGP'),
                _buildDataRow(
                    'available_seats'.tr, controller.seatsController.text),
                if (type == 'trip' || type == 'travel')
                  _buildDataRow('features'.tr, _getFeaturesList(controller)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('edit'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _inkBlack,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              controller.registerRoute();
            },
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: textMedium.copyWith(
                    fontSize: 12, color: Theme.of(context).hintColor)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? 'not_set'.tr : value,
              style: textRegular.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _getFeaturesList(RegisterRouteController controller) {
    final features = <String>[];
    if (controller.isAc) features.add('air_conditioning'.tr);
    final String mappedType = widget.type == 'single' ? 'trip' : widget.type;
    if (mappedType != 'travel') {
      if (controller.isSmokingAllowed) features.add('smoking_allowed'.tr);
      if (controller.hasMusic) features.add('music_system'.tr);
      if (controller.hasScreenEntertainment) {
        features.add('screen_entertainment'.tr);
      }
      if (controller.allowLuggage) features.add('allow_luggage'.tr);
    }
    return features.isEmpty ? 'none'.tr : features.join(', ');
  }
}

class CascadedBoardingPointDropdowns extends StatelessWidget {
  final RegisterRouteController controller;
  final Color fieldColor;
  final Color activeColor;

  const CascadedBoardingPointDropdowns({
    super.key,
    required this.controller,
    required this.fieldColor,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingBoardingPoints) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(color: activeColor),
        ),
      );
    }

    final bool isLtr = Get.find<LocalizationController>().isLtr;

    final startBoardingPoints = controller.selectedStartCity == null
        ? <BoardingPoint>[]
        : controller.boardingPoints
            .where((bp) => bp.cityId == controller.selectedStartCity!.id)
            .toList();

    final endBoardingPoints = controller.selectedEndCity == null
        ? <BoardingPoint>[]
        : controller.boardingPoints
            .where((bp) => bp.cityId == controller.selectedEndCity!.id)
            .toList();

    return Column(
      children: [
        // Starting Boarding Point Section
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: fieldColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: fieldColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trip_origin, color: activeColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'starting_point'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<City>(
                      value: controller.selectedStartCity,
                      decoration: InputDecoration(
                        labelText: 'City',
                        labelStyle: const TextStyle(fontSize: 12),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                      items: controller.cities.map((city) {
                        return DropdownMenuItem<City>(
                          value: city,
                          child: Text(isLtr ? city.name : city.nameAr,
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (city) => controller.setStartCity(city),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<BoardingPoint>(
                      value: controller.selectedStartBoardingPoint,
                      disabledHint: const Text('Select city',
                          style: TextStyle(fontSize: 12)),
                      decoration: InputDecoration(
                        labelText: 'Boarding Point',
                        labelStyle: const TextStyle(fontSize: 12),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                      items: startBoardingPoints.map((bp) {
                        return DropdownMenuItem<BoardingPoint>(
                          value: bp,
                          child: Text(isLtr ? bp.name : bp.nameAr,
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: controller.selectedStartCity == null
                          ? null
                          : (bp) => controller.setStartBoardingPoint(bp),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Destination Boarding Point Section
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: fieldColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: fieldColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag_rounded, color: activeColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'destination'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<City>(
                      value: controller.selectedEndCity,
                      decoration: InputDecoration(
                        labelText: 'City',
                        labelStyle: const TextStyle(fontSize: 12),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                      items: controller.cities.map((city) {
                        return DropdownMenuItem<City>(
                          value: city,
                          child: Text(isLtr ? city.name : city.nameAr,
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (city) => controller.setEndCity(city),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<BoardingPoint>(
                      value: controller.selectedEndBoardingPoint,
                      disabledHint: const Text('Select city',
                          style: TextStyle(fontSize: 12)),
                      decoration: InputDecoration(
                        labelText: 'Boarding Point',
                        labelStyle: const TextStyle(fontSize: 12),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                      items: endBoardingPoints.map((bp) {
                        return DropdownMenuItem<BoardingPoint>(
                          value: bp,
                          child: Text(isLtr ? bp.name : bp.nameAr,
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: controller.selectedEndCity == null
                          ? null
                          : (bp) => controller.setEndBoardingPoint(bp),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
