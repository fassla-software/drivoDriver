import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SimplePassengerModel {
  String? id;
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
      id: json['user_id']?.toString(),
      name: json['name']?.toString(),
      profileImage: json['profile_image']?.toString(),
      seatsCount: json['seats_count'] is int 
          ? json['seats_count'] 
          : int.tryParse(json['seats_count']?.toString() ?? ''),
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      fare: json['fare'] != null ? double.tryParse(json['fare'].toString()) : null,
      status: json['status']?.toString(),
      pickupAddress: json['pickup_address']?.toString() ?? json['start_address']?.toString(),
      dropoffAddress: json['dropoff_address']?.toString() ?? json['end_address']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      carpoolTripId: json['carpool_trip_id']?.toString() ?? json['passenger_id']?.toString(),
      
      // معالجة ذكية للإحداثيات تدعم الـ Map والـ List معاً منعاً للـ Crash
      pickupCoordinates: _parseCoordinates(json['pickup_coordinates'] ?? json['start_coordinates']),
      dropoffCoordinates: _parseCoordinates(json['dropoff_coordinates'] ?? json['end_coordinates']),
      closestPickupPoint: _parseCoordinates(json['closest_pickup_point']),
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

  /// دالة مساعدة خاصة للتعامل الآمن مع الإحداثيات وتجنب الـ Type Cast Error
  static List<double>? _parseCoordinates(dynamic jsonElement) {
    if (jsonElement == null) return null;
    try {
      // 1. إذا كانت قادمة كلستة مباشرة [lat, lng]
      if (jsonElement is List) {
        return jsonElement.map((e) => double.parse(e.toString())).toList();
      }
      // 2. إذا كانت قادمة كماب تحتوي على مفاتيح جغرافية {"lat": ..., "lng": ...}
      if (jsonElement is Map) {
        final lat = jsonElement['lat'] ?? jsonElement['latitude'];
        final lng = jsonElement['lng'] ?? jsonElement['longitude'];
        if (lat != null && lng != null) {
          return [double.parse(lat.toString()), double.parse(lng.toString())];
        }
      }
    } catch (e) {
      print('❌ Error parsing coordinates in SimplePassengerModel: $e');
    }
    return null;
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

  String displayPickupAddress(String? tripStartAddress) {
    return _firstNonEmpty([pickupAddress, tripStartAddress]) ?? 'location_not_available'.tr;
  }

  String displayDropoffAddress(String? tripEndAddress) {
    return _firstNonEmpty([dropoffAddress, tripEndAddress]) ?? 'location_not_available'.tr;
  }

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
      case 'ongoing': // إضافة حالة التشغيل المستمرة القادمة من الـ API لرحلة 488
        return 'picked_up'.tr;
      case 'dropped_off':
      case 'completed':
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
      case 'ongoing':
        return Colors.blue;
      case 'dropped_off':
      case 'completed':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}