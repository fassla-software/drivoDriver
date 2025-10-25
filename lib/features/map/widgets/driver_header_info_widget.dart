import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';

import 'package:ride_sharing_user_app/common_widgets/image_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverHeaderInfoWidget extends StatelessWidget {
  const DriverHeaderInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingSizeDefault, 60, Dimensions.paddingSizeDefault, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Theme.of(context).primaryColor)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: ImageWidget(
                width: 50,
                height: 50,
                image:
                    '${Get.find<SplashController>().config!.imageBaseUrl!.profileImage}/${Get.find<ProfileController>().driverImage}',
              ),
            ),
          ),
          const Spacer(),
          // Animated UI for pending or accepted state
          if (Get.find<RideController>().tripDetail != null &&
              Get.find<RideController>().tripDetail!.currentStatus ==
                  'accepted')
            _buildAnimatedRiderButton(context),
          // Original navigation button
          if (Get.find<RideController>().tripDetail != null)
            InkWell(
              onTap: () async {
                final rideController = Get.find<RideController>();
                final trip = rideController.tripDetail!;

                double lat, lng;

                if (trip.currentStatus == 'accepted' ||
                    trip.currentStatus == 'pending') {
                  lat = trip.pickupCoordinates!.coordinates![1];
                  lng = trip.pickupCoordinates!.coordinates![0];
                } else {
                  lat = trip.destinationCoordinates!.coordinates![1];
                  lng = trip.destinationCoordinates!.coordinates![0];
                }

                final String googleMapsAndroidUrl =
                    "google.navigation:q=$lat,$lng&key=${AppConstants.polylineMapKey}";
                final String googleMapsIOSUrl =
                    "comgooglemaps://?daddr=$lat,$lng&directionsmode=driving";
                final String googleMapsWebUrl =
                    "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving";
                final String appleMapsUrl =
                    "http://maps.apple.com/?daddr=$lat,$lng";

                try {
                  if (Platform.isIOS) {
                    // جرب Google Maps أولاً
                    if (await canLaunchUrl(Uri.parse(googleMapsIOSUrl))) {
                      await launchUrl(Uri.parse(googleMapsIOSUrl));
                    } else {
                      // إذا لم يكن Google Maps متسطب، افتح Google Maps في المتصفح
                      if (await canLaunchUrl(Uri.parse(googleMapsWebUrl))) {
                        await launchUrl(
                          Uri.parse(googleMapsWebUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        // fallback على Apple Maps
                        await launchUrl(Uri.parse(appleMapsUrl));
                      }
                    }
                  } else {
                    // Android - جرب Google Maps أولاً
                    if (await canLaunchUrl(Uri.parse(googleMapsAndroidUrl))) {
                      await launchUrl(Uri.parse(googleMapsAndroidUrl));
                    } else {
                      // إذا لم يكن Google Maps متسطب، افتح Google Maps في المتصفح
                      await launchUrl(
                        Uri.parse(googleMapsWebUrl),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  }
                } catch (e) {
                  // في حالة حدوث خطأ، جرب فتح Apple Maps على iOS أو Google Maps في المتصفح
                  try {
                    if (Platform.isIOS) {
                      await launchUrl(Uri.parse(appleMapsUrl));
                    } else {
                      await launchUrl(
                        Uri.parse(googleMapsWebUrl),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  } catch (fallbackError) {
                    // إذا فشل كل شيء، اعرض رسالة للمستخدم
                    Get.snackbar(
                      'خطأ',
                      'لا يمكن فتح الخرائط. تأكد من تثبيت Google Maps أو Apple Maps.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                      BorderRadius.circular(Dimensions.paddingSizeExtraLarge),
                  boxShadow: [
                    BoxShadow(
                        color: Theme.of(context).hintColor.withOpacity(.25),
                        blurRadius: 1,
                        spreadRadius: 1,
                        offset: const Offset(0, 1))
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: SizedBox(
                    width: Dimensions.iconSizeMedium,
                    height: Dimensions.iconSizeMedium,
                    child: Image.asset(Images.navigation,
                        color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildAnimatedRiderButton(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1200),
                  builder: (context, iconValue, child) {
                    return Transform.rotate(
                      angle: iconValue * 0.1,
                      child: Icon(
                        Icons.person_pin_circle,
                        color: Colors.white,
                        size: 20 + (5 * iconValue),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Text with animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, textValue, child) {
                    return Opacity(
                      opacity: textValue,
                      child: Text(
                        'go_to_your_destination'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Pulsing arrow with simple animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, arrowValue, child) {
                    return Transform.translate(
                      offset: Offset(arrowValue * 2, 0),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color:
                            Colors.white.withOpacity(0.8 + (0.2 * arrowValue)),
                        size: 16,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
