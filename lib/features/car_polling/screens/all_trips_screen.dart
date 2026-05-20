import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';

import '../../../common_widgets/app_bar_widget.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import 'simple_trips_screen.dart';
import 'register_route_screen.dart';

class AllTripsScreen extends StatelessWidget {
  const AllTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBarWidget(
        title: 'Welcome to Carpooling'.tr,
        showBackButton: true,
      ),
      body: GetBuilder<ProfileController>(
        builder: (profileController) {
          bool isActivated =
              profileController.profileInfo?.isCarpoolActivated ?? false;

          return RefreshIndicator(
            onRefresh: () async {
              await profileController.getProfileInfo();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: isActivated
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(
                              Dimensions.paddingSizeLarge),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              /// 🔹 My Trips
                              Text(
                                'My Trips'.tr,
                                style: textMedium.copyWith(
                                  fontSize: Dimensions.fontSizeLarge,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),

                              /// ⭐ Highlight Card (clean + alive)
                              InkWell(
                                onTap: () {
                                  Get.to(() =>
                                      const SimpleTripsScreen());
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey.shade900
                                        : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                      color:Colors.blueAccent.withOpacity(0.15),

                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(
                                            isDark ? 0.25 : 0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [

                                      Container(
                                        padding:
                                            const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.blueAccent.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.my_location,
                                          color: Colors.blueAccent,
                                          size: 24,
                                        ),
                                      ),

                                      const SizedBox(width: 15),

                                      Expanded(
                                        child: Text(
                                          'View My Current Trips'.tr,
                                          style: textMedium.copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Theme.of(context)
                                            .hintColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 25),

                            /// 🔹 Create Trip
Text(
  'Create Trip'.tr,
  style: textMedium.copyWith(
    fontSize: Dimensions.fontSizeLarge,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 10),

/// 🔹 Vertical Cards
Column(
  children: [

    _buildTripCard(
      context,
      title: 'One Trip'.tr,
      icon: Icons.trip_origin,
      color: Colors.blue,
      onTap: () {
        Get.to(() =>
            const RegisterRouteScreen(
                type: 'trip'));
      },
    ),

    const SizedBox(height: 14),

    _buildTripCard(
      context,
      title: 'Travel'.tr,
      icon: Icons.luggage,
      color: Colors.green,
      onTap: () {
        Get.to(() =>
            const RegisterRouteScreen(
                type: 'travel'));
      },
    ),

    const SizedBox(height: 14),

    _buildTripCard(
      context,
      title: 'Routine'.tr,
      icon: Icons.repeat,
      color: Colors.blue,
      onTap: () {
        Get.to(() =>
            const RegisterRouteScreen(
                type: 'routine'));
      },
    ),

    const SizedBox(height: 14),

    _buildTripCard(
      context,
      title: 'North Coast'.tr,
      icon: Icons.beach_access,
      color: Colors.green,
      onTap: () {
        Get.to(() =>
            const RegisterRouteScreen(
                type: 'north_coast'));
      },
    ),
  ],
),
                            ],
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.block,
                                  size: 50,
                                  color: Theme.of(context)
                                      .disabledColor),
                              const SizedBox(height: 10),
                              Text(
                                'not_activated'.tr,
                                style: textMedium.copyWith(
                                  fontSize:
                                      Dimensions.fontSizeLarge,
                                  color: Theme.of(context)
                                      .disabledColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔹 Clean Card (Best balance)
 Widget _buildTripCard(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),

    child: Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: color.withOpacity(0.15),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Row(
          children: [

            Container(
              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                title,

                style: textMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).hintColor,
            ),
          ],
        ),
      ),
    ),
  );
}
}