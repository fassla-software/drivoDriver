import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../domain/models/simple_passenger_model.dart';

class PassengerRouteInfoWidget extends StatelessWidget {
  final SimplePassengerModel passenger;
  final String? tripStartAddress;
  final String? tripEndAddress;
  final bool compact;
  final Color? labelColor;
  final Color? textColor;
  final Color? pickupIconColor;
  final Color? dropoffIconColor;
  final Color? backgroundColor;

  const PassengerRouteInfoWidget({
    super.key,
    required this.passenger,
    this.tripStartAddress,
    this.tripEndAddress,
    this.compact = false,
    this.labelColor,
    this.textColor,
    this.pickupIconColor,
    this.dropoffIconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final pickup = passenger.displayPickupAddress(tripStartAddress);
    final dropoff = passenger.displayDropoffAddress(tripEndAddress);
    final bg = backgroundColor ??
        Theme.of(context).dividerColor.withValues(alpha: 0.12);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
      ),
      child: Column(
        children: [
          _LocationLine(
            label: 'pickup_location'.tr,
            address: pickup,
            icon: Icons.trip_origin_rounded,
            iconColor: pickupIconColor ?? const Color(0xFF2E7D32),
            labelColor: labelColor,
            textColor: textColor,
            compact: compact,
          ),
          SizedBox(height: compact ? 4 : 6),
          _LocationLine(
            label: 'dropoff_location'.tr,
            address: dropoff,
            icon: Icons.flag_rounded,
            iconColor: dropoffIconColor ?? const Color(0xFFC62828),
            labelColor: labelColor,
            textColor: textColor,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  final String label;
  final String address;
  final IconData icon;
  final Color iconColor;
  final Color? labelColor;
  final Color? textColor;
  final bool compact;

  const _LocationLine({
    required this.label,
    required this.address,
    required this.icon,
    required this.iconColor,
    this.labelColor,
    this.textColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hint = labelColor ?? Theme.of(context).hintColor;
    final body = textColor ?? Theme.of(context).textTheme.bodyMedium?.color;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: compact ? 14 : 16, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: textRegular.copyWith(
                fontSize: compact ? Dimensions.fontSizeExtraSmall : 12,
                color: body,
                height: 1.25,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: textMedium.copyWith(
                    fontSize: compact ? Dimensions.fontSizeExtraSmall : 12,
                    color: hint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: address,
                  style: textMedium.copyWith(
                    fontSize: compact ? Dimensions.fontSizeExtraSmall : 12,
                    color: body,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
