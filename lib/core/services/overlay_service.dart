import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

const String kPendingOverlayBookingKey = 'milo_pending_overlay_booking';
const String kPendingOverlayQueryIdKey = 'milo_pending_overlay_query_id';
const String kCachedBaseUrlKey = 'milo_cached_base_url';

class OverlayService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Persists DioClient's active baseUrl so the separate overlay isolate
  /// can send PATCH /respond requests even when the main app is killed.
  static Future<void> cacheBaseUrl(String baseUrl) async {
    if (baseUrl.trim().isEmpty) return;
    try {
      await _storage.write(key: kCachedBaseUrlKey, value: baseUrl.trim());
    } catch (_) {}
  }

  static Future<bool> isPermissionGranted() async {
    if (!Platform.isAndroid) return false;
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final granted = await FlutterOverlayWindow.requestPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isActive() async {
    if (!Platform.isAndroid) return false;
    try {
      return await FlutterOverlayWindow.isActive();
    } catch (_) {
      return false;
    }
  }

  /// Displays the floating SYSTEM_ALERT_WINDOW card over Google Maps / other apps
  /// and persists the payload in secure storage so the separate overlay isolate
  /// never misses data during cold engine spin-up.
  static Future<bool> showBookingOverlay(
      Map<String, dynamic> bookingData,
      ) async {
    if (!Platform.isAndroid) return false;

    final granted = await isPermissionGranted();
    if (!granted) return false;

    try {
      final baseUrl = (bookingData['baseUrl'] ?? '').toString();
      if (baseUrl.isNotEmpty) {
        await cacheBaseUrl(baseUrl);
      }

      await _storage.write(
        key: kPendingOverlayBookingKey,
        value: json.encode(bookingData),
      );

      final alreadyOpen = await FlutterOverlayWindow.isActive();
      if (!alreadyOpen) {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          height: 410,
          width: WindowSize.matchParent,
          alignment: OverlayAlignment.bottomCenter,
          flag: OverlayFlag.defaultFlag,
          visibility: NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.none,
          overlayTitle: 'Milo Drive • New Ride Offer',
          overlayContent:
          '${bookingData['passengerName'] ?? 'Passenger'} • ${bookingData['scheduledTime'] ?? ''}',
        );
      }

      await FlutterOverlayWindow.shareData(bookingData);
      return true;
    } catch (e) {
      debugPrint('Failed to show system overlay: $e');
      return false;
    }
  }

  static Future<void> closeOverlay() async {
    if (!Platform.isAndroid) return;
    try {
      await _storage.delete(key: kPendingOverlayBookingKey);
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (_) {}
  }

  static Future<String?> consumePendingQueryBookingId() async {
    try {
      final id = await _storage.read(key: kPendingOverlayQueryIdKey);
      if (id != null && id.isNotEmpty) {
        await _storage.delete(key: kPendingOverlayQueryIdKey);
        return id;
      }
    } catch (_) {}
    return null;
  }
}

/// Floating SYSTEM_ALERT_WINDOW UI rendered in the dedicated overlay FlutterEngine.
class BookingSystemOverlay extends StatefulWidget {
  const BookingSystemOverlay({super.key});

  @override
  State<BookingSystemOverlay> createState() => _BookingSystemOverlayState();
}

class _BookingSystemOverlayState extends State<BookingSystemOverlay> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  StreamSubscription<dynamic>? _overlaySub;

  Map<String, dynamic>? _booking;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadPersistedBooking();
    _overlaySub = FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map) {
        final map = Map<String, dynamic>.from(event);
        if (map['overlayAction'] == null && mounted) {
          setState(() {
            _booking = map;
            _errorText = null;
          });
        }
      }
    });
  }

  Future<void> _loadPersistedBooking() async {
    try {
      final raw = await _storage.read(key: kPendingOverlayBookingKey);
      if (raw != null && raw.isNotEmpty && mounted) {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          setState(() => _booking = decoded);
        }
      }
    } catch (_) {}
  }

  Future<String?> _resolveJwtToken() async {
    final allValues = await _storage.readAll();
    for (final value in allValues.values) {
      if (value.startsWith('eyJ') && value.split('.').length == 3) {
        return value;
      }
    }
    return null;
  }

  Future<void> _confirmRideFromOverlay() async {
    final booking = _booking;
    if (booking == null || _isSubmitting) return;

    final bookingId =
    (booking['_id'] ?? booking['bookingId'] ?? booking['id'] ?? '')
        .toString();
    if (bookingId.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final token = await _resolveJwtToken();
      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Open Milo Drive to confirm.');
      }

      final baseUrl = (booking['baseUrl'] ?? '').toString().isNotEmpty
          ? booking['baseUrl'].toString()
          : (await _storage.read(key: kCachedBaseUrlKey) ?? '');

      if (baseUrl.isEmpty) {
        throw Exception('Server URL missing. Open Milo Drive to confirm.');
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      await dio.patch(
        '${AppConstants.bookingsEndpoint}/$bookingId/respond',
        data: {'action': 'confirm'},
      );

      await FlutterOverlayWindow.shareData({
        'overlayAction': 'confirmed',
        'bookingId': bookingId,
      });

      await OverlayService.closeOverlay();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorText = 'Could not confirm right now. Tap Query to open app.';
        });
      }
    }
  }

  Future<void> _openAppInQueryMode() async {
    final booking = _booking;
    final bookingId =
    (booking?['_id'] ?? booking?['bookingId'] ?? booking?['id'] ?? '')
        .toString();

    if (bookingId.isNotEmpty) {
      await _storage.write(key: kPendingOverlayQueryIdKey, value: bookingId);
      await FlutterOverlayWindow.shareData({
        'overlayAction': 'open_query',
        'bookingId': bookingId,
      });
    }

    await OverlayService.closeOverlay();
  }

  @override
  void dispose() {
    _overlaySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final passengerName =
    (booking?['passengerName'] ?? 'New Passenger').toString();
    final passengerPhone = (booking?['passengerPhone'] ?? '').toString();
    final pickup =
    (booking?['pickupLocation'] ?? 'Pickup location').toString();
    final drop = (booking?['dropLocation'] ?? 'Drop location').toString();
    final scheduledTime =
    (booking?['scheduledTime'] ?? 'Upcoming Ride').toString();

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1518),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8E244D), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Milo Badge + Minimize (X)
              Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6E1D3D),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '⚡ NEW RIDE OFFER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => OverlayService.closeOverlay(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Schedule & Passenger
              Text(
                scheduledTime,
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                passengerPhone.isNotEmpty
                    ? '$passengerName • $passengerPhone'
                    : passengerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              // Pickup -> Drop Card
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border:
                  Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.radio_button_checked,
                            color: Color(0xFF2ECC71), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pickup,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Color(0xFFE74C3C), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            drop,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action Buttons: Raise Query (opens app) vs 1-Tap Confirm Ride
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _openAppInQueryMode,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Raise Query',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                      _isSubmitting ? null : _confirmRideFromOverlay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: const Color(0xFF0B1F13),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFF0B1F13),
                        ),
                      )
                          : const Text(
                        'Confirm Ride',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}