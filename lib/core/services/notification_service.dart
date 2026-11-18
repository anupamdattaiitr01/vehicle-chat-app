import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';

typedef NotificationData = Map<String, dynamic>;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background FCM received: data=${message.data}');

  if (message.notification == null && message.data.isNotEmpty) {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
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
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  final StreamController<NotificationData> _notificationTapController =
  StreamController<NotificationData>.broadcast();

  static const AndroidNotificationChannel _fleetChannel =
  AndroidNotificationChannel(
    AppConstants.notificationChannelId,
    AppConstants.notificationChannelName,
    description: AppConstants.notificationChannelDescription,
    importance: Importance.max,
    playSound: true,
  );

  Stream<NotificationData> get onLocalNotificationTap =>
      _notificationTapController.stream;
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

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
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final decoded = json.decode(response.payload!);
            if (decoded is NotificationData) {
              _notificationTapController.add(decoded);
              return;
            }
          } catch (_) {}
          _notificationTapController.add({'roomType': response.payload!});
        }
      },
    );

    final androidPlugin =
    _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(_fleetChannel);
  }

  Future<RemoteMessage?> getInitialMessage() {
    return FirebaseMessaging.instance.getInitialMessage();
  }

  Future<String?> getToken() {
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