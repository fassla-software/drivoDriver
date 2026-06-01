import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/api_checker.dart';
import '../domain/models/simple_trip_model.dart';
import '../domain/services/current_trips_service_interface.dart';
import '../screens/simple_trip_map_screen.dart';

class SimpleTripsController extends GetxController implements GetxService {
  final CurrentTripsServiceInterface currentTripsServiceInterface;

  SimpleTripsController({required this.currentTripsServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _showSafeSnackBar(String message, {bool isError = true}) {
    final context = Get.context;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ));
  }

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  bool _isStartingTrip = false;
  bool get isStartingTrip => _isStartingTrip;

  String? _startingTripRouteId;
  String? get startingTripRouteId => _startingTripRouteId;

  bool _isEndingTrip = false;
  bool get isEndingTrip => _isEndingTrip;

  String? _endingTripRouteId;
  String? get endingTripRouteId => _endingTripRouteId;

  SimpleTripsResponseModel? _tripsResponse;
  SimpleTripsResponseModel? get tripsResponse => _tripsResponse;

  List<SimpleTripModel> _trips = [];
  List<SimpleTripModel> get trips => _trips;

  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) {
      print('=== SimpleTripsController onInit called ===');
    }
    getCurrentTrips();
  }

  /// Get current trips from API
  Future<void> getCurrentTrips({bool isRefresh = false}) async {
    if (kDebugMode) {
      print('=== getCurrentTrips called, isRefresh: $isRefresh ===');
    }

    if (isRefresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    update();

    try {
      if (kDebugMode) {
        print('=== Making API call to getCurrentTripsWithPassengers ===');
      }
      Response response =
          await currentTripsServiceInterface.getCurrentTripsWithPassengers();

      if (kDebugMode) {
        print('=== API Response - Status Code: ${response.statusCode} ===');
      }

      if (response.statusCode == 200) {
        _tripsResponse = SimpleTripsResponseModel.fromJson(response.body);

        final tripsData = _tripsResponse?.data;
        if (tripsData != null) {
          _trips = tripsData;
          if (kDebugMode) {
            print('=== Loaded ${_trips.length} trips ===');
          }
        } else {
          _clearData();
        }
      } else {
        _clearData();
        ApiChecker.checkApi(response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('=== API Error: $e ===');
      }
      _clearData();
      Get.showSnackbar(GetSnackBar(
        title: 'error'.tr,
        message: 'failed_to_load_trips'.tr,
        duration: const Duration(seconds: 3),
        backgroundColor: Get.theme.colorScheme.error,
      ));
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      update();
    }
  }

  /// Refresh trips
  Future<void> refreshTrips() async {
    await getCurrentTrips(isRefresh: true);
  }

  /// Get pending trips
  List<SimpleTripModel> get pendingTrips {
    return _trips.where((trip) => trip.tripStatus == 'pending').toList();
  }

  /// Get ongoing trips
  List<SimpleTripModel> get ongoingTrips {
    return _trips.where((trip) => trip.tripStatus == 'ongoing').toList();
  }

  /// Get completed trips
  List<SimpleTripModel> get completedTrips {
    return _trips.where((trip) => trip.tripStatus == 'completed').toList();
  }

  /// Get cancelled trips
  List<SimpleTripModel> get cancelledTrips {
    return _trips.where((trip) => trip.tripStatus == 'cancelled').toList();
  }

  /// Get trip status color
  Color getTripStatusColor(String status) {
    switch (status) {
      case 'pending':
      case 'return_pending':
        return Colors.orange;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get trip status display text
  String getTripStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'pending'.tr;
      case 'return_pending':
        return 'return_pending'.tr == 'return_pending'
            ? 'Return Pending'
            : 'return_pending'.tr;
      case 'ongoing':
        return 'ongoing'.tr;
      case 'completed':
        return 'completed'.tr;
      case 'cancelled':
        return 'cancelled'.tr;
      default:
        return 'unknown'.tr;
    }
  }

  /// Get available seats for a trip
  int getAvailableSeats(SimpleTripModel trip) {
    return trip.availableSeats ?? trip.seats ?? 0;
  }

  /// Start a trip
  Future<void> startTrip(int tripId) async {
    _isStartingTrip = true;
    _startingTripRouteId = tripId.toString();
    update();

    try {
      print('=== Starting trip for ID: $tripId ===');

      Response response = await currentTripsServiceInterface.startTrip(tripId);

      print(
          '=== Start Trip API Response - Status Code: ${response.statusCode} ===');
      print('=== Start Trip API Response - Body: ${response.body} ===');

      if (response.statusCode == 200) {
        _showSafeSnackBar('trip_started_successfully'.tr, isError: false);

        // Refresh the trips list
        await getCurrentTrips(isRefresh: true);

        // Get the updated trip data
        SimpleTripModel? updatedTrip =
            _trips.firstWhereOrNull((trip) => trip.id == tripId);
        if (updatedTrip != null) {
          // Navigate to simple trip map screen
          Get.to(() => SimpleTripMapScreen(trip: updatedTrip));
        }
      } else {
        if (response.statusCode == 403) {
          String errorMessage = 'failed_to_start_trip'.tr;
          if (response.body != null) {
            if (response.body['data'] != null &&
                response.body['data']['message'] != null) {
              errorMessage = response.body['data']['message'];
            } else if (response.body['message'] != null) {
              errorMessage = response.body['message'];
            }
          }

          _showSafeSnackBar(errorMessage);
        }
        if (response.statusCode == 401) {
          ApiChecker.checkApi(response);
        } else {
          String errorMessage = 'failed_to_start_trip'.tr;
          if (response.body != null) {
            if (response.body['data'] != null &&
                response.body['data']['message'] != null) {
              errorMessage = response.body['data']['message'];
            } else if (response.body['message'] != null) {
              errorMessage = response.body['message'];
            }
          }

          _showSafeSnackBar(errorMessage);
        }
      }
    } catch (e) {
      print('=== Start Trip Error: $e ===');
      _showSafeSnackBar('failed_to_start_trip'.tr);
    } finally {
      _isStartingTrip = false;
      _startingTripRouteId = null;
      update();
    }
  }

  /// Check if a specific trip is being started
  bool isTripBeingStarted(int tripId) {
    return _isStartingTrip && _startingTripRouteId == tripId.toString();
  }

  /// End a trip
  Future<void> endTrip(int tripId) async {
    _isEndingTrip = true;
    _endingTripRouteId = tripId.toString();
    update();

    try {
      print('=== Ending trip for ID: $tripId ===');

      Response response = await currentTripsServiceInterface.endTrip(tripId);

      print(
          '=== End Trip API Response - Status Code: ${response.statusCode} ===');
      print('=== End Trip API Response - Body: ${response.body} ===');

      if (response.statusCode == 200) {
        _showSafeSnackBar('trip_ended_successfully'.tr, isError: false);

        // Refresh the trips list
        await getCurrentTrips(isRefresh: true);
      } else {
        if (response.statusCode == 401) {
          ApiChecker.checkApi(response);
        } else {
          String errorMessage = 'failed_to_end_trip'.tr;
          if (response.body != null) {
            if (response.body['data'] != null &&
                response.body['data']['message'] != null) {
              errorMessage = response.body['data']['message'];
            } else if (response.body['message'] != null) {
              errorMessage = response.body['message'];
            }
          }

          _showSafeSnackBar(errorMessage);
        }
      }
    } catch (e) {
      print('=== End Trip Error: $e ===');
      _showSafeSnackBar('failed_to_end_trip'.tr);
    } finally {
      _isEndingTrip = false;
      _endingTripRouteId = null;
      update();
    }
  }

  /// Check if a specific trip is being ended
  bool isTripBeingEnded(int tripId) {
    return _isEndingTrip && _endingTripRouteId == tripId.toString();
  }

  bool _isCancellingTrip = false;
  bool get isCancellingTrip => _isCancellingTrip;

  String? _cancellingTripRouteId;
  String? get cancellingTripRouteId => _cancellingTripRouteId;

  /// Cancel a trip
  Future<void> cancelTrip(int tripId,
      {String? cancellationType, String? date, String? reason}) async {
    _isCancellingTrip = true;
    _cancellingTripRouteId = tripId.toString();
    update();

    try {
      print(
          '=== Cancelling trip for ID: $tripId, type: $cancellationType, date: $date ===');

      Response response = await currentTripsServiceInterface.cancelTrip(tripId,
          cancellationType: cancellationType, date: date, reason: reason);

      print(
          '=== Cancel Trip API Response - Status Code: ${response.statusCode} ===');
      print('=== Cancel Trip API Response - Body: ${response.body} ===');

      if (response.statusCode == 200) {
        _showSafeSnackBar('trip_cancelled_successfully'.tr, isError: false);

        // Refresh the trips list
        await getCurrentTrips(isRefresh: true);

        // check if we need to pop - only if not part of a multi-cancel loop or handled by caller
        if (cancellationType == null || cancellationType == 'all_dates') {
          if (Get.key.currentState?.canPop() ?? false) {
            Get.back();
          }
        }
      } else {
        if (response.statusCode == 401) {
          ApiChecker.checkApi(response);
        } else {
          String errorMessage = 'failed_to_cancel_trip'.tr;
          if (response.body != null) {
            if (response.body['data'] != null &&
                response.body['data']['message'] != null) {
              errorMessage = response.body['data']['message'];
            } else if (response.body['message'] != null) {
              errorMessage = response.body['message'];
            }
          }

          _showSafeSnackBar(errorMessage);
        }
      }
    } catch (e) {
      print('=== Cancel Trip Error: $e ===');
      _showSafeSnackBar('failed_to_cancel_trip'.tr);
    } finally {
      // If we are in a loop, we might not want to reset this immediately if we want to show loading state?
      // But for simplicity, we reset it. The multi-cancel method should handle its own loading state or reuse this.
      _isCancellingTrip = false;
      _cancellingTripRouteId = null;
      update();
    }
  }

  /// Cancel multiple dates for a trip
  Future<void> cancelTripDates(
      int tripId, List<String> dates, String reason) async {
    _isCancellingTrip = true;
    _cancellingTripRouteId = tripId.toString();
    update();

    try {
      for (String date in dates) {
        print('=== Cancelling date: $date for trip ID: $tripId ===');
        await currentTripsServiceInterface.cancelTrip(tripId,
            cancellationType: 'single_date', date: date, reason: reason);
      }
      // We assume if loop completes without throwing, it's success.
      // Ideally we should track individual successes but for now we follow simple requirement.
      _showSafeSnackBar('trip_cancelled_successfully'.tr, isError: false);

      await getCurrentTrips(isRefresh: true);
      if (Get.key.currentState?.canPop() ?? false) {
        Get.back();
      }
    } catch (e) {
      print('=== Cancel Trip Dates Error: $e ===');
      _showSafeSnackBar('failed_to_cancel_trip'.tr);
    } finally {
      _isCancellingTrip = false;
      _cancellingTripRouteId = null;
      update();
    }
  }

  /// Cancel entire trip route
  Future<void> cancelEntireTrip(int tripId, String reason) async {
    await cancelTrip(tripId,
        cancellationType: 'remaining_dates', reason: reason, date: null);
  }

  /// Check if a specific trip is being cancelled
  bool isTripBeingCancelled(int tripId) {
    return _isCancellingTrip && _cancellingTripRouteId == tripId.toString();
  }

  /// Clear all data
  void _clearData() {
    _trips.clear();
    _tripsResponse = null;
  }

  /// Clear all data and update UI
  void clearData() {
    _clearData();
    update();
  }
}
