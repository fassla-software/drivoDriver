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
  List<RepeatedDateModel>? tripDates;
  List<PassengerCoordinateModel>? passengerCoordinates;
  List<SimplePassengerModel>? passengers;

  SimpleTripModel({
    this.id,
    this.name,
    this.profileImage,
    this.seats,
    this.isSmokingAllowed,
    this.isAc,
    this.allowedGender,
    this.allowedAgeMin,
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
      // Debug passenger coordinates
      passengerCoordinates: (() {
        print(
            '=== Processing passenger_coordinates: ${json['passenger_coordinates']} ===');
        if (json['passenger_coordinates'] != null) {
          final list = json['passenger_coordinates'] as List;
          print('=== Passenger coordinates list length: ${list.length} ===');
          return (list
              .map((item) => PassengerCoordinateModel.fromJson(item))
              .toList());
        }
        return null;
      })(),
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
      'passenger_coordinates':
          passengerCoordinates?.map((item) => item.toJson()).toList(),
      'passengers': passengers?.map((item) => item.toJson()).toList(),
      'recurrence_type': tripType,
      'repeated_dates': tripDates?.map((item) => item.toJson()).toList(),
    };
  }

  // Helper methods
  String get tripStatus {
    if (isCancelled == true) {
      return 'cancelled';
    } else if (startTime != null &&
        (endTime == null || endTime!.isEmpty) &&
        (isTripStarted == 0 || isTripStarted == null)) {
      return 'pending';
    } else if (startTime != null &&
        (endTime == null || endTime!.isEmpty) &&
        isTripStarted == 1) {
      return 'ongoing';
    } else if (startTime != null && endTime != null && endTime!.isNotEmpty) {
      return 'completed';
    }
    return 'unknown';
  }

  bool get hasPassengers => (passengersCount ?? 0) > 0;

  String get formattedStartTime {
    if (startTime != null && startTime!.isNotEmpty) {
      return startTime!;
    }
    return 'N/A';
  }

  String get formattedStartDate {
    if (startDay != null && startDay!.isNotEmpty) {
      return startDay!;
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
