import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

Future<BitmapDescriptor> getMarkerIcon(String url) async {
  final response = await http.get(Uri.parse(url));
  final bytes = response.bodyBytes;

  final codec = await ui.instantiateImageCodec(bytes, targetWidth: 120);
  final frame = await codec.getNextFrame();

  final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) {
    return BitmapDescriptor.defaultMarker;
  }

  return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
}