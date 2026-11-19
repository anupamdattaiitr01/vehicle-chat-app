class AppConstants {
  AppConstants._();

  static const String encryptionKey = String.fromEnvironment(
    'ENCRYPTION_KEY',
    defaultValue: 'fleet_payload_secret_2026',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5001',
  );

  // API Endpoints
  static const String bookingsEndpoint = '/api/bookings';

  // Secure Storage Keys
  static const String jwtTokenKey = 'jwt_token';
  static const String driverIdKey = 'driver_id';
  static const String driverNameKey = 'driver_name';

  // FCM & Local Notification Channels
  static const String notificationChannelId = 'fleet_chat_messages';
  static const String notificationChannelName = 'Fleet Chat Messages';
  static const String notificationChannelDescription =
      'Incoming messages from your manager and the fleet community';

  static const String bookingChannelId = 'booking_alerts_channel';
  static const String bookingChannelName = 'Ride Booking Alerts';
  static const String bookingChannelDescription =
      'Urgent full-screen alerts when a manager assigns a new ride';

  static int tabIndexFromRoomType(String? roomType) {
    final normalized = roomType?.toLowerCase().trim();
    if (normalized == 'personal' ||
        normalized == 'private' ||
        normalized == 'direct') {
      return 1;
    }
    return 0;
  }
}