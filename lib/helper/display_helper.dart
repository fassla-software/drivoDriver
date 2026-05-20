import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/helper/responsive_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

void showCustomSnackBar(String message,
    {bool isError = true, int seconds = 3, String? subMessage}) {

  final context = Get.context;
  if (context == null) return;

  ScaffoldMessenger.of(context).clearSnackBars();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: Duration(seconds: seconds),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Colors.red : Colors.green,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          if (subMessage != null)
            Text(subMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    ),
  );
}