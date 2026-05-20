import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/image_widget.dart';
import 'package:ride_sharing_user_app/features/home/controllers/banner_controller.dart';
import 'package:ride_sharing_user_app/features/home/widgets/banner_shimmer.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:url_launcher/url_launcher.dart';

class BannerView extends StatelessWidget {
  const BannerView({super.key});

  Future<void> _launchUrl(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch URL: $url - Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BannerController>(
      builder: (bannerController) {
        if (bannerController.isLoading) {
          return const BannerShimmer();
        }

        final banners = bannerController.bannerList;
        if (banners == null || banners.isEmpty) {
          return const SizedBox();
        }

        final String? baseUrl = Get.find<SplashController>().config?.imageBaseUrl?.banner;

        return Container(
          height: 150,
          width: Get.width,
          margin: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Swiper(
              itemCount: banners.length,
              autoplay: banners.length > 1,
              autoplayDelay: 4000,
              loop: banners.length > 1,
              onIndexChanged: (index) {
                bannerController.setCurrentIndex(index, true);
              },
              pagination: banners.length > 1
                  ? SwiperPagination(
                      margin: const EdgeInsets.only(bottom: 8),
                      builder: DotSwiperPaginationBuilder(
                        activeColor: Theme.of(context).primaryColor,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 6.0,
                        activeSize: 8.0,
                        space: 3.0,
                      ),
                    )
                  : null,
              itemBuilder: (context, index) {
                final banner = banners[index];
                final String imageUrl = '$baseUrl/${banner.image ?? ""}';

                return InkWell(
                  onTap: () {
                    if (banner.id != null) {
                      bannerController.updateBannerClickCount(banner.id!);
                    }
                    if (banner.redirectLink != null && banner.redirectLink!.isNotEmpty) {
                      _launchUrl(banner.redirectLink!);
                    }
                  },
                  child: ImageWidget(
                    image: imageUrl,
                    fit: BoxFit.cover,
                    width: Get.width,
                    height: 150,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
