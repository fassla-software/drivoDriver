class RegisterRouteResponseModel {
  final bool success;
  final String message;
  final String? routeId;
  final Map<String, dynamic>? data;

  RegisterRouteResponseModel({
    required this.success,
    required this.message,
    this.routeId,
    this.data,
  });

  factory RegisterRouteResponseModel.fromJson(Map<String, dynamic> json) {
    String? parsedRouteId;
    if (json['route_id'] != null) {
      parsedRouteId = json['route_id'].toString();
    } else if (json['data'] != null && json['data']['route_id'] != null) {
      parsedRouteId = json['data']['route_id'].toString();
    }

    final bool isSuccess = json['success'] ??
        (json['response_code'] == 'default_store_200') ??
        false;

    return RegisterRouteResponseModel(
      success: isSuccess,
      message: json['message'] ?? '',
      routeId: parsedRouteId,
      data: json['data'],
    );
  }
}
