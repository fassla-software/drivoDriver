class RemainingDistanceModel {
  double? distance;
  String? distanceText;
  String? duration;
  int? durationSec;
  String? status;
  String? driveMode;
  String? encodedPolyline;
  bool? isPicked;
  bool? isDrop;

  RemainingDistanceModel(
      {this.distance,
      this.distanceText,
      this.duration,
      this.durationSec,
      this.status,
      this.driveMode,
      this.encodedPolyline,
      this.isPicked,
      this.isDrop});

  RemainingDistanceModel.fromJson(Map<String, dynamic> json) {
    if (json['distance'] != null) {
      try {
        distance = json['distance'].toDouble();
      } catch (e) {
        distance = double.parse(json['distance'].toString());
      }
    }

    distanceText = json['distance_text'];
    duration = json['duration'];
    // distance = json['distance'];
    durationSec = json['duration_sec'];
    status = json['status'];
    driveMode = json['drive_mode'];
    encodedPolyline = json['encoded_polyline'];
    isPicked = json['is_picked'];
    isDrop = json['is_dropped'];
  }
}

final RemainingDistanceModel fakeModel = RemainingDistanceModel(
  distance: 12.5,
  distanceText: "12.5 km",
  duration: "15 mins",
  durationSec: 900,
  status: "on_route",
  driveMode: "car",
  encodedPolyline: "abcd1234efgh5678",
  isPicked: true,
  isDrop: false,
);
