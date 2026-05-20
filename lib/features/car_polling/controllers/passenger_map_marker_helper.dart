import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../util/images.dart';
import '../domain/models/simple_passenger_model.dart';

/// Builds circular map markers from passenger profile photo or placeholder.
class PassengerMapMarkerHelper {
  /// ~same visual size as default Google Maps pin (car icons use ~50px).
  static const int _defaultSize = 44;

  static Future<BitmapDescriptor> fromPassenger(
    SimplePassengerModel passenger, {
    int size = _defaultSize,
  }) async {
    final bytes = await _buildCircularMarkerBytes(
      imageUrl: passenger.fullProfileImage,
      size: size,
    );
    return BitmapDescriptor.bytes(bytes, width: size.toDouble());
  }

  static Future<BitmapDescriptor> placeholder({int size = _defaultSize}) async {
    final bytes = await _buildCircularMarkerBytes(size: size);
    return BitmapDescriptor.bytes(bytes, width: size.toDouble());
  }

  static Future<Uint8List> _buildCircularMarkerBytes({
    String? imageUrl,
    int size = _defaultSize,
  }) async {
    ui.Image? image;
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      try {
        image = await _loadNetworkImage(imageUrl.trim(), size);
      } catch (_) {
        image = null;
      }
    }
    image ??= await _loadAssetImage(Images.personPlaceholder, size);
    return _drawCircularMarker(image, size);
  }

  static Future<ui.Image> _loadNetworkImage(String url, int size) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to load marker image');
    }
    final codec = await ui.instantiateImageCodec(
      response.bodyBytes,
      targetWidth: size,
      targetHeight: size,
    );
    return (await codec.getNextFrame()).image;
  }

  static Future<ui.Image> _loadAssetImage(String assetPath, int size) async {
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: size,
        targetHeight: size,
      );
      return (await codec.getNextFrame()).image;
    } catch (_) {
      final data = await rootBundle.load(Images.person);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: size,
        targetHeight: size,
      );
      return (await codec.getNextFrame()).image;
    }
  }

  static Future<Uint8List> _drawCircularMarker(ui.Image image, int size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final d = size.toDouble();
    const borderColor = Color(0xFF2F6BFF);
    const borderWidth = 2.0;
    final innerPadding = borderWidth + 1;

    canvas.drawCircle(
      Offset(d / 2, d / 2),
      d / 2 - 1,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset(d / 2, d / 2),
      d / 2 - borderWidth / 2,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    final innerRect = Rect.fromLTWH(
      innerPadding,
      innerPadding,
      d - innerPadding * 2,
      d - innerPadding * 2,
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(innerRect));
    paintImage(
      canvas: canvas,
      rect: innerRect,
      image: image,
      fit: BoxFit.cover,
    );
    canvas.restore();

    final picture = recorder.endRecording();
    final outImage = await picture.toImage(size, size);
    final byteData = await outImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
