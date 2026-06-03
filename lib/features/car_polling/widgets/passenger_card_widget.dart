import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../util/dimensions.dart';
import '../../../util/images.dart';
import '../../../util/styles.dart';
import '../domain/models/simple_passenger_model.dart';
import '../domain/models/simple_trip_model.dart';
import '../controllers/simple_trip_otp_controller.dart';
import 'passenger_route_info_widget.dart';

class PassengerCardWidget extends StatelessWidget {
  final SimplePassengerModel passenger;
  final SimpleTripModel trip;
  final Function(SimplePassengerModel, SimpleTripOtpController) onOtpTap;
  final Function(BuildContext, SimplePassengerModel, SimpleTripModel)
      onRouteOptionsTap;

  const PassengerCardWidget({
    super.key,
    required this.passenger,
    required this.trip,
    required this.onOtpTap,
    required this.onRouteOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
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
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
                child: ClipOval(
                  child: _PassengerAvatar(passenger: passenger),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.name ?? 'unknown_passenger'.tr,
                      style: textMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    GetBuilder<SimpleTripOtpController>(
                      builder: (controller) {
                        return (passenger.isOtpNotVerified) ?? true
                            ? InkWell(
                                onTap: () {
                                  print(
                                      "trip Status: ${passenger.isOtpNotVerified}");
                                  if ((passenger.isOtpNotVerified) ?? true) {
                                    onOtpTap(passenger, controller);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_user,
                                        size: 12,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'OTP',
                                        style: textMedium.copyWith(
                                          fontSize: 10,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SizedBox();
                      },
                    ),
                    const SizedBox(height: 6),
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
                      onTap: () => onRouteOptionsTap(context, passenger, trip),
                      borderRadius: BorderRadius.circular(10),
                      child: PassengerRouteInfoWidget(
                        passenger: passenger,
                        tripId: trip.id.toString(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],
      ),
    );
  }
}

class _PassengerAvatar extends StatelessWidget {
  final SimplePassengerModel passenger;

  const _PassengerAvatar({required this.passenger});

  @override
  Widget build(BuildContext context) {
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
}
