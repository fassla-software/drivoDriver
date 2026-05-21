import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../controllers/simple_trip_otp_controller.dart';

class ImprovedTripOtpWidget extends StatelessWidget {
  final String carpoolTripId;
  final String passengerName;
  final Function(String message, Color backgroundColor,
      {IconData icon, Duration duration})? onShowSnackBar;
  final VoidCallback? onCloseDialog;
  final SimpleTripOtpController controller;

  const ImprovedTripOtpWidget({
    super.key,
    required this.carpoolTripId,
    required this.passengerName,
    this.onShowSnackBar,
    required this.controller,
    this.onCloseDialog,
  });

  @override
  Widget build(BuildContext context) {
    controller.onShowSnackBar = onShowSnackBar;
    controller.onCloseDialog = onCloseDialog;
    final isDark = Get.isDarkMode;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    final disabledColor = Theme.of(context).disabledColor;

    // Set callbacks for the controller

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Premium Lock Icon Indicator
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.15),
                  primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[900] : Colors.white,
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  color: primaryColor,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          // Title
          Text(
            'enter_trip_otp'.tr,
            style: textBold.copyWith(
              fontSize: Dimensions.fontSizeExtraLarge,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            child: Text(
              '${'collect_the_otp_from_customer'.tr} ($passengerName)',
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          // Pin input & Verification Section
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.15) : Colors.grey[50],
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeSmall,
                        ),
                        child: PinCodeTextField(
                          length: 4,
                          appContext: context,
                          obscureText: false,
                          showCursor: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          animationType: AnimationType.scale,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.underline,
                            fieldHeight: 45,
                            fieldWidth: 40,
                            borderWidth: 2.5,
                            activeColor: primaryColor,
                            selectedColor: primaryColor,
                            inactiveColor: disabledColor.withOpacity(0.4),
                            selectedFillColor: Colors.transparent,
                            inactiveFillColor: Colors.transparent,
                            activeFillColor: Colors.transparent,
                          ),
                          animationDuration: const Duration(milliseconds: 250),
                          backgroundColor: Colors.transparent,
                          enableActiveFill: false,
                          textStyle: textBold.copyWith(
                            fontSize: Dimensions.fontSizeOverLarge,
                            color: primaryColor,
                          ),
                          onChanged: controller.updateVerificationCode,
                          beforeTextPaste: (text) => true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          // Action Buttons Row
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault),
            child: Row(
              children: [
                // Cancel Button
                Expanded(
                  flex: 4,
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final close = onCloseDialog;
                      if (close != null) {
                        close();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusDefault),
                        side: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      'cancel'.tr,
                      style: textMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                // Verify Button
                Expanded(
                  flex: 6,
                  child: ElevatedButton(
                    onPressed: controller.isPinVerificationLoading
                        ? null
                        : () async {
                            HapticFeedback.mediumImpact();
                            if (controller.verificationCode.length == 4) {
                              await controller.matchOtp(
                                carpoolTripId,
                                controller.verificationCode,
                              );
                            } else {
                              final snack = onShowSnackBar;
                              if (snack != null) {
                                snack(
                                  "Pin code is required",
                                  Colors.orange,
                                  icon: Icons.warning_rounded,
                                );
                              } else {
                                Get.snackbar(
                                  'warning'.tr,
                                  'Pin code is required',
                                  backgroundColor: Colors.orange,
                                  colorText: Colors.white,
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: primaryColor.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                      elevation: 2,
                    ),
                    child: controller.isPinVerificationLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: Dimensions.fontSizeLarge,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'verify'.tr,
                                style: textBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],
      ),
    );
  }
}
