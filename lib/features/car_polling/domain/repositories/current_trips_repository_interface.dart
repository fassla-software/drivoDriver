import 'package:get/get_connect/http/src/response/response.dart';
import '../../../../interface/repository_interface.dart';

abstract class CurrentTripsRepositoryInterface implements RepositoryInterface {
  Future<Response> getCurrentTripsWithPassengers();
  Future<Response> startTrip(int carpoolRouteId);
  Future<Response> endTrip(int carpoolRouteId);
  Future<Response> cancelTrip(int carpoolRouteId,
      {String? cancellationType, String? date, String? reason});
}
