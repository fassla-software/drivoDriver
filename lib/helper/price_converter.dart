import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';

class PriceConverter {
  static String convertPrice(BuildContext context, double price,
      {double? discount, String? discountType}) {
    bool inRight =
        Get.find<SplashController>().config!.currencySymbolPosition == 'right';
    String decimal =
        Get.find<SplashController>().config!.currencyDecimalPoint ?? '1';
    String symbol = Get.find<SplashController>().config!.currencySymbol ?? '\$';
    String finalResult;
    if (discount != null && discountType != null) {
      if (discountType == 'amount') {
        price = price - discount;
      } else if (discountType == 'percent') {
        price = price - ((discount / 100) * price);
      }
    }
    if (inRight) {
      finalResult =
          '${(price).toStringAsFixed(int.parse(decimal)).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} $symbol';
    } else {
      finalResult =
          '$symbol${(price).toStringAsFixed(int.parse(decimal)).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
    return finalResult;
  }

  /// Converts a distance value (in km) to a properly formatted string.
  /// - If distance >= 1 km, shows "X.X km" (1 decimal place)
  /// - If distance < 1 km, shows "XXX m" (whole meters)
  /// - Handles null and zero values gracefully
  static String convertDistance(double? distanceInKm) {
    if (distanceInKm == null) return '0 m';
    if (distanceInKm <= 0) return '0 m';

    if (distanceInKm >= 1) {
      // Show in km with 1 decimal place
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      // Convert to meters and show as whole number
      int meters = (distanceInKm * 1000).round();
      return '$meters m';
    }
  }

  static double convertWithDiscount(BuildContext context, double price,
      double discount, String discountType) {
    if (discountType == 'amount') {
      price = price - discount;
    } else if (discountType == 'percent') {
      price = price - ((discount / 100) * price);
    }
    return price;
  }

  static double calculation(
      double amount, double discount, String type, int quantity) {
    double calculatedAmount = 0;
    if (type == 'amount') {
      calculatedAmount = discount * quantity;
    } else if (type == 'percent') {
      calculatedAmount = (discount / 100) * (amount * quantity);
    }
    return calculatedAmount;
  }

  static String percentageCalculation(BuildContext context, String price,
      String discount, String discountType) {
    return '$discount${discountType == 'percent' ? '%' : '\$'} OFF';
  }
}
