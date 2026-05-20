import 'rest_stop_model.dart';

class RegisterRouteRequestModel {
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final String startTime;
  final String rideType;
  final int? isAc;
  final int? isSmokingAllowed;
  final int seatsAvailable;
  final int? hasMusic;
  final String? allowedGender;
  final int? allowedAgeMin;
  final int? allowedAgeMax;
  final int? hasScreenEntertainment;
  final int? allowLuggage;
  final String? vehicleId;
  final double price;
  final List<RestStopModel>? restStops;
  final String? recurrenceType;
  final List<String>? selectedDates;

  // New fields for different carpool types
  final int? boardingPointStartId;
  final int? boardingPointEndId;
  final bool? isAcBool;
  final String? departureTime;
  final String? returnTime;

  RegisterRouteRequestModel({
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    required this.startTime,
    required this.rideType,
    this.isAc,
    this.isSmokingAllowed,
    required this.seatsAvailable,
    this.hasMusic,
    this.allowedGender,
    this.allowedAgeMin,
    this.allowedAgeMax,
    this.hasScreenEntertainment,
    this.allowLuggage,
    this.vehicleId,
    required this.price,
    this.restStops,
    this.recurrenceType = 'once',
    this.selectedDates,
    this.boardingPointStartId,
    this.boardingPointEndId,
    this.isAcBool,
    this.departureTime,
    this.returnTime,
  });

  Map<String, dynamic> toJson() {
    final String carpoolType = rideType == 'single' ? 'trip' : rideType;
    final Map<String, dynamic> data = {
      'carpool_type': carpoolType,
      'start_time': startTime,
      'price': price,
      'seats_available': seatsAvailable,
    };

    if (carpoolType == 'trip') {
      data['start_lat'] = startLat;
      data['start_lng'] = startLng;
      data['end_lat'] = endLat;
      data['end_lng'] = endLng;
      data['allowed_gender'] = allowedGender ?? 'both';
    } else if (carpoolType == 'travel') {
      data['boarding_point_start_id'] = boardingPointStartId;
      data['boarding_point_end_id'] = boardingPointEndId;
      data['is_ac'] = isAcBool ?? true;
      data['allowed_gender'] = allowedGender ?? 'both';
    } else if (carpoolType == 'routine') {
      data['start_lat'] = startLat;
      data['start_lng'] = startLng;
      data['end_lat'] = endLat;
      data['end_lng'] = endLng;
      data['departure_time'] = departureTime;
      data['return_time'] = returnTime;
    } else if (carpoolType == 'north_coast') {
      data['start_lat'] = startLat;
      data['start_lng'] = startLng;
      data['end_lat'] = endLat;
      data['end_lng'] = endLng;
    }

    return data;
  }
}
