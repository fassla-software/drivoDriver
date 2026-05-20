import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/localization/language_model.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/setting/controllers/setting_controller.dart';
import 'package:ride_sharing_user_app/features/setting/widgets/theme_change_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'setting'.tr, regularAppbar: true),
      body: GetBuilder<SettingController>(
        builder: (settingController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                  vertical: Dimensions.paddingSize,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    /// Language Title
                    Row(
                      children: [
                        Image.asset(
                          Images.languageIcon,
                          scale: 2,
                          color: Theme.of(context).primaryColor,
                        ),

                        const SizedBox(
                          width: Dimensions.paddingSizeLarge,
                        ),

                        Text(
                          'language'.tr,
                          style: textRegular.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                          ),
                        ),
                      ],
                    ),

                    /// Dropdown
                    GetBuilder<LocalizationController>(
                      builder: (localizationController) {

                        return DropdownButton<String>(
                          isDense: true,

                          style: textMedium.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),

                          value:
                              '${localizationController.locale.languageCode}_${localizationController.locale.countryCode}',

                          underline: const SizedBox(),

                          icon: const Icon(
                            Icons.keyboard_arrow_down_sharp,
                          ),

                          elevation: 1,

                          selectedItemBuilder: (context) {
                            return AppConstants.languages
                                .map<Widget>((LanguageModel language) {

                              return Center(
                                child: Text(
                                  language.languageName,

                                  style: textRegular.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .color,
                                  ),
                                ),
                              );
                            }).toList();
                          },

                          items: AppConstants.languages
                              .map((LanguageModel language) {

                            final value =
                                '${language.languageCode}_${language.countryCode}';

                            return DropdownMenuItem<String>(
                              value: value,

                              child: Text(
                                language.languageName.tr,

                                style: textRegular.copyWith(
                                  color: localizationController
                                              .locale
                                              .languageCode ==
                                          language.languageCode
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .color,
                                ),
                              ),
                            );
                          }).toList(),

                          onChanged: (String? newValue) {

                            if (newValue != null) {

                              final parts = newValue.split('_');

                              Get.find<LocalizationController>()
                                  .setLanguage(
                                Locale(parts[0], parts[1]),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Padding(
              //   padding: const EdgeInsets.all(
              //     Dimensions.paddingSizeDefault,
              //   ),
              //
              //   child: Row(
              //     children: [
              //
              //       SizedBox(
              //         width: Dimensions.iconSizeMedium,
              //
              //         child: Image.asset(
              //           Images.themeIcon,
              //           color: Theme.of(context).primaryColor,
              //         ),
              //       ),
              //
              //       SizedBox(
              //         width: Get.find<LocalizationController>().isLtr
              //             ? 0
              //             : Dimensions.paddingSizeSmall,
              //       ),
              //
              //       Padding(
              //         padding: const EdgeInsets.only(
              //           left: Dimensions.paddingSizeSmall,
              //         ),
              //
              //         child: Text('theme'.tr),
              //       ),
              //     ],
              //   ),
              // ),

              // const ThemeChangeWidget(),
            ],
          );
        },
      ),
    );
  }
}