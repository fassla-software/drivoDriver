import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/chat/controllers/chat_controller.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/models/simple_passenger_model.dart';

class PassengerRouteInfoWidget extends StatelessWidget {
  final SimplePassengerModel passenger;
  final String tripId;

  const PassengerRouteInfoWidget({
    super.key,
    required this.passenger,
    required this.tripId,
  });

  void _callUser(String? phone) async {
    if (phone == null || phone.isEmpty) return;

    final uri = Uri.parse("tel:$phone");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        "Error",
        "Cannot open dialer",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _openChat() {
    final ChatController controller = Get.find<ChatController>();

    debugPrint("PASSENGER DATA: ${passenger.toJson()}");
    debugPrint("PASSENGER ID: ${passenger.id}");
    debugPrint("TRIP ID: $tripId");

    // 🔥 fallback ثابت مؤقت

    String userId = passenger.id.toString();

    controller.createChannel(
      userId,
      tripId: tripId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        /// CALL
        InkWell(
          onTap: () => _callUser(passenger.phone),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call, color: Colors.white, size: 18),
          ),
        ),

        const SizedBox(width: 10),

        /// CHAT
        InkWell(
          onTap: () {

            Get.find<ChatController>().createChannel(
              passenger.id.toString(),
              tripId: tripId,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}
