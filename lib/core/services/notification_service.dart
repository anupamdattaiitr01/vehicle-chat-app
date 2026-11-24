import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

typedef NotificationData = Map<String, dynamic>;

const String kBookingAlertChannelId = 'booking_alerts_channel';
const String kBookingAlertChannelName = 'Ride Booking Alerts';
const String kBookingAlertChannelDesc =
    'Urgent full-screen alerts when a manager assigns a new ride';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background FCM received: data=${message.data}');

  if (message.data.isEmpty) return;

  // 1. Ride Assignment Alert: Trigger native WindowManager card in background/kill mode
  if (message.data['type'] == 'BOOKING_ASSIGNED') {
    if (Platform.isAndroid) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'pending_native_booking_json',
          json.encode(message.data),
        );
        // MiloApplication's OnSharedPreferenceChangeListener immediately
        // inflates MiloOverlayManager's floating card (or falls back to a
        // notification if SYSTEM_ALERT_WINDOW is disabled).
        return;
      } catch (e) {
        debugPrint('Native overlay bridge error: $e');
      }
    }

    // Non-Android or bridge error fallback notification
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kBookingAlertChannelId,
        kBookingAlertChannelName,
        description: kBookingAlertChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    final rawBookingId = (message.data['_id'] ??
        message.data['bookingId'] ??
        message.data['id'] ??
        '')
        .toString();
    final notificationId = rawBookingId.isNotEmpty
        ? NotificationService.bookingNotificationId(rawBookingId)
        : DateTime.now().millisecondsSinceEpoch.remainder(1000000000);

    final passengerName = message.data['passengerName'] ?? 'Passenger';
    final pickup = message.data['pickupLocation'] ?? 'Pickup location';
    final scheduledTime = message.data['scheduledTime'] ?? '';

    await plugin.show(
      id: notificationId,
      title: 'New Ride Assigned • $passengerName',
      body: '$scheduledTime • Pickup: $pickup',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          kBookingAlertChannelId,
          kBookingAlertChannelName,
          channelDescription: kBookingAlertChannelDesc,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          visibility: NotificationVisibility.public,
          ongoing: true,
          autoCancel: true,
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: json.encode(message.data),
    );
    return;
  }

  // 2. Standard Data-Only Chat Message Notification
  if (message.notification == null) {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        description: AppConstants.notificationChannelDescription,
        importance: Importance.max,
        playSound: true,
      ),
    );

    await plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1000000000),
      title: message.data['title'] ??
          message.data['senderName'] ??
          'New Fleet Message',
      body: message.data['body'] ??
          message.data['content'] ??
          'You have a new message',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: json.encode(message.data),
    );
  }
}

class NotificationService {
  static const MethodChannel _fullScreenChannel =
  MethodChannel('com.yourcompany.vehicle_chat_app/full_screen_intent');

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  final StreamController<NotificationData> _notificationTapController =
  StreamController<NotificationData>.broadcast();

  NotificationData? _initialLocalLaunchPayload;

  static const AndroidNotificationChannel _fleetChannel =
  AndroidNotificationChannel(
    AppConstants.notificationChannelId,
    AppConstants.notificationChannelName,
    description: AppConstants.notificationChannelDescription,
    importance: Importance.max,
    playSound: true,
  );

  static const AndroidNotificationChannel _bookingChannel =
  AndroidNotificationChannel(
    kBookingAlertChannelId,
    kBookingAlertChannelName,
    description: kBookingAlertChannelDesc,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static int bookingNotificationId(String bookingId) {
    return bookingId.hashCode & 0x7fffffff;
  }

  Stream<NotificationData> get onLocalNotificationTap =>
      _notificationTapController.stream;
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
  Stream<String> get onTokenRefresh =>
      // ignore: deprecated_member_use
  FirebaseMessaging.instance.onTokenRefresh;

  NotificationData? consumeInitialLocalNotification() {
    final payload = _initialLocalLaunchPayload;
    _initialLocalLaunchPayload = null;
    return payload;
  }

  Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final decoded = _decodePayload(response.payload);
        if (decoded != null) {
          _notificationTapController.add(decoded);
        }
      },
    );

    final launchDetails =
    await _localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _initialLocalLaunchPayload =
          _decodePayload(launchDetails?.notificationResponse?.payload);
    }

    final androidPlugin =
    _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(_fleetChannel);
    await androidPlugin?.createNotificationChannel(_bookingChannel);
  }

  Future<void> cancelBookingNotification(String bookingId) async {
    if (bookingId.isEmpty) return;
    try {
      await _localNotifications.cancel(id: bookingNotificationId(bookingId));
    } catch (_) {}
  }

  NotificationData? _decodePayload(String? rawPayload) {
    if (rawPayload == null || rawPayload.isEmpty) return null;
    try {
      final decoded = json.decode(rawPayload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return {'roomType': rawPayload};
  }

  Future<bool> canUseFullScreenIntent() async {
    if (!Platform.isAndroid) return true;
    try {
      final allowed = await _fullScreenChannel
          .invokeMethod<bool>('canUseFullScreenIntent');
      return allowed ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> openFullScreenIntentSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _fullScreenChannel.invokeMethod('openFullScreenIntentSettings');
    } catch (_) {}
  }

  Future<RemoteMessage?> getInitialMessage() {
    return FirebaseMessaging.instance.getInitialMessage();
  }

  Future<String?> getToken() {
    // ignore: deprecated_member_use
    return FirebaseMessaging.instance.getToken();
  }

  Future<void> showForegroundNotification({
    required String title,
    required String body,
    required NotificationData data,
  }) async {
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1000000000),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _fleetChannel.id,
          _fleetChannel.name,
          channelDescription: _fleetChannel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: json.encode(data),
    );
  }

  void dispose() {
    _notificationTapController.close();
  }
}