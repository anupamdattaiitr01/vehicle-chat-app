import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/booking/domain/entities/booking_entity.dart';

class OverlayService {
  static const MethodChannel _channel =
  MethodChannel('com.yourcompany.vehicle_chat_app/native_overlay');
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Syncs active baseUrl and JWT token into native SharedPreferences so
  /// MiloFirebaseMessagingService can accept bookings in background/kill mode.
  static Future<void> cacheBaseUrl(String baseUrl) async {
    if (!Platform.isAndroid) return;
    try {
      String? jwt;
      final allValues = await _storage.readAll();
      for (final value in allValues.values) {
        if (value.startsWith('eyJ') && value.split('.').length == 3) {
          jwt = value;
          break;
        }
      }
      await _channel.invokeMethod('syncCredentials', {
        'baseUrl': baseUrl.trim(),
        if (jwt != null) 'token': jwt,
      });
    } catch (_) {}
  }

  static Future<bool> isPermissionGranted() async {
    if (!Platform.isAndroid) return false;
    try {
      final allowed =
      await _channel.invokeMethod<bool>('isOverlayPermissionGranted');
      return allowed ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final opened =
      await _channel.invokeMethod<bool>('requestOverlayPermission');
      return opened ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> closeOverlay() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('dismissNativeOverlay');
    } catch (_) {}
  }

  static Future<String?> consumePendingQueryBookingId() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('consumePendingQueryId');
    } catch (_) {
      return null;
    }
  }
}

extension BookingOverlaySync on BookingEntity {
  Map<String, dynamic> toOverlayMap() => {
    '_id': id,
    'passengerName': passengerName,
    'passengerPhone': passengerPhone,
    'pickupLocation': pickupLocation,
    'dropLocation': dropLocation,
    'scheduledTime': scheduledTime,
  };
}