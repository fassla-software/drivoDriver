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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBarWidget(
        title: 'All Trips',
        showBackButton: true,
      ),
      body: GetBuilder<ProfileController>(builder: (profileController) {
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
                    ? Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(Dimensions.paddingSizeLarge),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // My Current Trips Button
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Get.to(() => const SimpleTripsScreen());
                                  },
                                  icon: const Icon(Icons.my_location, size: 20),
                                  label: Text(
                                    'My Current Trips',
                                    style: textMedium.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: Dimensions.paddingSizeDefault,
                                      horizontal: Dimensions.paddingSizeSmall,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          Dimensions.paddingSizeSmall),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                  width: Dimensions.paddingSizeDefault),
                              // Register Route Button
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Get.to(() => const RegisterRouteScreen());
                                  },
                                  icon: const Icon(Icons.add_road, size: 20),
                                  label: Text(
                                    'Register Route',
                                    style: textMedium.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.secondary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: Dimensions.paddingSizeDefault,
                                      horizontal: Dimensions.paddingSizeSmall,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          Dimensions.paddingSizeSmall),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.block,
                                size: 50,
                                color: Theme.of(context).disabledColor),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            Text(
                              'not_activated'.tr,
                              textAlign: TextAlign.center,
                              style: textMedium.copyWith(
                                fontSize: Dimensions.fontSizeLarge,
                                color: Theme.of(context).disabledColor,
                              ),
                            ),
                          ],
                        ),
                      ),
              )
            ],
          ),
        );
      }),
    );
  }
}
