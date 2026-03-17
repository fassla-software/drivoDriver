import '../repositories/current_trips_repository_interface.dart';
import 'current_trips_service_interface.dart';

class CurrentTripsService implements CurrentTripsServiceInterface {
  final CurrentTripsRepositoryInterface currentTripsRepositoryInterface;

  CurrentTripsService({required this.currentTripsRepositoryInterface});

  @override
  Future getCurrentTripsWithPassengers() {
    return currentTripsRepositoryInterface.getCurrentTripsWithPassengers();
  }

  @override
  Future startTrip(int carpoolRouteId) {
    return currentTripsRepositoryInterface.startTrip(carpoolRouteId);
  }

  @override
  Future endTrip(int carpoolRouteId) {
    return currentTripsRepositoryInterface.endTrip(carpoolRouteId);
  }

  @override
  Future cancelTrip(int carpoolRouteId,
      {String? cancellationType, String? date, String? reason}) {
    return currentTripsRepositoryInterface.cancelTrip(carpoolRouteId,
        cancellationType: cancellationType, date: date, reason: reason);
  }
}
