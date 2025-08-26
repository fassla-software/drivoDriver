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
}
