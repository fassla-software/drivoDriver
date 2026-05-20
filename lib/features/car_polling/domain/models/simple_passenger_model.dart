import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SimplePassengerModel {
  int? id;
  String? name;
  String? profileImage;
  int? seatsCount;
  double? price;
  double? fare;
  String? status;
  String? pickupAddress;
  String? dropoffAddress;
  List<double>? pickupCoordinates;
  List<double>? closestPickupPoint;
  List<double>? dropoffCoordinates;

  String? phone;
  String? email;
  String? carpoolTripId;

  SimplePassengerModel({
    this.id,
    this.name,
    this.profileImage,
    this.seatsCount,
    this.price,
    this.closestPickupPoint,
    this.fare,
    this.status,
    this.pickupAddress,
    this.dropoffAddress,
    this.pickupCoordinates,
    this.dropoffCoordinates,
    this.phone,
    this.email,
    this.carpoolTripId,
  });

  factory SimplePassengerModel.fromJson(Map<String, dynamic> json) {
    print('=== SimplePassengerModel.fromJson: $json ===');
    return SimplePassengerModel(
      id: json['id'],
      price: json['price']?.toDouble(),
      name: json['name'],
      profileImage: json['profile_image'],
      seatsCount: json['seats_count'],
      fare: json['fare']?.toDouble(),
      status: json['status'],
      pickupAddress: json['pickup_address']?.toString() ??
          json['start_address']?.toString(),
      dropoffAddress: json['dropoff_address']?.toString() ??
          json['end_address']?.toString(),
      pickupCoordinates: json['pickup_coordinates'] != null
          ? List<double>.from(json['pickup_coordinates'])
          : null,
      closestPickupPoint: json['closest_pickup_point'] != null
          ? List<double>.from(json['closest_pickup_point'])
          : null,
      dropoffCoordinates: json['dropoff_coordinates'] != null
          ? List<double>.from(json['dropoff_coordinates'])
          : null,
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      carpoolTripId: json['carpool_trip_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profile_image': profileImage,
      'seats_count': seatsCount,
      'fare': fare,
      'price': price,
      'status': status,
      'pickup_address': pickupAddress,
      'dropoff_address': dropoffAddress,
      'pickup_coordinates': pickupCoordinates,
      'dropoff_coordinates': dropoffCoordinates,
      'phone': phone,
      'email': email,
      'carpool_trip_id': carpoolTripId,
    };
  }
String? get fullProfileImage {
  final img = profileImage;

  if (img == null || img.trim().isEmpty) return null;

  if (img.startsWith('http')) return img;

  return 'https://drivoeg.com/storage/app/public/customer/profile/$img';
}

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  /// Pickup text for UI — passenger address, then trip start, then placeholder.
  String displayPickupAddress(String? tripStartAddress) {
    return _firstNonEmpty([pickupAddress, tripStartAddress]) ??
        'location_not_available'.tr;
  }

  /// Dropoff text for UI — passenger address, then trip end, then placeholder.
  String displayDropoffAddress(String? tripEndAddress) {
    return _firstNonEmpty([dropoffAddress, tripEndAddress]) ??
        'location_not_available'.tr;
  }

  // Helper methods
String get formattedFare {
  final value = fare ?? price ?? 0;
  return '${value.toStringAsFixed(2)} EGP';
}

  String get statusDisplayText {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'pending'.tr;
      case 'accepted':
        return 'accepted'.tr;
      case 'picked_up':
        return 'picked_up'.tr;
      case 'dropped_off':
        return 'dropped_off'.tr;
      case 'cancelled':
        return 'cancelled'.tr;
      default:
        return 'unknown'.tr;
    }
  }

  Color get statusColor {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'picked_up':
        return Colors.blue;
      case 'dropped_off':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
