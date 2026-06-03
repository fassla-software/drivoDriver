import 'simple_passenger_model.dart';
import 'passenger_coordinate_model.dart';

class RepeatedDateModel {
  String? date;
  bool? isCancelled;

  RepeatedDateModel({this.date, this.isCancelled});

  factory RepeatedDateModel.fromJson(Map<String, dynamic> json) {
    return RepeatedDateModel(
      date: json['date']?.toString(),
      isCancelled: json['is_cancelled'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'is_cancelled': isCancelled,
    };
  }
}

class SimpleTripModel {
  int? id;
  String? name;
  String? profileImage;
  int? seats;
  bool? isSmokingAllowed;
  bool? isAc;
  String? allowedGender;
  int? allowedAgeMin;
  int? allowedAgeMax;
  bool? hasScreenEntertainment;
  bool? hasMusic;
  bool? allowLuggage;
  bool? isCancelled;
  String? startDay;
  String? startHour;
  String? startAddress;
  List<double>? startCoordinates;
  String? startTime;
  String? endTime;
  List<double>? endCoordinates;
  double? price;
  int? availableSeats;
  String? startMeridiem;
  String? endMeridiem;
  String? endAddress;
  int? isTripStarted;
  String? vehicleName;
  int? passengersCount;
  String? encodedPolyline;
  String? tripType;
  String? carpoolType;
  String? serverTripStatus;
  bool? hasReturnLeg;
  String? effectiveTripLeg;
  bool? canStartOutbound;
  bool? canStartReturn;
  String? departureTime;
  String? returnTime;
  List<RepeatedDateModel>? tripDates;
  List<PassengerCoordinateModel>? passengerCoordinates;
  List<SimplePassengerModel>? passengers;

  // bool? isOtpNotVerified = true;

  SimpleTripModel({
    this.id,
    this.name,
    this.profileImage,
    this.seats,
    this.isSmokingAllowed,
    this.isAc,
    this.allowedGender,
    this.allowedAgeMin,
    // this.isOtpNotVerified,
    this.allowedAgeMax,
    this.hasScreenEntertainment,
    this.hasMusic,
    this.allowLuggage,
    this.startDay,
    this.startHour,
    this.startAddress,
    this.startCoordinates,
    this.startTime,
    this.endTime,
    this.endCoordinates,
    this.price,
    this.availableSeats,
    this.startMeridiem,
    this.endMeridiem,
    this.endAddress,
    this.isTripStarted,
    this.vehicleName,
    this.passengersCount,
    this.encodedPolyline,
    this.tripType,
    this.carpoolType,
    this.serverTripStatus,
    this.hasReturnLeg,
    this.effectiveTripLeg,
    this.canStartOutbound,
    this.canStartReturn,
    this.departureTime,
    this.returnTime,
    this.isCancelled,
    this.tripDates,
    this.passengerCoordinates,
    this.passengers,
  });

  factory SimpleTripModel.fromJson(Map<String, dynamic> json) {
    return SimpleTripModel(
      id: json['id'],
      name: json['name']?.toString(),
      profileImage: json['profile_image']?.toString(),
      // isOtpNotVerified: json['is_otp_not_verified'] == 1 ||
      //     json['is_otp_not_verified'] == true ||
      //     json['is_otp_not_verified'] == null,
      seats: json['seats'],
      isSmokingAllowed: json['is_smoking_allowed'],
      isAc: json['is_ac'],
      isCancelled: json['is_cancelled'],

      allowedGender: json['allowed_gender']?.toString(),
      allowedAgeMin: json['allowed_age_min'],
      allowedAgeMax: json['allowed_age_max'],

      hasScreenEntertainment: json['has_screen_entertainment'],
      hasMusic: json['has_music'],
      allowLuggage: json['allow_luggage'],

      startDay: json['start_day']?.toString(),
      startHour: json['start_hour']?.toString(),
      startAddress: json['start_address']?.toString(),

      tripType: json['recurrence_type']?.toString(),
      carpoolType: (json['carpool_type'] ?? json['type'])?.toString(),
      // serverTripStatus: json['trip_status']?.toString(),
      hasReturnLeg:
          json['has_return_leg'] == 1 || json['has_return_leg'] == true,
      effectiveTripLeg: json['effective_trip_leg']?.toString(),
      canStartOutbound:
          json['can_start_outbound'] == 1 || json['can_start_outbound'] == true,
      canStartReturn:
          json['can_start_return'] == 1 || json['can_start_return'] == true,
      departureTime: json['departure_time']?.toString(),
      returnTime: json['return_time']?.toString(),

      tripDates: json['repeated_dates'] != null
          ? (json['repeated_dates'] as List)
              .map((item) => RepeatedDateModel.fromJson(item))
              .toList()
          : null,

      startCoordinates: json['start_coordinates'] != null
          ? List<double>.from(json['start_coordinates'])
          : null,

      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),

      endCoordinates: json['end_coordinates'] != null
          ? List<double>.from(json['end_coordinates'])
          : null,

      price: json['price']?.toDouble(),
      availableSeats: json['available_seats'],

      startMeridiem: json['start_meridiem']?.toString(),
      endMeridiem: json['end_meridiem']?.toString(),

      endAddress: json['end_address']?.toString(),

      isTripStarted: json['is_trip_started'],

      vehicleName: json['vehicle_name']?.toString(),
      passengersCount: json['passengers_count'],

      encodedPolyline: json['encoded_polyline']?.toString(),

      // ❌ تجاهل passenger_coordinates من السيرفر لأنه فاضي
      // ✅ نبنيه من passengers
      passengerCoordinates: json['passengers'] != null
          ? (json['passengers'] as List).expand((p) {
              List<PassengerCoordinateModel> result = [];

              // pickup
              if (p['closest_pickup_point'] != null) {
                result.add(
                  PassengerCoordinateModel.fromJson({
                    'type': 'pickup',
                    'passenger_id': p['carpool_trip_id'],
                    'closest_pickup_point': p['closest_pickup_point'],
                    'pickup_coordinates': p['start_coordinates'] != null
                        ? [
                            p['start_coordinates']['lat'],
                            p['start_coordinates']['lng']
                          ]
                        : null,
                    'address': p['pickup_address'],
                  }),
                );
              }

              // dropoff
              if (p['end_coordinates'] != null) {
                result.add(
                  PassengerCoordinateModel.fromJson({
                    'type': 'dropoff',
                    'passenger_id': p['carpool_trip_id'],
                    'dropoff_coordinates': [
                      p['end_coordinates']['lat'],
                      p['end_coordinates']['lng']
                    ],
                    'address': p['dropoff_address'],
                  }),
                );
              }

              return result;
            }).toList()
          : [],

      passengers: json['passengers'] != null
          ? (json['passengers'] as List)
              .map((item) => SimplePassengerModel.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profile_image': profileImage,
      'seats': seats,
      'is_smoking_allowed': isSmokingAllowed,
      'is_ac': isAc,
      'allowed_gender': allowedGender,
      'allowed_age_min': allowedAgeMin,
      'allowed_age_max': allowedAgeMax,
      'has_screen_entertainment': hasScreenEntertainment,
      'has_music': hasMusic,
      'allow_luggage': allowLuggage,
      'start_day': startDay,
      'start_hour': startHour,
      'start_address': startAddress,
      'start_coordinates': startCoordinates,
      'start_time': startTime,
      'end_time': endTime,
      'end_coordinates': endCoordinates,
      'price': price,
      'available_seats': availableSeats,
      'start_meridiem': startMeridiem,
      'end_meridiem': endMeridiem,
      'end_address': endAddress,
      'is_trip_started': isTripStarted,
      'vehicle_name': vehicleName,
      'passengers_count': passengersCount,
      'encoded_polyline': encodedPolyline,
      'recurrence_type': tripType,
      'carpool_type': carpoolType,
      'trip_status': serverTripStatus,
      'has_return_leg': hasReturnLeg,
      'effective_trip_leg': effectiveTripLeg,
      'can_start_outbound': canStartOutbound,
      'can_start_return': canStartReturn,
      'departure_time': departureTime,
      'return_time': returnTime,
      'repeated_dates': tripDates?.map((e) => e.toJson()).toList(),
      'passengers': passengers?.map((e) => e.toJson()).toList(),
    };
  }

  String get tripStatus {
    if (serverTripStatus != null && serverTripStatus!.isNotEmpty) {
      return serverTripStatus!;
    }
    if (isCancelled == true) {
      return 'cancelled';
    }
    final sTime = startTime;
    final eTime = endTime;
    if (sTime != null &&
        (eTime == null || eTime.isEmpty) &&
        (isTripStarted == 0 || isTripStarted == null)) {
      return 'pending';
    } else if (sTime != null &&
        (eTime == null || eTime.isEmpty) &&
        isTripStarted == 1) {
      return 'ongoing';
    } else if (sTime != null && eTime != null && eTime.isNotEmpty) {
      return 'completed';
    }
    return 'unknown';
  }

  bool get hasPassengers => (passengersCount ?? 0) > 0;

  String get formattedStartTime {
    final sTime = startTime;
    if (sTime != null && sTime.isNotEmpty) {
      return sTime;
    }
    return 'N/A';
  }

  String get formattedStartDate {
    final sDay = startDay;
    if (sDay != null && sDay.isNotEmpty) {
      return sDay;
    }
    return 'N/A';
  }

  String get formattedPrice {
    return '${price?.toStringAsFixed(2) ?? '0'} EGP';
  }

  List<String> get features {
    List<String> features = [];
    if (isAc == true) features.add('AC');
    if (hasMusic == true) features.add('Music');
    if (hasScreenEntertainment == true) features.add('Entertainment');
    if (allowLuggage == true) features.add('Luggage');
    if (isSmokingAllowed == true) features.add('Smoking');
    return features;
  }
}

class SimpleTripsResponseModel {
  String? responseCode;
  String? message;
  int? totalSize;
  String? limit;
  String? offset;
  List<SimpleTripModel>? data;
  List<dynamic>? errors;

  SimpleTripsResponseModel({
    this.responseCode,
    this.message,
    this.totalSize,
    this.limit,
    this.offset,
    this.data,
    this.errors,
  });

  factory SimpleTripsResponseModel.fromJson(Map<String, dynamic> json) {
    return SimpleTripsResponseModel(
      responseCode: json['response_code'],
      message: json['message'],
      totalSize: json['total_size'],
      limit: json['limit']?.toString(),
      offset: json['offset']?.toString(),
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => SimpleTripModel.fromJson(item))
              .toList()
          : null,
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'response_code': responseCode,
      'message': message,
      'total_size': totalSize,
      'limit': limit,
      'offset': offset,
      'data': data?.map((item) => item.toJson()).toList(),
      'errors': errors,
    };
  }
}
