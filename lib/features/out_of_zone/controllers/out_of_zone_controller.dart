import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/data/api_checker.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/out_of_zone/domain/models/zone_list_model.dart';
import 'package:ride_sharing_user_app/features/out_of_zone/domain/service/out_of_zone_service_interface.dart';
import 'package:ride_sharing_user_app/features/out_of_zone/widgets/out_of_zone_bottoms_sheet_widget.dart';
import 'package:ride_sharing_user_app/helper/map_helper.dart';

class OutOfZoneController extends GetxController implements GetxService {
  final OutOfZoneServiceInterface outOfZoneServiceInterface;
  OutOfZoneController({required this.outOfZoneServiceInterface});

  ZoneListModel? zoneListModel;
  Position location = Position(
    longitude: 0,
    latitude: 0,
    timestamp: DateTime.now(),
    accuracy: 1,
    altitude: 1,
    heading: 1,
    speed: 1,
    speedAccuracy: 1,
    altitudeAccuracy: 1,
    headingAccuracy: 1,
  );
  bool isDriverOutOfZone = false;
  List<List<LatLngPoint>> polygones = [];
  List<LatLngPoint> nearestZone = [];
  List<LatLngPoint> currentZone = [];
  Timer? _timer;
  bool _isShowDialog = true;

  void updateShowDialog(bool action) {
    _isShowDialog = action;
  }

  void getZoneList() async {
    Response response = await outOfZoneServiceInterface.getZoneList();
    if (response.statusCode == 200) {
      polygones = [];
      zoneListModel = ZoneListModel.fromJson(response.body);
      for (var v in zoneListModel!.data!) {
        polygones.add(v.zoneCoordinates!.coordinatesPoint!);
      }
      findDriverCurrentZone();
    } else {
      ApiChecker.checkApi(response);
    }
  }

  Future<bool> getDriverCurrentPosition() async {
    try {
      Position newLocation = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5),
        desiredAccuracy: LocationAccuracy.high,
      );
      location = newLocation;
      return true;
    } catch (e) {
      try {
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          location = lastKnown;
          return true;
        }
      } catch (_) {}
      if (Get.isRegistered<LocationController>()) {
        location = Get.find<LocationController>().position;
        return true;
      }
      return false;
    }
  }

  Future<void> findDriverCurrentZone() async {
    bool gotPosition = await getDriverCurrentPosition();
    if (!gotPosition) {
      isDriverOutOfZone = false;
      return;
    }
    for (int i = 0; i < polygones.length; i++) {
      if (MapHelper.isPointInPolygon(
          LatLngPoint(location.latitude, location.longitude), polygones[i])) {
        currentZone = polygones[i];
        isDriverOutOfZone = false;
        break;
      } else {
        isDriverOutOfZone = true;
      }
    }
    if (polygones.isNotEmpty) {
      outOfZoneOnListener();
    }
  }

  void outOfZoneOnListener() {
    bool isBottomSheetOpen = false;
    nearestZone = MapHelper.findNearestPolygon(
        LatLngPoint(location.latitude, location.longitude), polygones);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      bool gotPosition = await getDriverCurrentPosition();
      if (!gotPosition) {
        return;
      }
      if (!MapHelper.isPointInPolygon(
          LatLngPoint(location.latitude, location.longitude), currentZone)) {
        nearestZone = MapHelper.findNearestPolygon(
            LatLngPoint(location.latitude, location.longitude), polygones);
        if (MapHelper.isPointInPolygon(
            LatLngPoint(location.latitude, location.longitude), nearestZone)) {
          currentZone = nearestZone;
          isDriverOutOfZone = false;
          if (Get.isBottomSheetOpen! && isBottomSheetOpen) {
            isBottomSheetOpen = false;
            if (Get.currentRoute != '/OutOfZoneMapView') {
              Get.back();
            }
            Get.back();
          }
        } else {
          isDriverOutOfZone = true;
          if (!Get.isBottomSheetOpen! &&
              (Get.currentRoute != '/OutOfZoneMapView') &&
              _isShowDialog) {
            isBottomSheetOpen = true;
            await Get.bottomSheet(const OutOfZoneBottomSheetWidget());
            isBottomSheetOpen = false;
          }
        }
      } else {
        if (Get.isBottomSheetOpen! && isBottomSheetOpen) {
          isBottomSheetOpen = false;
          Get.back();
        }
      }
    });
  }
}
